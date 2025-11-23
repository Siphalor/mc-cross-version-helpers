#! /bin/env sh

FMT_RED="\033[31m"
FMT_GREEN="\033[32m"
FMT_BLUE="\033[34m"
FMT_CLEAR="\033[0m"

if [ $# -eq 0 ] ; then
  echo "Error: must supply the command to run for every MC version"
  exit 1
fi

mcVersions=$(find ./gradle -maxdepth 1 -type d -name 'mc-*' | sed -n -e 's#.*mc-\([0-9.]\+\).*#\1#g' -e p | sort -V)
echo "Discovered MC versions:
$mcVersions"

for mcVersion in $mcVersions ; do
  printf '%bRunning "%s" for MC version %s%b\n\n' "$FMT_BLUE" "$*" "$mcVersion" "$FMT_CLEAR"
  sed gradle.properties -i -e "s#\(minecraft\.version\.descriptor = \).*#\1$mcVersion#"
  if "$@" ; then
    succeeded="$succeeded $mcVersion"
  else
    failed="$failed $mcVersion"
  fi
  echo
done

succeeded="${succeeded# }"
failed="${failed# }"

printf '%bResults:%b\n' "$FMT_BLUE" "$FMT_CLEAR"
if [ -n "$succeeded" ] ; then
  printf '%bSucceeded: %s%b\n' "$FMT_GREEN" "$succeeded" "$FMT_CLEAR"
fi
if [ -n "$failed" ] ; then
  printf '%bFailed: %s%b\n' "$FMT_RED" "$failed" "$FMT_CLEAR"
  exit 1
fi
