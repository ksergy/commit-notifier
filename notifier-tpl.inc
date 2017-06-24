# $1 --- repository alias
# $2 --- commit: hash date branch author
# $3, 4, ... --- notified ones
function notifier {
  local repo_alias="$1"
  local commit="$2"
  local -a notified=( ${@:3} )

  echo "Notify about $commit in $repo_alias : ${notified[@]}"
}

