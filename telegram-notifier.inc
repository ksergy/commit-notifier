DIR="${BASH_SOURCE%/*}"
[[ ! -d "$DIR" ]] && DIR="$PWD"
. "$DIR/telegram-bot-key.inc"

# $1 --- repository alias
# $2 --- commit: hash date branch author
# $2, ... --- notified persons
function notifier {
  local repo_alias="$1"
  local commit="$2"
  local -a notified=( ${@:3} )
  local url="https://api.telegram.org/$TELEGRAM_BOT_KEY/sendMessage"
  local json1='{"chat_id": '
  local json2=', "text": "'
  local json3='"}'
  local json=""
  local cmd_line=""

  commit=$(echo "$commit" | sed 's/"/<double-quote>/g')
  commit=$(echo "$commit" | sed "s/'/<quote>/g")
  commit=$(echo "$commit" | sed 's/\\/<backslash>/g')

  for person in ${notified[@]}; do
    echo "Notify '$person' about '$commit' in '$repo_alias'"
    json="$json1"
    json+="$person"
    json+="$json2"
    json+="$repo_alias: "
    json+="$commit"
    json+="$json3"
    cmd_line="curl -s -X POST -H 'Content-Type: application/json' -d '$json' '$url'"

    eval "$cmd_line" > /dev/null || true
  done
}

