#!/bin/sh

USAGE="fetch"
. "$(git --exec-path)/git-sh-setup"

test -z "$1" && usage
ACTION="$1"; shift

test -z "$GIVOTAL_REF" && GIVOTAL_REF="$(git config givotal.ref)"
test -z "$GIVOTAL_REF" && GIVOTAL_REF="refs/heads/pivotal/master"

case "$ACTION" in
fetch)
        PREV_REF="$(git symbolic-ref HEAD 2>/dev/null)"
        PREV_REF=${PREV_REF##refs/heads/}
        if $(git show-ref --quiet $GIVOTAL_REF); then
                git checkout $GIVOTAL_REF &>/dev/null
        else
                say "Creating Givotal orphaned branch..."
                git checkout --orphan $GIVOTAL_REF &>/dev/null
                git rm -rf . &>/dev/null
        fi
        purr.py --current
        git add current
        purr.py --backlog
        git add backlog
        git commit -m "Fetchted pivotal data" &>/dev/null
        git checkout $PREV_REF &>/dev/null
;;
current)
        git grep "^__PP|" $GIVOTAL_REF:current | cut -d "|" -f2,3 | sort -h | cut -d "|" -f2
;;
backlog)
        while read -r iteration
        do
                echo -e "\033[0;30m\033[47m * $iteration | =========================== \033[0m" 
                git grep "^__PP|" $GIVOTAL_REF:backlog/$iteration | cut -d "|" -f2,3 | sort -h | cut -d "|" -f2
        done <<< "$(git ls-tree $GIVOTAL_REF:backlog --name-only | sort -r)"
;;
*)
	usage
esac
