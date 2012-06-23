#!/usr/bin/env python
# encoding: utf-8

import os
import codecs
import shutil
import subprocess
from util.pivotal import Pivotal

p = Pivotal()


def mk_current():
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
        print story['id'][0]
        with codecs.open(os.path.join(path, 'story'), 'w', 'utf-8') as storyfile:
            storyfile.write(u"Name: %s \n" % story['name'][0])
            storyfile.write(u"Type: %s \n" % story['story_type'][0])
            storyfile.write(u"Current state: %s \n" % story['current_state'][0])
            storyfile.write(u"Description:\n%s \n" % story['description'][0])
    # now time to unlink stale stories
    for story in os.listdir(basedir):
        if story not in current_dirs:
            shutil.rmtree(os.path.join(basedir, story))
            with open("/dev/null", 'w') as null:
                subprocess.call(['git', 'rm', '-rf', os.path.join(basedir, story)], stderr=null)

mk_current()
