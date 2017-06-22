# $1 --- commit: hash date branch author
# $2, 3, ... --- notified ones
function notifier {
  local commit="$1"
  local -a notified=( ${@:2} )

  echo "Notify about $commit : ${notified[@]}"
}

