#!/bin/bash
set -o errexit -o nounset -o pipefail
function -h {
cat <<USAGE
 USAGE: remoting.bash ...
        remoting.bash remote <user>@<host> (--sudo)? -- <command> <arguments>*

  A template for Bash remoting. With the \`remote\` command, you can try
  running commands or functions defined in the script on a remote machine.

USAGE
}; function --help { -h ;}                 # A nice way to handle -h and --help

function main {
  : abstract
}

function globals {
  export LC_ALL=en_US.UTF-8
  export LANG="$LC_ALL"
}; globals

function fingerprint {
  printf 'on %s (running %s) at %s\n' \
         "$(hostname -f)" "$(uname -s)" "$(date -u +'%F %T UTC')"
}
########## Body functions go here. Call one of them in main.

##################################################################### Utilities

# Usage: remote <ssh connection parameters> -- <command> <arg>*
function remote {
  local ssh=( -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no )
  local shell=( bash )
  while [[ ${1:+isset} ]]
  do
    case "$1" in
      --sudo) shell=( sudo bash ) ; shift ;;
      --)     shift ; break ;;
      *)      ssh=( "${ssh[@]}" "$1" ) ; shift ;;
    esac
  done
  serialized "$@" | ssh "${ssh[@]}" "${shell[@]}"
}

# Usage: serialized <command> <arg>* | <a bash shell>
function serialized {
  declare -f                                        # Send function definitions
  echo 'set -o errexit -o nounset -o pipefail'          # Enable error handling
  echo '! declare -f globals || globals'           # Setup globals if available
  printf ' %q' "$@"                             # Print each argument, *quoted*
  echo                                      # Send a newline to run the command
}

function msg { out "$*" >&2 ;}
function err { local x=$? ; msg "$*" ; return $(( $x == 0 ? 1 : $x )) ;}
function out { printf '%s\n' "$*" ;}

# Handles "no-match" exit code specified by POSIX for filtering tools.
function maybe { "$@" || return $(( $? == 1 ? 0 : $? )) ;}

if declare -f -- "${1:-}" >/dev/null
then "$@"
else main "$@"
fi

