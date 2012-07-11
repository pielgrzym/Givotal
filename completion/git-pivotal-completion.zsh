#!/usr/bin/env zsh

GIVOTAL_DIR=$(dirname "$(echo "$0" | sed -e 's,\\,/,g')")/..

_git-pv ()
{
        local curcontext="$curcontext" state line
        typeset -A opt_args
        _arguments -C \
                ':command:->command' \
                '*::options:->options'
        	case $state in
                        (command)

                                local -a subcommands
                                subcommands=(
                                'fetch:Fetch pivotal data from current and mywork'
                                'fetchall:Fetch all pivotal data'
                                'current:Show stories from current'
                                'backlog:Show stories from backlog'
                                'mywork:Show stories from mywork'
                                'start:Start working on a story'
                                'show:Show story details'
                                'finish:Finish a story in pivotal'
                                'deliver:Deliver a story in pivotal and push to remote'
                                'review:Checkout story remote branch to see the work'
                                'accept:Accept the story in pivotal and merge to integration branch'
                                'reject:Reject and comment story in pivotal'
                                'comment:Comment story in pivotal'
                                )
                                _describe -t commands 'git pv' subcommands
                                ;;

                        (options)
                                case $line[1] in
                                        show | start | comment)
                                                __git_pv_show_all_ids
                                                ;;
                                        finish | deliver)
                                                __git_pv_show_my_ids
                                                ;;
                                        review | accept | reject)
                                                __git_pv_show_current_ids
                                                ;;
                                esac
                                ;;
                esac
}

__git_pv_show_all_ids() 
{
        # oh mama, thats a long pipe
        local -a ids
        ids=($(git grep --name-only "^__PP" $givotal_ref -- current backlog | cut -d":" -f 2 | sed 's/current\///g' | sed 's/backlog\/[0-9]*\///g' | sed 's/\/story//g' | sort -u))
        compadd "$@" "$ids[@]"
}

__git_pv_show_current_ids() 
{
        # oh mama, thats a long pipe
        local -a ids
        ids=($(git grep --name-only "^__PP" $givotal_ref -- current | cut -d":" -f 2 | sed 's/current\///g' | sed 's/\/story//g' | sort -u))
        compadd "$@" "$ids[@]"
}

__git_pv_show_backlog_ids() 
{
        # oh mama, thats a long pipe
        local -a ids
        ids=($(git grep --name-only "^__PP" $givotal_ref -- backlog | cut -d":" -f 2 | sed 's/backlog\/[0-9]*\///g' | sed 's/\/story//g' | sort -u))
        compadd "$@" "$ids[@]"
}

__git_pv_show_my_ids() 
{
        # oh mama, thats a long pipe
        local -a ids
        ids=($(git grep --name-only "^__PP" $givotal_ref -- mywork | cut -d":" -f 2 | sed 's/mywork\///g' | sed 's/\/story//g' | sort -u))
        compadd "$@" "$ids[@]"
}


zstyle ':completion:*:*:git:*' user-commands pv:'pivotal wrapper for git'
