#!/usr/bin/python2

# from kenny tilton's code:
# https://github.com/kennytilton/matrix/blob/master/js/matrix/matrix_compile.py

import httplib, urllib, sys

# Define the parameters for the POST request and encode them in
# a URL-safe format.

with open(sys.argv[1],'r') as f:
    js_orig = f.read()

params = urllib.urlencode([
    ('js_code', js_orig),
    ('compilation_level', 'SIMPLE_OPTIMIZATIONS'),
    ('output_format', 'text'),
    ('formatting', 'pretty_print'),
    ('output_info', 'warnings'),
  ])

# Always use the following value for the Content-type header.
headers = { "Content-type": "application/x-www-form-urlencoded" }
conn = httplib.HTTPConnection('closure-compiler.appspot.com')
conn.request('POST', '/compile', params, headers)
response = conn.getresponse()
data = response.read()
print(data)
conn.close()
