# Documentation for pylightxl library
# https://pylightxl.readthedocs.io/en/latest/

import pylightxl as xl

"""This file will take input of an excel sheet and generate a schedule for MATPOWER to run powerflow checks on."""

class Outage:
    """
    class used to store pertinent information about outages
    will need to be expanded to accommodate the functionality we need
    """
    def __init__(self, out_duration, branch):
        self.duration = out_duration
        self.branch = branch
        self.concurrency = None

    def set_concurrency(self, con_branches, min_overlap):
        """
        list con_branches: list of branches that will be out concurrently eg: branch 1 and 2 would be [1, 2]
        integer min_overlap: integer value of minimum time overlap required for concurrent outage
        """
        for a, branch in con_branches:
            self.concurrency[a,0] = branch
            self.concurrency[a,1] = min_overlap

# We will need to get the sheet location into here at some point
# Likely will require some integration with the GUI
sheet = xl.readxl(fn='RequiredOutages.xlsx' , ws='Transmission')

# Fetch branch number
branches = sheet.ws(ws='Transmission').col(col=3)

# Fetch outage duration (days)
duration = sheet.ws(ws='Transmission').col(col=4)

# Fetch other considerations
considerations = sheet.ws(ws='Transmission').col(col=5)

# Sanitize duration inputs
# This is realistically going to go away when we dictate the file template later.

for i, dura in enumerate(duration):
    if 'day' in dura:
        dura = dura.replace('day', '')
        dura = dura.replace('s', '')
        dura = int(dura)
        dura = dura * 24
        duration[i] = dura
    elif 'week' in dura:
        dura = dura.replace('week', '')
        dura = dura.replace('s', '')
        dura = int(dura)
        dura = dura * 24 * 7
        duration[i] = dura
    elif 'Duration' in dura:
        dura = dura.replace('Duration', 'Duration (Hours)')
        duration[i] = dura

# Duration is now in hours
print(duration)

# Create output File
# Below is a test case mostly to explore the functionality of the library.
output = xl.Database()
output.add_ws(ws="Schedule")

for row_id, data in enumerate(branches, start = 1):
    output.ws(ws="Schedule").update_index(row = row_id, col = 1, val = data)

for row_id, data in enumerate(duration, start = 1):
    output.ws(ws="Schedule").update_index(row = row_id, col = 2, val = data)

for row_id, data in enumerate(considerations, start = 1):
    if(data == ''):
        data = ' '
    output.ws(ws="Schedule").update_index(row = row_id, col = 3, val = data)

xl.writexl(db = output, fn="schedule.xlsx")   