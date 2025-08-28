#!/usr/bin/python3
'''
Set the title of the terminal window
'''
import sys

title = " ".join(sys.argv[1:])
print("title %s" % title)
# \033 is the ANSII escape character
# ]0; is the command to set the title
# \a is the bell char (7) to end the title sequence
print("\033]0;" + title, end="\a", flush=True)
