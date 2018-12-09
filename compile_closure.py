#!/usr/bin/python3

# from kenny tilton's code:
# https://github.com/kennytilton/matrix/blob/master/js/matrix/matrix_compile.py

import requests, urllib, sys

# Define the parameters for the POST request and encode them in
# a URL-safe format.

with open(sys.argv[1],'r') as f:
    js_orig = f.read()


par = {'js_code': js_orig,
       'compilation_level': 'SIMPLE_OPTIMIZATIONS',
       'output_format': 'text',
       'formatting': 'pretty_print',
       'output_info': 'compiled_code',}

r = requests.post('https://closure-compiler.appspot.com/compile', data=par)
print(r.text)
