#!/usr/bin/python

# Analyzes axi stream logs for UFT file packets

import sys
import os
import json
from pprint import pprint

try:
    from prettytable import PrettyTable
except ImportError:
    print 'Requires prettytable module'
    print 'pip install PrettyTable'
    exit(1)

def parseArray(p, name):
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
			arpt.add_row([name, op, senderhw, senderip, targethw, targetip])
			return
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
		uftt.add_row([int(filter(str.isdigit, name)), uftfrom, uftto, dc, cmd, str(tcid), str(seq)])
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
		uftt.add_row([int(filter(str.isdigit, name)), uftfrom, uftto, dc, cmd, str(tcid), str(seq)])

# ---------------------------------------------
# MAIN
# ---------------------------------------------
# Usage warning
if len(sys.argv) == 1:
	print 'Usage: uftcheck.py axi_stream_res.log'
	print '    -e   Ethernet header also included'
	print '    -j   Input in wireshark JSON format'
	exit(0)

# check if file exists
isfile = 0
for fname in sys.argv[1:]:
	if os.path.isfile(fname):
		isfile = 1
if isfile is 0:
	print 'uftcheck.py: No files in input arguments'
	exit(0)

# prepare tables
uftt = PrettyTable(['File', 'From', 'To', 'D/C', 'Control', 'TCID', 'SEQ'])
arpt = PrettyTable(['File', 'Req/Rep', 'Sender HW', 'Sender IP', 'Target HW', 'Target IP'])

# If JSON mode
if '-j' in sys.argv:	
	for fname in sys.argv:
		if (not fname.endswith(".json")):
			continue
		data = json.load(open(fname))
		i=0
		seq=-1
		tcid=-1
		for pack in data:
			i = i + 1
			if "arp" in pack["_source"]["layers"]:
				op = 'req' if pack["_source"]["layers"]["arp"]["arp.opcode"] == "1" else 'resp'
				senderhw = pack["_source"]["layers"]["arp"]["arp.src.hw_mac"]
				senderip = pack["_source"]["layers"]["arp"]["arp.src.proto_ipv4"]
				targethw = pack["_source"]["layers"]["arp"]["arp.dst.hw_mac"]
				targetip = pack["_source"]["layers"]["arp"]["arp.dst.proto_ipv4"]
				arpt.add_row([str(i), op, senderhw, senderip, targethw, targetip])
			
			if "data" in pack["_source"]["layers"]:
				uftfrom = pack["_source"]["layers"]["ip"]["ip.src"]
				uftfrom = uftfrom + ' (' + pack["_source"]["layers"]["udp"]["udp.srcport"] + ')'
				uftto = pack["_source"]["layers"]["ip"]["ip.dst"]
				uftto = uftto + ' (' + pack["_source"]["layers"]["udp"]["udp.dstport"] + ')'
				dt = pack["_source"]["layers"]["data"]["data.data"].split(":")
				p = [ int(x,16) for x in dt ]
				if p[0] > 127:
					dc = 'D'
					cmd = ''
					tcid = p[0]-128
					seq = p[1]*pow(2,16) + p[2]*pow(2,8) + p[3]
					# uftt.add_row([str(i), uftfrom, uftto, dc, cmd, str(tcid), str(seq)])
					uftt.add_row([int(filter(str.isdigit, str(i))), uftfrom, uftto, dc, cmd, str(tcid), str(seq)])

				else:
					dc = 'C'
					if p[0] == 0:
						cmd = 'FT Start'
						seq = p[4]*pow(2,24) + p[5]*pow(2,16) + p[6]*pow(2,8) + p[7]
					elif p[0] == 1:
						cmd = 'FT Stop'
					elif p[0] == 2:
						cmd = 'ACK packet'
						seq = p[4]*pow(2,24) + p[5]*pow(2,16) + p[6]*pow(2,8) + p[7]
					elif p[0] == 3:
						cmd = 'ACK transfer'
					else:
						cmd = 'unknown'
					tcid = p[1]*pow(2,16) + p[2]*pow(2,8) + p[3]
					# uftt.add_row([str(i), uftfrom, uftto, dc, cmd, str(tcid), str(seq)])
					uftt.add_row([int(filter(str.isdigit, str(i))), uftfrom, uftto, dc, cmd, str(tcid), str(seq)])
		# pprint(data[2]["_source"]["layers"]["arp"])
	print '---- ARP Requests ----'
	print arpt
	print '---- UFT Packets ----'
	print uftt.get_string(sortby="File")
	exit(0)

for fname in sys.argv:
	# print 'testing', fname
	if (not fname.endswith(".log")) and (not fname.endswith(".txt")):
		continue
	name = os.path.splitext(os.path.basename(fname))[0]

	# convert file to int array
	with open(fname) as f:
	    content = f.readlines()
	content = [x.strip() for x in content] 
	p = [ int(x,16) for x in content ]


	parseArray(p, name)

print '---- ARP Requests ----'
print arpt
print '---- UFT Packets ----'
print uftt.get_string(sortby="File")
