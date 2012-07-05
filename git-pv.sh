#!/bin/sh

USAGE="fetch"
. "$(git --exec-path)/git-sh-setup"

test -z "$1" && usage
ACTION="$1"; shift
PARAM1="$1"; shift

test -z "$GIVOTAL_REF" && GIVOTAL_REF="$(git config givotal.ref)"
test -z "$GIVOTAL_REF" && GIVOTAL_REF="refs/heads/pivotal/main"

function print_tasks {
        git grep "^__PP|" $GIVOTAL_REF:$1 | cut -d "|" -f2,3 | sort -h | cut -d "|" -f2
}

function modify_story {
        STORY_ID=$1
        TOKEN=$(git config givotal.token)
        PROJECT_ID=$(git config givotal.projectid)
        curl -s -o /dev/null -H "X-TrackerToken: $TOKEN" -X PUT -H "Content-Length: 0" \
              "http://www.pivotaltracker.com/services/v3/projects/$PROJECT_ID/stories/$STORY_ID$2" 1> /dev/null
        if [ "${?}" -ne "0" ]; then
                echo "Error: story modification failed"
                exit 1
        fi
}

function register_story {
        PREV_REF="$(git symbolic-ref HEAD 2>/dev/null)"
        PREV_REF=${PREV_REF##refs/heads/}
        git checkout $GIVOTAL_REF &>/dev/null
        if [ -d "branches" ]; then
                if [ -e "branches/$1" ]; then
                        echo "Story already started"
                        exit 1
                fi
                echo $2 > branches/$1
        else
                mkdir branches
                echo $2 > branches/$1
        fi
        git add branches
        git commit -m "Registered new pivotal branch" &>/dev/null
        git checkout $PREV_REF &>/dev/null
}

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
        purr.py --mywork
        git add mywork
        git commit -m "Fetchted pivotal data" &>/dev/null
        git checkout $PREV_REF &>/dev/null
        echo -e "\033[1;36mDone fetching pivotal data\033[0m"
        ;;
current | cur)
        print_tasks "current"
        ;;
backlog | bck)
        while read -r iteration
        do
                echo -e "\033[0;30m\033[47m * $iteration | =========================== \033[0m" 
                print_tasks "backlog/$iteration"
        done <<< "$(git ls-tree $GIVOTAL_REF:backlog --name-only | sort -h)"
        ;;
mywork | my)
        print_tasks "mywork"
        ;;
start | s)
        test -z "$PARAM1" && usage
        STORY_ID="$PARAM1"
        USERNAME=$(git config user.name)
        modify_story $STORY_ID "?story\[current_state\]=started&story\[owned_by\]=${USERNAME/ /%20}"
        echo -n "Branch suffix: "
        read BRANCH_SUFFIX
        BRANCH_NAME="$PARAM1-${BRANCH_SUFFIX/ /}"
        register_story $PARAM1 $BRANCH_NAME
        if $(git show-ref --quiet $BRANCH_NAME); then
                echo "Branch $BRANCH_NAME exists. Checking out..."
                git checkout $BRANCH_NAME
                exit
        fi
        git checkout -b $BRANCH_NAME
        ;;
show | sh)
        STORY_PATH=$(git grep $PARAM1 $GIVOTAL_REF | head -n 1)
        if [ -n "$STORY_PATH" ]; then
                git show $(echo $STORY_PATH | cut -d":" -f1,2) | grep -v "^__PP"
        fi
        ;;
finish | f)
        CURRENT_REF="$(git symbolic-ref HEAD 2>/dev/null)"
        CURRENT_REF=${CURRENT_REF##refs/heads/}
        PIVOTAL_BRANCH=$(git grep "$CURRENT_REF" $GIVOTAL_REF:branches)
        if [ -n $PIVOTAL_BRANCH ] && [ "$PIVOTAL_BRANCH" != "" ]; then
                STORY_ID=$(echo $PIVOTAL_BRANCH | cut -d":" -f3)
                modify_story $STORY_ID "?story\[current_state\]=finished"
        else
                echo "You are not on a pivotal story branch"
        fi
        ;;
deliver | dlv)
        CURRENT_REF="$(git symbolic-ref HEAD 2>/dev/null)"
        CURRENT_REF=${CURRENT_REF##refs/heads/}
        PIVOTAL_BRANCH=$(git grep "$CURRENT_REF" $GIVOTAL_REF:branches)
        if [ -n $PIVOTAL_BRANCH ] && [ "$PIVOTAL_BRANCH" != "" ]; then
                STORY_ID=$(echo $PIVOTAL_BRANCH | cut -d":" -f3)
                modify_story $STORY_ID "?story\[current_state\]=delivered"
        else
                echo "You are not on a pivotal story branch"
                exit
        fi
        INTEGRATION_BRANCH=$(git config givotal.integration-branch)
        echo "Do you want to rebase against \"$INTEGRATION_BRANCH\" branch? [y]"
        read YNO
        case $YNO in
                [nN] )
                        git push origin $CURRENT_REF
                        ;;
                *)
                        git rebase -i $INTEGRATION_BRANCH
                        git push origin $CURRENT_REF
                        ;;
        esac
        ;;
*)
	usage
esac
