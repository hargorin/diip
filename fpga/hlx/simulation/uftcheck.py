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

uftt = PrettyTable(['File', 'From', 'To', 'D/C', 'Control', 'TCID', 'SEQ'])
arpt = PrettyTable(['File', 'Req/Rep', 'Sender HW', 'Sender IP', 'Target HW', 'Target IP'])


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


	off = 0
	uftfrom = ''
	uftto = ''
	# check if user specified that the packets are ethernet frames
	if '-e' in sys.argv:
		# check if ARP
		if (p[12] == 0x08) and (p[13] == 0x06):
			# Report ARP packet information
			off = 14
			x=off+7
			op = 'req' if p[x] == 1 else 'resp'
			x=off+8
			senderhw = format(p[x],'x')+':'+format(p[x+1],'x')+':'+format(p[x+2],'x')+':'+format(p[x+3],'x')+':'+format(p[x+4],'x')+':'+format(p[x+5],'x')
			x=off+14
			senderip = str(p[x])+'.'+str(p[x+1])+'.'+str(p[x+2])+'.'+str(p[x+3])
			x=off+18
			targethw = format(p[x],'x')+':'+format(p[x+1],'x')+':'+format(p[x+2],'x')+':'+format(p[x+3],'x')+':'+format(p[x+4],'x')+':'+format(p[x+5],'x')
			x=off+24
			targetip = str(p[x])+'.'+str(p[x+1])+'.'+str(p[x+2])+'.'+str(p[x+3])
			arpt.add_row([fnameshort, op, senderhw, senderip, targethw, targetip])
			continue
		else:
			# its an UFT packet
			# Get from and to
			x=26
			ufromip = str(p[x])+'.'+str(p[x+1])+'.'+str(p[x+2])+'.'+str(p[x+3])
			x=30
			utoip = str(p[x])+'.'+str(p[x+1])+'.'+str(p[x+2])+'.'+str(p[x+3])
			x=34
			ufromport = p[x]*256 + p[x+1]
			x=36
			utoport = p[x]*256 + p[x+1]
			uftfrom = ufromip + ' (' + str(ufromport) + ')'
			uftto = utoip + ' (' + str(utoport) + ')'
			# remove Ethernet/IP and UDP header
			p = p[42:]
	
	# Analyze data/cmd
	if p[0] > 127:
		dc = 'D'
		cmd = ''
		tcid = p[0]-128
		seq = p[1]*pow(2,16) + p[2]*pow(2,8) + p[3]
		uftt.add_row([fnameshort, uftfrom, uftto, dc, cmd, str(tcid), str(seq)])
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
		if p[0] == 3:
			cmd = 'ACK transfer'
		tcid = p[1]*pow(2,16) + p[2]*pow(2,8) + p[3]
		uftt.add_row([fnameshort, uftfrom, uftto, dc, cmd, str(tcid), str(seq)])

print '---- ARP Requests ----'
print arpt
print '---- UFT Packets ----'
print uftt
