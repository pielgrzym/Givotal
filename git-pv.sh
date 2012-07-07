#!/bin/sh

usage="fetch"
. "$(git --exec-path)/git-sh-setup"

test -z "$1" && usage
action="$1"; shift
param1="$1"; shift

integration_branch=$(git config givotal.integration-branch)

test -z "$givotal_ref" && givotal_ref="$(git config givotal.ref)"
test -z "$givotal_ref" && givotal_ref="refs/heads/pivotal/main"

function print_tasks {
        git grep "^__PP|" "$givotal_ref":"$1" | cut -d "|" -f2,3 | sort -h | cut -d "|" -f2
}

function modify_story {
        story_id=$1
        token=$(git config givotal.token)
        project_id=$(git config givotal.projectid)
        curl -s -o /dev/null -H "X-TrackerToken: $token" -X PUT -H "Content-Length: 0" \
              "https://www.pivotaltracker.com/services/v3/projects/$project_id/stories/$story_id$2" 1> /dev/null
        if [ "${?}" -ne "0" ]; then
                echo "Error: story modification failed"
                exit 1
        fi
}

function register_story {
        prev_ref="$(git symbolic-ref HEAD 2>/dev/null)"
        prev_ref=${prev_ref##refs/heads/}
        git checkout "$givotal_ref" &>/dev/null
        if [ -d "branches" ]; then
                if [ -e "branches/$1" ]; then
                        echo "Story already started"
                        git checkout "$prev_ref" &>/dev/null
                        exit 1
                fi
                echo "$2" > branches/$1
        else
                mkdir branches
                echo "$2" > branches/$1
        fi
        git add branches
        git commit -m "Registered new pivotal branch" &>/dev/null
        git checkout "$prev_ref" &>/dev/null
}

function get_story_path {
        story_id=$1
        matches=($(git grep -l "$story_id" "$givotal_ref" current backlog | sort ))
        if [ ${#matches[@]} -gt 1 ] || [ ${#matches[@]} = 0 ]; then
                echo -1
                return
        fi
        # echo $(git grep -l "$story_id" "$givotal_ref" current backlog | sort )
        # for m in ${matches[@]}; do
        #         echo "Candidate: $m"
        # done
        if [ -n ${matches[0]} ]; then
                echo "${matches[0]}"
                return
        else
                echo 0
                return
        fi
}

function get_storyid_from_branch {
        ref="$(git symbolic-ref HEAD 2>/dev/null)"
        branch=${ref##refs/heads/}
        story_id=${branch%%-*}
        if [[ $story_id =~ [0-9] ]]; then
                story=$(get_story_path "$story_id")
        else
                echo -2
                return
        fi
        if [ -z $story ] || [ $story = -1 ]; then
                echo -1
                return
        else
                echo $story_id
        fi
}

case "$action" in
fetch | fetchall)
        prev_ref="$(git symbolic-ref HEAD 2>/dev/null)"
        prev_ref=${prev_ref##refs/heads/}
        if $(git show-ref --quiet "$givotal_ref"); then
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
        username=$(git config user.name)
        modify_story "$story_id" "?story\[current_state\]=started&story\[owned_by\]=${username// /%20}"
        echo -n "Branch suffix: "
        read branch_suffix
        branch_name="$param1-${branch_suffix// /-}"
        register_story "$param1" "$branch_name"
        if $(git show-ref --quiet "$branch_name"); then
                echo "Branch $branch_name exists. Checking out..."
                git checkout "$branch_name"
                exit
        fi
        git checkout -b "$branch_name"
        ;;
show | sh)
        # get_story_path "$param1"
        # exit
        story_path=$(get_story_path "$param1")
        if [ "$story_path" = -1 ]; then
                echo "Ambigous  or invalid story id"
                exit 1
        elif [ -n "$story_path" ]; then
                echo $story_path
                git show "$story_path" | grep -v "^__"
        fi
        ;;
finish | f)
        story_id=$(get_storyid_from_branch)
        if [ "$story_id" = -1 ]; then
                echo "Ambigous or invalid story id in branch name"
        elif [ "$story_id" = -2 ]; then
                echo "You are not on a pivotal story branch"
        elif [ -n "$story_id" ]; then
                modify_story "$story_id" "?story\[current_state\]=finished"
                echo -e "Story $story_id: \033[0;34mfinished\033[0m"
        else
                echo "Unknown error"
        fi
        ;;
deliver | dlv)
        story_id=$(get_storyid_from_branch)
        if [ "$story_id" = -1 ]; then
                echo "Ambigous or invalid story id in branch name"
        elif [ "$story_id" = -2 ]; then
                echo "You are not on a pivotal story branch"
        elif [ -n "$story_id" ]; then
                story_id=$(echo "$pivotal_branch" | cut -d":" -f3)
                modify_story "$story_id" "?story\[current_state\]=delivered"
                echo -e "Story $story_id: \033[1;33mdelivered\033[0m"
        else
                echo "Unknown error"
                exit
        fi
        echo "Do you want to rebase against \"$integration_branch\" branch?"
        echo -en "(if the task is \033[1;31m redelivered\033[0m answer 'no') [y] "
        read yno
        case $yno in
                [nN] )
                        git push origin "$current_ref"
                        ;;
                *)
                        git rebase -i "$integration_branch"
                        git push origin "$current_ref"
                        ;;
        esac
        ;;
review | rv)
        test -z "$param1" && usage
        story_path=$(get_story_path "$param1")
        if [ "$story_path" = -1 ]; then
                echo "Ambigous  or invalid story id"
                exit
        elif [ -n "$story_path" ]; then
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
                fi
                branch="${branch##*[[:blank:]]}"
                lbranch=${branch##$remote/} # remote/1234-my -> 1234-my
                if $(git show-ref --quiet "refs/heads/$lbranch"); then
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
        fi
        ;;
accept | ac)
        story_id=$(get_storyid_from_branch)
        if [ "$story_id" = -1 ]; then
                echo "Ambigous or invalid story id in branch name"
        elif [ "$story_id" = -2 ]; then
                echo "You are not on a pivotal story branch"
        elif [ -n "$story_id" ]; then
                modify_story "$story_id" "?story\[current_state\]=accepted"
                echo -en "\033[1;34mMerge story into '$integration_branch'? [y/n]\033[0m "
                read yno
                case "$yno" in
                        [nN] )
                                exit
                                ;;
                        *)
                                git checkout "$integration_branch"
                                git merge --no-ff "$story_ref"
                                ;;
                esac
        else
                echo "Unknown error"
        fi
        ;;
reject | rj)
        story_id=$(get_storyid_from_branch)
        if [ "$story_id" = -1 ]; then
                echo "Ambigous or invalid story id in branch name"
        elif [ "$story_id" = -2 ]; then
                echo "You are not on a pivotal story branch"
        elif [ -n "$story_id" ]; then
                editor=$(git config core.editor)
                tmp_filename=/tmp/"$story_id"-reject-$(date -I)
                if [ -f "$tmp_filename" ]; then
                        rm -rf "$tmp_filename"
                fi
                $editor "$tmp_filename"
                msg=$(<$tmp_filename)
                modify_story "$story_id" "?story\[current_state\]=rejected"
                token=$(git config givotal.token)
                project_id=$(git config givotal.projectid)
                curl -s -o /dev/null -H "X-TrackerToken: $token" -X POST -H "Content-type: application/xml" \
                        -d "<note><text>$msg</text></note>" \
                        "https://www.pivotaltracker.com/services/v3/projects/$project_id/stories/$story_id/notes" 1>/dev/null
                rm -rf "$tmp_filename"
                echo -e "Story $story_id: \033[1;31mrejected\033[0m"
        else
                echo "Unknown error"
        fi
        ;;
*)
	usage
        ;;
esac
