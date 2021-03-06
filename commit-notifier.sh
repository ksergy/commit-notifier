#!/bin/bash

set -e
set -u

SELF=$(basename "$0")
DATE_FORMAT="+%F %T %z"
DATE=$(date -u "$DATE_FORMAT")
REQUIRED_ARGUMENTS_AMOUNT=1

KW_BRANCH="#BRANCH#"
KW_PREV_DATE="#PREV_DATE#"
KW_CUR_DATE="#CUR_DATE#"

declare CONFIG_PATH=""
declare REPO_ALIAS=""
declare PATH_TO_REPO=""
declare FETCH_CMD=""
declare CHECKOUT_CMD=""
declare GET_LOGS_CMD=""
declare GET_INITIAL_COMMIT_AUTHOR_CMD=""
declare -a BRANCHES=()

DIR="${BASH_SOURCE%/*}"
[[ ! -d "$DIR" ]] && DIR="$PWD"
. "$DIR/notifier.inc"

function die {
  echo -en "\x1b[31m$@\x1b[0m\n" >&2
  exit 1
}

function usage {
  echo "$SELF config-file-path"
}

function prepare {
  $FETCH_CMD
}

function create_get_logs_cmd {
 echo "$GET_LOGS_CMD" |
   sed "s/$KW_BRANCH/\"$1\"/" |
   sed "s/$KW_PREV_DATE/$2/" |
   sed "s/$KW_CUR_DATE/$3/"
}

function get_date_from_file {
  [[ -f "$1" ]] && {
    cat "$1"
  } || {
    date -u "$DATE_FORMAT" -d@0
  }
}

function notify_branch_but_author {
  local branch="$1"
  local -a notified=( ${@:2} )

  local prev_date_file=".commit-notifier.$branch.prev_date"
  local prev_date=$(get_date_from_file "$prev_date_file");

  local get_initial_commit_author_cmd=$(echo "$GET_INITIAL_COMMIT_AUTHOR_CMD" | sed "s/$KW_BRANCH/\"$branch\"/")
  local get_logs_cmd=$(create_get_logs_cmd "$branch" "$prev_date" "$DATE")

  local initial_commit_author=$( eval "$get_initial_commit_author_cmd" )
  local tmp_file=$(mktemp)

  echo "Initial commit author: $branch: $initial_commit_author"

  eval "$get_logs_cmd | egrep -v -- '$initial_commit_author'\$" > "$tmp_file" || true

  mapfile -t commits < "$tmp_file"

  echo "Commits count: ${#commits[@]}"

  for ((idx=0; idx < ${#commits[@]}; ++idx)); do
    cmd="notifier \"$REPO_ALIAS\" \"${commits[$idx]}\" ${notified[@]}"
    echo "Cmd: $cmd"
    eval "$cmd"
  done

  rm $tmp_file

  [[ ${#commits[@]} -eq 0 ]] || echo "$DATE" > $prev_date_file
}

function notify_branch_all {
  local branch="$1"
  local -a notified=( ${@:2} )

  local prev_date_file=".commit-notifier.$branch.prev_date"
  local prev_date=$(get_date_from_file "$prev_date_file");

  local get_logs_cmd=$(create_get_logs_cmd "$branch" "$prev_date" "$DATE")
  local tmp_file=$(mktemp)

  eval "$get_logs_cmd"  > "$tmp_file"

  mapfile -t commits < "$tmp_file"

  for ((idx=0; idx < ${#commits[@]}; ++idx)); do
    cmd="notifier \"$REPO_ALIAS\" \"${commits[$idx]}\" ${notified[@]}"
    echo "Cmd: $cmd"
    eval "$cmd"
  done

  rm $tmp_file

  [[ ${#commits[@]} -eq 0 ]] || echo "$DATE" > $prev_date_file
}

function process_branch {
  local branch="$1"
  local rule="$2"
  local -a notified=( ${@:3} )
  local checkout_cmd=$(echo "$CHECKOUT_CMD" | sed -s "s/$KW_BRANCH/$branch/")

  echo "Checking out with: $checkout_cmd"

  eval "$checkout_cmd"

  case "$rule" in
    '-')
    # send notification for any pushed commit but author's
    notify_branch_but_author "$branch" ${notified[@]}
    ;;

    '+')
    # send notification for each and every pushed commit
    notify_branch_all "$branch" ${notified[@]}
    ;;
  esac
}

######## M A I N

[[ $# -ge 1 ]] || {
  usage
  exit 0
}

CONFIG_PATH="$1"

source "$CONFIG_PATH"

pushd "$PATH_TO_REPO"

prepare

for line in ${BRANCHES[@]}; do
  echo "Line: $line"

  array=(${line//;/ })

  echo "  Array: ${array[@]}"

  [[ ${#array[@]} -ge 3 ]] || continue

  branch_name=${array[0]}
  rule=${array[1]}

  notified=( ${array[@]:2} )

  echo "  Branch: '$branch_name', rule: '$rule', notified: '${notified[@]}'"
  process_branch "$branch_name" "$rule" ${notified[@]}
done

popd

echo -en '\x1b[32mDone\x1b[0m\n'

