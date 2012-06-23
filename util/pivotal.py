import subprocess
import getpass
import urllib
import urllib2
from util.xmlhelper import xmltodict


class Pivotal(object):
    def __init__(self):
        try:
            self.TOKEN = subprocess.check_output(['git', 'config', 'givotal.token'])
            self.USERNAME = subprocess.check_output(['git', 'config', 'givotal.username'])
        except subprocess.CalledProcessError:
            self.TOKEN, self.USERNAME = self.getToken()
            choice = raw_input("Apply token to git global config? (Y/n)")
            choice = choice or 'Y'
            if choice in ['y', 'Y', 'Yes', 'yes']:
                subprocess.check_output(['git', 'config', '--global', 'givotal.token', self.TOKEN])
                subprocess.check_output(['git', 'config', '--global', 'givotal.username', self.USERNAME])
            else:
                subprocess.check_output(['git', 'config', 'givotal.token', self.TOKEN])
                subprocess.check_output(['git', 'config', 'givotal.username', self.USERNAME])

        try:
            self.PROJECT_ID = subprocess.check_output(['git', 'config', 'givotal.projectid'])
        except subprocess.CalledProcessError:
            self.PROJECT_ID = self.setupProjectId()
        self.PROJECT_ID = self.PROJECT_ID.strip()

    def get(self, url):
        req = urllib2.Request(url, None, {'X-TrackerToken': self.TOKEN})
        response = urllib2.urlopen(req)
        return xmltodict(response.read())

    def getToken(self):
        print "Pivotal token not found in your gitconfig."
        sysuser = getpass.getuser()
        username = raw_input("Username [%s]: " % sysuser)
        username = username or sysuser
        password = getpass.getpass()
        data = urllib.urlencode({'username': username, 'password': password})
        request = urllib2.Request("https://www.pivotaltracker.com/services/v3/tokens/active", data)
        try:
            response = urllib2.urlopen(request)
        except urllib2.HTTPError:
            print "Wrong username or password"
            exit(1)
        dom = xmltodict(response.read())
        return dom['guid'][0].strip(), username.strip()

    def setupProjectId(self):
        projects = []
        project_list = self.get("http://www.pivotaltracker.com/services/v3/projects")
        for p in project_list['project']:
            projects.append([
                p['id'][0],
                p['name'][0],
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
            return selected_project[0]
        else:
            print "Wrong choice:", choice
            exit(1)
