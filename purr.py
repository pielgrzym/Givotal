#!/usr/bin/env python
# encoding: utf-8

import subprocess
import getpass
import urllib
import urllib2
from xml.dom import minidom


def setup():
    url = "http://www.pivotaltracker.com/services/v3/projects"
    print 'token', TOKEN
    req = urllib2.Request(url, None, {'X-TrackerToken': TOKEN})
    response = urllib2.urlopen(req)
    dom = minidom.parseString(response.read())
    projects = []
    for p in dom.getElementsByTagName('project'):
        projects.append([
            p.getElementsByTagName('id')[0].firstChild.data,
            p.getElementsByTagName('name')[0].firstChild.data
        ])
    print "Choose a project:"
    for i, p in enumerate(projects):
        print "    %d) %s" % (i + 1, p[1])
    choice = raw_input("Enter number [1]: ")
    choice = choice or 1
    choice = int(choice)
    if choice in range(1, len(projects) + 1):
        selected_project = projects[choice - 1]
        print "Adding project %s with id %s to local git config" % (selected_project[0],
                selected_project[1])
        subprocess.call(['git', 'config', 'givotal.projectid', selected_project[0]])
    else:
        print "Wrong choice:", choice
        exit(1)


def getToken():
    print "Pivotal token not found in your gitconfig."
    sysuser = getpass.getuser()
    username = raw_input("Username [%s]:" % sysuser)
    username = username or sysuser
    password = getpass.getpass()
    data = urllib.urlencode({'username': username, 'password': password})
    request = urllib2.Request("https://www.pivotaltracker.com/services/v3/tokens/active", data)
    try:
        response = urllib2.urlopen(request)
    except urllib2.HTTPError:
        print "Wrong username or password"
        exit(1)
    dom = minidom.parseString(response.read())
    return dom.getElementsByTagName('guid')[0].firstChild.data

try:
    TOKEN = subprocess.check_output(['git', 'config', 'givotal.token'])
except subprocess.CalledProcessError:
    TOKEN = getToken()
    choice = raw_input("Apply token to git global config? (Y/n)")
    choice = choice or 'Y'
    if choice in ['y', 'Y', 'Yes', 'yes']:
        subprocess.check_output(['git', 'config', '--global', 'givotal.token', TOKEN])
    else:
        subprocess.check_output(['git', 'config', 'givotal.token', TOKEN])

print TOKEN

try:
    PROJECT_ID = subprocess.check_output(['git', 'config', 'givotal.projectid'])
except subprocess.CalledProcessError:
    setup()
