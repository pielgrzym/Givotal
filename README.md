Givotal
=======

Integrate git and pivotal.

Features:
* fast pivotal data fetching using simple python script (purr.py)
* caching pivotal data using git orphaned branch - using plain files - fetching data using git mechanisms
* hacker-friendly - written mostly in bash/python - easy to extend and customize
* color output - yay!
* configuration per repository or global using git builtin config system

Installation
------------

Clone the repository and put it in your `$PATH` (either by placing repo inside `$PATH` or prepending repository path like below):

    export PATH=<path_to_givotal_source_without_trailing_/_>:$PATH

For completion to work you also need a one extra step depending on your shell.

For bash:

    source <path_to_givotal_source>/completion/git-pivotal-completion.bash

For zsh

    source <path_to_givotal_source>/completion/git-pivotal-completion.zsh

Aliases I find usefull (optional step):

    alias gva='git pv accept'
    alias gvb='git pv backlog'
    alias gvc='git pv current'
    alias gvd='git pv deliver'
    alias gvf='git pv fetchall'
    alias gvfn='git pv finish'
    alias gvj='git pv reject'
    alias gvm='git pv mywork'
    alias gvr='git pv review'
    alias gvs='git pv start'
    alias gvv='git pv show'

Fetch data:

    git pivotal fetchall
    Creating Givotal orphaned branch...
    Pivotal token not found in your gitconfig.
    Username [myusername]: goodfella
    Password:
    Apply token to git global config? (Y/n)
    Choose a project:
        1) Agile Pig
        2) Fast Swine
        3) Hog Travel
    Enter number [1]:
    Adding project Agile Pig with id 12345 to local git config
    Enter integration branch name [devel]: 
    Fetching current..
    Fetching backlog..
    Fetching my work...
    Enter your pivotal user initials: BZ

You are ready to roll.


Usage
-----

Update pivotal data:

    git pivotal fetchall

Update just current and mywork:

    git pivotal fetch

Show current:

    git pivotal current

Show backlog:

    git pivotal backlog

Show our work:

    git pivotal mywork

Show story details:

    git pivotal show [ 1234567 ]

Without story id givotal tries to fetch id from current branch name (XXXXXXX-some-name; where XXXXXXX is the id)

Start working on a story:

    git pivotal start 1234567
    Branch suffix: fancy-feature
    Switched to a new branch '1234567-fancy-feature'

Finish a story (being on a branch that belongs to this story):

    git pivotal finish [ 1234567 ]

Without story id givotal tries to fetch id from current branch name. 

Deliver a story (being on a branch that belongs to this story):

    git pivotal deliver [ 1234567 ]
    Do you want to rebase against 'devel' branch? [y]

Without story id givotal tries to fetch id from current branch name. 

Review a story

    git pivotal review 123456

Accept a story under review:

    git pivotal review 123456
    git pivotal accept
    Merge into 'devel'? [Y/n] y

or

    git pivotal accept [ 123456 ]

Without story id givotal tries to fetch id from current branch name. 

Reject a story under review:

    git pivotal review 123456
    git pivotal reject

or

    git pivotal reject [ 1234567 ]

Without story id givotal tries to fetch id from current branch name. 
Reject will fire up `git config core.editor` and you can post a reason why the story was rejected.

Comment a story:

    git pivotal comment [ 1234567 ]
    
Without story id givotal tries to fetch id from current branch name. 
Commenting also fires up `git config core.editor` to write comment.

To be continued
---------------

There are dozens of features to come:

* rating stories
* <del>bash/zsh autocompletion of story ids and more</del>
* <del>story review/accept/reject (with automatic fetch and branch checkout)</del>
* ability to create custom workflow hooks inside .git/givotal-hooks dir
* <del>commenting stories</del>
* listing latest comments
* showing project log
* filtering stories with tags
* searching inside stories
