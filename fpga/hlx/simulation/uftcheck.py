#!/usr/bin/python

# Analyzes axi stream logs for UFT file packets

import sys
import os

try:
    from prettytable import PrettyTable
except ImportError:
    print 'Requires prettytable module'
    print 'pip install PrettyTable'
    exit(1)

if len(sys.argv) == 1:
	print 'Usage: uftcheck.py axi_stream_res.log'
	exit(0)

t = PrettyTable(['File', 'D/C', 'Control', 'TCID', 'SEQ'])

if '--ip' in sys.argv:

for fname in sys.argv:
	# print 'testing', fname
	if (not fname.endswith(".log")) and (not fname.endswith(".txt")):
		continue
	fnameshort = os.path.splitext(os.path.basename(fname))[0]

	# convert file to int array
	with open(fname) as f:
	    content = f.readlines()
	content = [x.strip() for x in content] 
	p = [ int(x,16) for x in content ]
	
	# Analyze data/cmd
	if p[0] > 127:
		dc = 'D'
		cmd = ''
		tcid = p[0]-128
		seq = p[1]*pow(2,16) + p[2]*pow(2,8) + p[3]
		t.add_row([fnameshort, dc, cmd, str(tcid), str(seq)])
	else:
		dc = 'C'
		if p[0] == 0:
			cmd = 'FT Start'
			seq = p[4]*pow(2,24) + p[5]*pow(2,16) + p[6]*pow(2,8) + p[7]
		if p[0] == 1:
			cmd = 'FT Stop'
		if p[0] == 2:
			cmd = 'ACK packet'
			seq = p[4]*pow(2,24) + p[5]*pow(2,16) + p[6]*pow(2,8) + p[7]
		if p[0] == 2:
			cmd = 'ACK transfer'
		tcid = p[1]*pow(2,16) + p[2]*pow(2,8) + p[3]
		t.add_row([fnameshort, dc, cmd, str(tcid), str(seq)])

print t
