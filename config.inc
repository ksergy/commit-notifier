PATH_TO_REPO="$HOME/project"
FETCH_CMD="hg pull"
CHECKOUT_CMD="hg update #BRANCH#"
GET_LOGS_CMD="hg log -r 'branch(#BRANCH#)' --template \"{node} {date|isodate} {branch} {author}\n\" --date \"#PREV_DATE# to #CUR_DATE#\""
GET_INITIAL_COMMIT_AUTHOR_CMD="hg log -r \"min(branch(#BRANCH#))\" --template \"{author}\n\""
BRANCHES=(
  "experimental;*;qa@company.com;features@company.com",
  "experimental2;-;dev1@company.com;features@company.com"
)

