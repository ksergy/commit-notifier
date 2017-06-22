DIR="${BASH_SOURCE%/*}"
[[ ! -d "$DIR" ]] && DIR="$PWD"
. "$DIR/telegram-bot-key.inc"

# $1 --- commit: hash date branch author
# $2, ... --- notified persons
function notifier {
  local commit="$1"
  local -a notified=( ${@:2} )
  local url="https://api.telegram.org/$TELEGRAM_BOT_KEY/sendMessage"
  local json1='{"chat_id": '
  local json2=', "text": "'
  local json3='"}'
  local json=""
  local cmd_line=""

  commit=$(echo "$commit" | sed 's/"/_/g')

  for person in ${notified[@]}; do
    echo "Notify '$person' about '$commit'"
    json="$json1$person$json2$commit$json3"
    cmd_line="curl -X POST -H 'Content-Type: application/json' -d '$json' '$url'"

    echo "  About to: $cmd_line"

    eval "$cmd_line" || true
  done
}
