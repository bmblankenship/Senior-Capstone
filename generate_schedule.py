# Documentation for pylightxl library
# https://pylightxl.readthedocs.io/en/latest/

import pylightxl as xl

"""This file will take input of an excel sheet and generate a schedule for MATPOWER to run powerflow checks on."""

# We will need to get the sheet location into here at some point
# Likely will require some integration with the GUI

sheet = xl.readxl(fn='RequiredOutages.xlsx' , ws=('Transmission'))

# Fetch branch number
branches = sheet.ws(ws='Transmission').col(col=3)

# Fetch outage duration (days)
duration = sheet.ws(ws='Transmission').col(col=4)

# Fetch other considerations
considerations = sheet.ws(ws='Transmission').col(col=5)