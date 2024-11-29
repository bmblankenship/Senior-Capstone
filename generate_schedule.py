# Documentation for pylightxl library
# https://pylightxl.readthedocs.io/en/latest/

import pylightxl as xl

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

for i, dura in enumerate(duration):
    if 'day' in dura in dura:
        dura = dura.replace('day', '')
        dura = dura.replace('s', '')
        dura = int(dura)
        dura = dura * 24
        duration[i] = dura
        i += 1
    elif 'week' in dura in dura:
        dura = dura.replace('week', '')
        dura = dura.replace('s', '')
        dura = int(dura)
        dura = dura * 24 * 7
        duration[i] = dura
        i += 1

# Duration is now in hours
print(duration)

# Create output File
# Below is a test case mostly to explore the functionality of the library.
output = xl.Database()
output.add_ws(ws="Schedule")

output.ws(ws="Schedule").update_index(row = 1, col = 1, val = "Branch Number")
for row_id, data in enumerate(branches, start = 2):
    output.ws(ws="Schedule").update_index(row = row_id, col = 1, val = data)

output.ws(ws="Schedule").update_index(row = 1, col = 2, val = "Duration (Hours)") 
for row_id, data in enumerate(duration, start = 2):
    output.ws(ws="Schedule").update_index(row = row_id, col = 2, val = data)

output.ws(ws="Schedule").update_index(row = 1, col = 3, val = "Considerations") 
for row_id, data in enumerate(considerations, start = 2):
    if(data == ''):
        data = ' '
    output.ws(ws="Schedule").update_index(row = row_id, col = 3, val = data)

xl.writexl(db = output, fn="schedule.xlsx")   