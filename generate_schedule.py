# Documentation for pylightxl library
# https://pylightxl.readthedocs.io/en/latest/

import pylightxl as xl
import re

"""This file will take input of an excel sheet and generate a schedule for MATPOWER to run powerflow checks on."""

# We will need to get the sheet location into here at some point
# Likely will require some integration with the GUI

sheet = xl.readxl(fn='RequiredOutages.xlsx' , ws='Transmission')

# Fetch branch number
branches = sheet.ws(ws='Transmission').col(col=3)

# Fetch outage duration (days)
duration = sheet.ws(ws='Transmission').col(col=4)

# Fetch other considerations
considerations = sheet.ws(ws='Transmission').col(col=5)

# Remove headers from imported arrays and print contents for testing
branches.pop(0)
duration.pop(0)
considerations.pop(0)

#print(branches)
print(duration)
#print(considerations)

# Sanitize duration inputs

i = 0
for dura in duration:
    if 'day' in dura or 'days' in dura:
        dura = dura.replace('day', '')
        dura = dura.replace('s', '')
        dura = int(dura)
        dura = dura * 24
        duration[i] = dura
        i += 1
    elif 'week' in dura or 'weeks' in dura:
        dura = dura.replace('week', '')
        dura = dura.replace('s', '')
        dura = int(dura)
        dura = dura * 24 * 7
        duration[i] = dura
        i += 1

print(duration)