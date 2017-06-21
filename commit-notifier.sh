#!/bin/bash

set -e
set -u

SELF=$(basename "$0")
DATE=$(date -u +'%F %T')
REQUIRED_ARGUMENTS_AMOUNT=1
CONFIG_FD=3

KW_BRANCH="#BRANCH#"
KW_PREV_DATE="#PREV_DATE#"
KW_CUR_DATE="#CUR_DATE#"

declare CONFIG_PATH=""
declare PATH_TO_REPO=""
declare FETCH_CMD=""
declare CHECKOUT_CMD=""
declare GET_LOGS_CMD=""
declare GET_INITIAL_COMMIT_AUTHOR_CMD=""
declare -A BRANCHES=()

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

function notify_branch_but_author {
  local branch="$1"
  local -a notified=( ${@:2} )

  local prev_date_file=".commit-notifier.$branch.prev_date"
  local prev_date="";
  [[ -f "$prev_date_file" ]] && {
    prev_date=$(cat "$prev_date_file")
  } || {
    prev_date=$(date +'%F %T' -d@0)
  }

  local get_initial_commit_author_cmd=$(echo "$GET_INITIAL_COMMIT_AUTHOR_CMD" | sed "s/$KW_BRANCH/$branch/")
  local get_logs_cmd=$(echo "$GET_LOGS_CMD" |
                         sed "s/$KW_BRANCH/$branch/" |
                         sed "s/$KW_PREV_DATE/$prev_date/" |
                         sed "s/$KW_CUR_DATE/$DATE/")

  local initial_commit_author=$( eval "$get_initial_commit_author_cmd" )
  local tmp_file=$(mktemp)

  echo "Initial commit author: $branch: $initial_commit_author"

  eval "$get_logs_cmd | egrep -v -- '$initial_commit_author'\$" > "$tmp_file"

  mapfile -t commits < "$tmp_file"

  echo "Commits count: ${#commits[@]}"

  for ((idx=0; idx < ${#commits[@]}; ++idx)); do
    echo "Notify about ${commits[$idx]} : ${notified[@]}"
  done

  rm $tmp_file

  echo "$DATE" > $prev_date_file
}

function notify_branch_all {
  local branch="$1"
  local -a notified=( ${@:2} )

  local prev_date_file=".commit-notifier.$branch.prev_date"
  local prev_date="";
  [[ -f "$prev_date_file" ]] && {
    prev_date=$(cat "$prev_date_file")
  } || {
    prev_date=$(date +'%F %T' -d@0)
  }

  local get_logs_cmd=$(echo "$GET_LOGS_CMD" |
                         sed "s/$KW_BRANCH/$branch/" |
                         sed "s/$KW_PREV_DATE/$prev_date" |
                         sed "s/$KW_CUR_DATE/$DATE/")

  local tmp_file=$(mktemp)

  eval "$get_logs_cmd"  > "$tmp_file"

  mapfile -t commits <<< "$tmp_file"

  for ((idx=0; idx < ${#commits[@]}; ++idx)); do
    echo "Notify about ${commits[$idx]} : ${notified[@]}"
  done

  rm $tmp_file

  echo "$DATE" > $prev_date_file
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

    '*')
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

eval "exec $CONFIG_FD<'$CONFIG_PATH'"

read -u $CONFIG_FD PATH_TO_REPO
read -u $CONFIG_FD FETCH_CMD
read -u $CONFIG_FD CHECKOUT_CMD
read -u $CONFIG_FD GET_LOGS_CMD
read -u $CONFIG_FD GET_INITIAL_COMMIT_AUTHOR_CMD

pushd "$PATH_TO_REPO"

#set -x
while read -u $CONFIG_FD line; do
  echo "Line read: $line"
  array=(${line//;/ })

  [[ ${#array[@]} -ge 3 ]] || continue

  echo "Array: ${array[@]}"

  branch_name=${array[0]}
  rule=${array[1]}

  notified=(${array[@]:2})

  echo "Notified: ${notified[@]}"

  process_branch "$branch_name" "$rule" ${notified[@]}
done
#set +x

popd

eval "exec $CONFIG_FD<&-"

echo -en '\x1b[32mDone\x1b[0m\n'

