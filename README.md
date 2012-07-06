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

    export PATH=/givotal/path/to/repo:$PATH

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

Review a story

   git pivotal review 123456


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
