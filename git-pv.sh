#!/usr/bin/env bash

usage="fetch"
. "$(git --exec-path)/git-sh-setup"

export GIVOTAL_DIR=$(dirname "$(echo "$0" | sed -e 's,\\,/,g')")

. $GIVOTAL_DIR/givotal-common

test -z "$1" && usage
action="$1"; shift
param1="$1"; shift

case "$action" in
fetch | fetchall)
        prev_ref="$(git symbolic-ref HEAD 2>/dev/null)"
        prev_ref=${prev_ref##refs/heads/}
        if git show-ref --quiet "$givotal_ref"; then
                git checkout "$givotal_ref" &>/dev/null
        else
                say "Creating Givotal orphaned branch..."
                git checkout --orphan "$givotal_ref" &>/dev/null
                git rm -rf . &>/dev/null
        fi
        if [ "$action" = 'fetch' ]; then
                purr.py --current
                git add current
                purr.py --mywork
                git add mywork
        else
                purr.py --current
                git add current
                purr.py --mywork
                git add mywork
                purr.py --backlog
                git add backlog
        fi
        git commit -m "Fetchted pivotal data" &>/dev/null
        git checkout "$prev_ref" &>/dev/null
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
        done <<< "$(git ls-tree "$givotal_ref":backlog --name-only | sort -h)"
        ;;
mywork | my)
        print_tasks "mywork"
        ;;
start | s)
        test -z "$param1" && usage
        story_id="$param1"
        if ! story=$(get_story_path "$story_id"); then
                echo "Ambigous or invalid story id"
                exit 1
        fi
        username=$(git config user.name)
        modify_story "$story_id" "?story\[current_state\]=started&story\[owned_by\]=${username// /%20}"
        echo -n "Branch suffix: "
        read branch_suffix
        branch_name="$param1-${branch_suffix// /-}"
        if git show-ref --quiet "$branch_name"; then
                echo "Branch $branch_name exists. Checking out..."
                git checkout "$branch_name"
                exit
        fi
        git checkout -b "$branch_name"
        ;;
show | sh)
        require_story_id
        story_path=$(get_story_path "$story_id")
        echo $story_path
        git show "$story_path" | grep -v "^__"
        ;;
finish | f)
        require_story_id
        modify_story "$story_id" "?story\[current_state\]=finished"
        echo -e "Story $story_id: \033[0;34mfinished\033[0m"
        ;;
deliver | dlv)
        require_story_id
        modify_story "$story_id" "?story\[current_state\]=delivered"
        current_ref="$(git symbolic-ref HEAD 2>/dev/null)"
        current_ref=${current_ref##refs/heads/}
        if ! integration_remote=$(git config givotal.integration-remote); then
                echo "You haven't defined integration remote yet."
                echo "Integration remote is the remote repository"
                echo "to which you push branches for review"
                echo -n "Enter integration repository name: "
                read integration_remote
                git config givotal.integration-remote "$integration_remote"
        fi
        echo -e "Story $story_id: \033[1;33mdelivered\033[0m"
        echo "Do you want to rebase against \"$integration_branch\" branch?"
        echo -en "(if the task is \033[1;31m redelivered\033[0m answer 'no') [y] "
        read yno
        case $yno in
                [nN] )
                        git push "$integration_remote" "$current_ref"
                        ;;
                *)
                        git rebase -i "$integration_branch"
                        git push "$integration_remote" "$current_ref"
                        ;;
        esac
        ;;
review | rv)
        test -z "$param1" && usage
        if ! story_path=$(get_story_path "$param1"); then
                echo "Ambigous  or invalid story id"
                exit 1
        fi
        initials=$(git show "$story_path" | grep "^__OWNER_INITIALS" | cut -d":" -f2)
        remote=$(git config givotal.remote-$initials)
        if [ -z "$remote" ]; then
                echo "No remote repository defined for initials $initials"
                echo -n "Provide remote name (Ctrl-c to abort): "
                read remote
                git config givotal.remote-$initials "$remote"
                echo "Remote $remote added to local givotal config"
        fi
        git fetch "$remote"
        branches=($(git branch -r | grep "$remote/$param1-"))
        if [ ${#branches[@]} -gt 1 ]; then
                echo ${branches}
                echo "More than one remote branch matches story id"
                echo "Please choose desired branch:"
                idx=0
                for b in ${branches[@]}; do
                        let "idx++"
                        echo -n "$idx. "
                        echo $b
                done
                echo -n "Choose branch: "
                read b
                if [ $((b-1)) -ge ${#branches[@]} ] || [ $((b-1)) -lt 0 ]; then
                        echo "Wrong choice: $b"
                        exit
                fi
                branch=${branches[(($b-1))]}
        else
                branch=${branches[0]}
        fi
        branch="${branch##*[[:blank:]]}"
        lbranch=${branch##$remote/} # remote/1234-my -> 1234-my
        if git show-ref --quiet "refs/heads/$lbranch"; then
                echo "Local branch $lbranch exists"
                echo "Merge remote (default) or replace? [m/r] "
                read mr
                case "$mr" in
                        [rR] )
                                # replace branch in case there was a forced update
                                git checkout "$(git config givotal.integration-branch)"
                                git branch -D "$lbranch"
                                git checkout -t "$branch"
                                ;;
                        *)
                                # just add fixes after redelivery
                                git checkout "$lbranch"
                                git merge "$branch"
                                ;;
                esac
        else
                # create new tracking branch to see the work
                git checkout -t "$branch"
        fi
        ;;
accept | ac)
        require_story_id
        modify_story "$story_id" "?story\[current_state\]=accepted"
        # in case we want to accept a story not checking out it's branch
        if [[ -n "$param1" ]]; then
                exit 0
        fi
        echo -en "\033[1;34mMerge story into '$integration_branch'? [y/n]\033[0m "
        read yno
        case "$yno" in
                [nN] )
                        exit
                        ;;
                *)
                        prev_ref="$(git symbolic-ref HEAD 2>/dev/null)"
                        prev_ref=${prev_ref##refs/heads/}
                        git checkout "$integration_branch"
                        git merge --no-ff "$prev_ref"
                        ;;
        esac
        ;;
reject | rj)
        require_story_id
        modify_story "$story_id" "?story\[current_state\]=rejected"
        git pv comment $story_id
        echo -e "Story $story_id: \033[1;31mrejected\033[0m"
        ;;
comment | com)
        require_story_id
        editor=$(git config core.editor)
        tmp_filename=/tmp/"$story_id"-reject-$(date -I)
        if [ -f "$tmp_filename" ]; then
                rm -rf "$tmp_filename"
        fi
        $editor "$tmp_filename"
        msg=$(<$tmp_filename)
        token=$(git config givotal.token)
        project_id=$(git config givotal.projectid)
        curl -s -o /dev/null -H "X-TrackerToken: $token" -X POST -H "Content-type: application/xml" \
                -d "<note><text>$msg</text></note>" \
                "https://www.pivotaltracker.com/services/v3/projects/$project_id/stories/$story_id/notes" 1>/dev/null
        rm -rf "$tmp_filename"
        ;;
*)
	usage
        ;;
esac
