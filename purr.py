#!/usr/bin/python2
# encoding: utf-8

import os
import codecs
import shutil
import subprocess
import argparse
from util.pivotal import Pivotal

parser = argparse.ArgumentParser(prog="purr",
        description="Pivotal Update Remote Registry tool")
parser.add_argument('-c', '--current', action='store_true', help="Fetch stories from current")
parser.add_argument('-b', '--backlog', action='store_true', help="Fetch stories from backlog")


def populate_dirs(stories, prefix=""):
    """Creates a directory structure for given stories

    :stories: list of stories in xml2dict format
    :returns: None

    """
    current_dirs = []
    for i, story in enumerate(stories):
        path = os.path.join(prefix, story['id'][0])
        try:
            os.makedirs(path)
        except OSError:
            pass
        current_dirs.append(story['id'][0])
        with codecs.open(os.path.join(path, 'story'), 'w', 'utf-8') as storyfile:
            storyfile.write(u"Name: %d. %s \n" % (i, story['name'][0]))
            storyfile.write(u"Type: %s \n" % story['story_type'][0])
            storyfile.write(u"Current state: %s \n" % story['current_state'][0])
            storyfile.write(u"Description:\n%s \n" % story['description'][0])
            story_colors = {
                    'feature': '\033[1;32m',
                    'bug': '\033[1;31m',
                    'chore': '\033[1;30m',
                    }
            if 'owned_by' in story:
                owner = '\033[1;34m' + "".join([x[0] for x in story['owned_by'][0].split(" ")])
            else:
                owner = ""
            story_color = story_colors[story['story_type'][0]]
            if story['current_state'][0] == 'accepted':
                story_color = '\033[1;36m'
            storyfile.write(u"__PP|%d|%s#%s %s %s\n" % (
                i,
                story_color,
                story['id'][0],
                story['name'][0],
                "(%s%s)" % (owner, story_color) if owner else ""
                ))
    # now time to unlink stale stories
    for story in os.listdir(prefix):
        if story not in current_dirs:
            shutil.rmtree(os.path.join(prefix, story))
            with open("/dev/null", 'w') as null:
                subprocess.call(['git', 'rm', '-rf', os.path.join(prefix, story)], stderr=null)


def mk_current():
    print "Fetching current.."
    iterations = p.get("https://www.pivotaltracker.com/services/v3/projects/%s/iterations/current" % p.PROJECT_ID)
    populate_dirs(iterations['iteration'][0]['stories'][0]['story'], prefix="current")


def mk_backlog():
    print "Fetching backlog.."
    iterations = p.get("https://www.pivotaltracker.com/services/v3/projects/%s/iterations/backlog" % p.PROJECT_ID)
    if not iterations or not len(iterations['iteration']):
        return
    for it, iteration in enumerate(iterations['iteration']):
        iteration_number = iteration['number'][0]
        populate_dirs(iterations['iteration'][it]['stories'][0]['story'], prefix=os.path.join("backlog", iteration_number))


if __name__ == "__main__":

    p = Pivotal()
    args = parser.parse_args()
    if args.current:
        mk_current()
    if args.backlog:
        mk_backlog()
