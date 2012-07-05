Givotal
=======

Integrate git and pivotal. Givotal uses a simple python command to fetch and parse pivotal api xml. 
All pivotal data is being cached in git local orphaned branch (a branch disconnected from project history).

Installation
------------

Clone the repository and put it in your $PATH (either by placing repo inside $PATH or prepending repository path like below):

    export PATH=/givotal/path/to/repo:$PATH

Fetch data:

    git pivotal fetch
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
    Adding project Agile Pigwith id 12345 to local git config
    Enter integration branch name [devel]: 
    Fetching current..
    Fetching backlog..
    Fetching my work...
    Enter your pivotal user initials: BZ

You are ready to roll.


Usage
-----

Show current:

    git pivotal current

Show backlog:

    git pivotal backlog

Show our work:

    git pivotal mywork

Show story details:

    git pivotal show 1234567

Start working on a story:

    git pivotal start 1234567
    Branch suffix: fancy-feature
    Switched to a new branch '1234567-fancy-feature'

Finish a story (being on a branch that belongs to this story):

    git pivotal finish 

Deliver a story (being on a branch that belongs to this story):

    git pivotal deliver
    Do you want to reabase against 'devel' branch? [y]


To be continued
---------------

There are dozens of features to come:

* rating stories
* bash/zsh autocompletion of story ids and more
* story review/accept/reject (with automatic fetch and branch checkout)
* ability to create custom workflow hooks inside .git/givotal-hooks dir
* commenting stories
* listing latest comments
* showing project log
* filtering stories with tags
* searching inside stories
