#!/usr/bin/env python

import os, os.path, re

prioritized = ['INBOX', '.list.boost']

def prio_cmp(x, y):
   for prefix in prioritized:
       xsw = x.startswith(prefix)
       ysw = y.startswith(prefix)
       if xsw and ysw:
          return cmp(x, y)
       elif xsw:
          return -1
       elif ysw:
          return +1
   return cmp(x, y)

mobile = os.environ['HOSTNAME'] != 'shogun'
# TODO: python 2.5 only :/
#    pattern = '(INBOX|list.*)' if mobile else '.*'
filter_pattern = ''
if mobile:
    filter_pattern = '(INBOX|Drafts|list.*)' 
else:
    filter_pattern = '.*'
