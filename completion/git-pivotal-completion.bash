#!/usr/bin/env bash
GIVOTAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/..
. $GIVOTAL_DIR/givotal-common

_git_pv() 
{
        local subcommands="fetch fetchall current backlog mywork start show finish deliver review accept reject comment"
        local subcommand="$(__git_find_on_cmdline "$subcommands")"
        if [ -z "$subcommand" ]; then
                __gitcomp "$subcommands"
                return
        fi
        
        case "$subcommand" in
                show | start | comment)
                        __git_pv_show_all_ids
                        ;;
                finish | deliver)
                        __git_pv_show_my_ids
                        ;;
                review | accept | reject)
                        __git_pv_show_current_ids
                        ;;
                *)
                        COMREPLY=()
                        ;;
        esac
}

__git_pv_show_all_ids() 
{
        # oh mama, thats a long pipe
        local ids=$(git grep --name-only "^__PP" $givotal_ref -- current backlog | cut -d":" -f 2 | sed 's/current\///g' | sed 's/backlog\/[0-9]*\///g' | sed 's/\/story//g' | sort -u)
        __gitcomp "$ids"
}

__git_pv_show_current_ids() 
{
        # oh mama, thats a long pipe
        local ids=$(git grep --name-only "^__PP" $givotal_ref -- current | cut -d":" -f 2 | sed 's/current\///g' | sed 's/\/story//g' | sort -u)
        __gitcomp "$ids"
}

__git_pv_show_backlog_ids() 
{
        # oh mama, thats a long pipe
        local ids=$(git grep --name-only "^__PP" $givotal_ref -- backlog | cut -d":" -f 2 | sed 's/backlog\/[0-9]*\///g' | sed 's/\/story//g' | sort -u)
        __gitcomp "$ids"
}

__git_pv_show_my_ids() 
{
        # oh mama, thats a long pipe
        local ids=$(git grep --name-only "^__PP" $givotal_ref -- mywork | cut -d":" -f 2 | sed 's/mywork\///g' | sed 's/\/story//g' | sort -u)
        __gitcomp "$ids"
}

