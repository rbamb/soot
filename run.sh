#! /usr/bin/env bash

JDK_HOME="/opt/java-se-8u42-ri"
JAVAC="$JDK_HOME/bin/javac"
JAVA="$JDK_HOME/bin/java"

SOOT_JAR="target/sootclasses-trunk-jar-with-dependencies.jar"
SOOT_MAIN_CLASS="soot.Main"
SOOT_CFG_CLASS="soot.tools.CFGViewer"
SOOT_OUTPUT_DIR="sootOutput"
SOOT_LOG="log"

SOOT_CLASSPATH=".:$JDK_HOME/jre/lib/rt.jar:$JDK_HOME/jre/lib/jce.jar"

C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RESET="\033[0m"

exec_dot() {
  local dir="$1"
  for file in "$dir"/*; do
    if [[ $file == *.dot ]]; then
      out=${file%.dot}.png
      dot -Tpng "$file" -o "$out"
    fi
  done
}

exec_from_jar() {
  [ ! -f "$SOOT_JAR" ] && mvn clean package assembly:single -DskipTests
  local mainClass="$1"
  local args="--soot-class-path $SOOT_CLASSPATH "
  args+="$2"
  "$JAVA" -cp "$SOOT_JAR" "$mainClass" $args
}

exec_from_src() {
  local mainClass="$1"
  local args="-cp . -pp $2"
  mvn clean compile exec:java \
    -Dexec.mainClass="$mainClass" \
    -Dexec.args="$args"
  # -Dorg.slf4j.simpleLogger.defaultLogLevel=debug
}

exec_graph() {
  local graph="$1"
  local targetClass="$2"
  local args="--graph=$graph "
  args+="--ir=grimp "
  args+="-app -W "
  args+="-verbose "
  args+="$targetClass "
  exec_from_src "$SOOT_CFG_CLASS" "$args"
  # exec_from_jar "$SOOT_CFG_CLASS" "$args"
}

exec_IR() {
  local format="$1"
  local targetClass="$2"
  local args="-f $format "
  args+="-verbose "
  args+="$targetClass "
  exec_from_src "$SOOT_MAIN_CLASS" "$args"
}

resolve_log() {
  local logfile="$1"
  local tmplog="log.tmp"
  declare -A arr
  for (( i=1; i<6; i++ )); do
    declare -a current_array
    arr[$i]=${current_array[@]}
  done
  while IFS= read -r line; do
    if [[ ! $line == [Thread* ]]; then
      continue
    fi
    idx="${line:8:1}"
    arr[$idx]+="$line\n"
  done < "$logfile"
  for i in "${!arr[@]}"; do
    cur="${arr[$i]}"
    for val in "${cur[@]}"; do
      echo -e "$val" >> "$tmplog"
    done
  done
  rm -f "$logfile" && mv "$tmplog" "$logfile"
}

# exec_IR "J" "Test" 2>"$SOOT_LOG"
# resolve_log "$SOOT_LOG"

exec_graph "BriefUnitGraph" "Main:getInt"
# exec_dot "$SOOT_OUTPUT_DIR"
# exec_from_jar "$SOOT_CFG_CLASS" "--help"
