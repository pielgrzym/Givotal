#!/usr/bin/env python
# encoding: utf-8

import subprocess

try:
    API_KEY = subprocess.check_output(['git', 'config', 'givotal.apikey'])
except subprocess.CalledProcessError:
    print """Pivotal api key not found in your gitconfig.
    Please add it via:
        >>> git config --global givotal.apikey = "<YOUR_API_KEY>"
    """
    exit(1)

print API_KEY
