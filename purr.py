#!/usr/bin/env python
# encoding: utf-8

from util.pivotal import Pivotal

p = Pivotal()

iterations = p.get("https://www.pivotaltracker.com/services/v3/projects/%s/iterations" % p.PROJECT_ID)
