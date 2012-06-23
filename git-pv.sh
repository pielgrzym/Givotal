#!/bin/sh

USAGE="fetch"
. "$(git --exec-path)/git-sh-setup"

test -z "$1" && usage
ACTION="$1"; shift

test -z "$GIVOTAL_REF" && GIVOTAL_REF="$(git config givotal.ref)"
test -z "$GIVOTAL_REF" && GIVOTAL_REF="refs/heads/pivotal-db"

case "$ACTION" in
fetch)
        PREV_REF="$(git symbolic-ref HEAD 2>/dev/null)"
        PREV_REF=${PREV_REF##refs/heads/}
        if [ -z $(git show-ref --verify --quiet $GIVOTAL_REF) ]; then
                say "Creating Givotal orphaned branch..."
                git checkout --orphan $GIVOTAL_REF
                git rm -rf .
        else
                git checkout $GIVOTAL_REF
        fi
        purr.py --current
        git add current
        purr.py --backlog
        git add backlog
        git commit -m "Msg"
        git checkout $PREV_REF
;;
*)
	usage
esac
