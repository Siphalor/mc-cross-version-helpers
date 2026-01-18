#! /bin/env sh

FMT_RED="\033[31m"
FMT_GREEN="\033[32m"
FMT_BLUE="\033[34m"
FMT_CLEAR="\033[0m"

printHelp() {
  cat <<EOT > /dev/stderr
Usage: $0 [options] [--] <command> [<args>]
Options:
  --fail-fast, -f: Abort with non-zero exit code on the first error
  --versions <versions>: Comma-separated list of Minecraft versions this command should run for.
      By default, the command will be executed for each available Minecraft version.
EOT
}

if [ $# -eq 0 ] ; then
  printHelp
  exit 100
fi

for arg in "$@" ; do
  if [ "$mode" = cmd ] ; then
    command="$command $arg"
    continue
  fi
  case "$lastArg" in
    "--versions")
      mcVersions="$mcVersions $(echo "$arg" | sed 's/,/ /g')"
      lastArg=
      continue
      ;;
  esac
  case "$arg" in
    "--versions")
      lastArg="$arg"
      continue
      ;;
    "--fail-fast")
      failFast=1
      continue
      ;;
    "-f")
      failFast=1
      continue
      ;;
    "--")
      mode=cmd
      continue
      ;;
    "--"*)
      echo "Unrecognized argument: $arg" > /dev/stderr
      echo > /dev/stderr
      printHelp
      exit 100
      ;;
  esac

  mode=cmd
  command="$arg"
done

if [ -z "$mcVersions" ] ; then
  mcVersions=$(find ./gradle -maxdepth 1 -type d -name 'mc-*' | sed -n -e 's#.*mc-\([0-9.]\+\).*#\1#g' -e p | sort -V)
fi

echo "Discovered MC versions:
$mcVersions"

for mcVersion in $mcVersions ; do
  printf '%bRunning "%s" for MC version %s%b\n\n' "$FMT_BLUE" "$command" "$mcVersion" "$FMT_CLEAR"
  sed gradle.properties -i -e "s#\(minecraft\.version\.descriptor = \).*#\1$mcVersion#"
  if $command ; then
    succeeded="$succeeded $mcVersion"
  else
    if [ -n "$failFast" ] ; then
      printf '%bFailed: %s%b\n' "$FMT_RED" "$mcVersion" "$FMT_CLEAR"
      exit 1
    fi
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
