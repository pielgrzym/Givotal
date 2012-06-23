#!/usr/bin/env python
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


def mk_current():
    print "Fetching current.."
    basedir = "current"
    iterations = p.get("https://www.pivotaltracker.com/services/v3/projects/%s/iterations/current" % p.PROJECT_ID)
    current_dirs = []
    for i, story in enumerate(iterations['iteration'][0]['stories'][0]['story']):
        path = os.path.join(basedir, story['id'][0])
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
    # now time to unlink stale stories
    for story in os.listdir(basedir):
        if story not in current_dirs:
            shutil.rmtree(os.path.join(basedir, story))
            with open("/dev/null", 'w') as null:
                subprocess.call(['git', 'rm', '-rf', os.path.join(basedir, story)], stderr=null)


def mk_backlog():
    print "Fetching backlog.."
    basedir = "backlog"
    iterations = p.get("https://www.pivotaltracker.com/services/v3/projects/%s/iterations/backlog" % p.PROJECT_ID)
    current_dirs = []
    for it, iteration in enumerate(iterations['iteration']):
        iteration = iteration['number'][0]
        for i, story in enumerate(iterations['iteration'][it]['stories'][0]['story']):
            path = os.path.join(basedir, iteration, story['id'][0])
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
        # now time to unlink stale stories
    for it, iteration in enumerate(iterations['iteration']):
        iteration = iteration['number'][0]
        for story in os.listdir(os.path.join(basedir, iteration)):
            if story not in current_dirs:
                shutil.rmtree(os.path.join(basedir, iteration, story))
                with open("/dev/null", 'w') as null:
                    subprocess.call(['git', 'rm', '-rf', os.path.join(basedir, iteration, story)], stderr=null)


if __name__ == "__main__":

    p = Pivotal()
    args = parser.parse_args()
    if args.current:
        mk_current()
    if args.backlog:
        mk_backlog()
