#!/usr/bin/env python
# encoding: utf-8

import subprocess
import getpass
import urllib
import urllib2
from xml.dom import minidom


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
    API_KEY = subprocess.check_output(['git', 'config', 'givotal.token'])
except subprocess.CalledProcessError:
    API_KEY = subprocess.check_output(['git', 'config', 'givotal.token', getToken()])

print API_KEY
