package diip_java_cc.Model;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.nio.ByteBuffer;
import java.util.Arrays;

public class UFT {

	// ================================================================================
	// Settings
	// ================================================================================
	public static final int TX_PACKET_DATA_SIZE = 1024;
	public static final int UFT_CONTROLL_SIZE = 34;

	// How many times the UDP receive socket can timeout before the send/receive is 
	// aborted
	public static final int TIMEOUT_MAX = 100;
	
	// ================================================================================
	// Types
	// ================================================================================
	public enum pktType {
		FTS, FTP, ACKFP, ACKFT, USER, DATA
	};

	// ================================================================================
	// Public static methods
	// ================================================================================
	/**
	 * Receive a UFT data packet
	 * @param socket
	 * @param address
	 * @return
	 */
	public static UFTData receive (DatagramSocket s) {
		UFTData rx = new UFTData();
		int tcid, nseq;
		int timeoutCtr = 0;
		int totalrxbytes=0;

	    byte[] buf = new byte[1500];
        DatagramPacket packet = new DatagramPacket(buf, buf.length);
    	Util.setDatagramSoTimeout(s, 1);
		
		// Wait for start packet
        boolean startreceived = false;
        while(!startreceived) {
        	// Check timeout condition
        	if(timeoutCtr > TIMEOUT_MAX) {
        		rx.status = UFTData.Status.TIMEOUT;
//        		System.out.println("TIMEOUT");
        		return rx;
        	}
			try {
				s.receive(packet);
				
			} catch (SocketTimeoutException e1) {
				// no data recevied, continue
				timeoutCtr++;
				continue;
			} catch (IOException e) {
				e.printStackTrace();
			}
//			System.out.printf("received %d bytes from %s\n", packet.getLength(), packet.getAddress().toString());
//        	System.out.println(Arrays.toString(packet.getData()));
			// Check for start packet
			if(getPacketType(buf) == pktType.FTS)
				startreceived = true;
			// Check for user register
			if(getPacketType(buf) == pktType.USER) {
				rx.status = UFTData.Status.USER;
				rx.uregAddress = buf[3];
				ByteBuffer bb = ByteBuffer.wrap(buf);
				int dummy = bb.getInt();
				rx.uregContent = bb.getInt();
				rx.address = packet.getAddress();
				return rx;
			}
        }
		
        // get tcid and nseq from start packet
        tcid = ((0xFF & buf[1])<<16) + ((0xFF & buf[2])<<8) + ((0xFF & buf[3])<<0); 
        nseq = ((0xFF & buf[4])<<24) + ((0xFF & buf[5])<<16) + ((0xFF & buf[6])<<8) + ((0xFF & buf[7])<<0); 

        // Allocate data
        byte[] rxdata = new byte[1500*nseq];
        int rxdataptr = 0;
        
		// Receive all data
        timeoutCtr = 0;
//        System.out.printf("tcid=%d nseq=%d\n", tcid, nseq);
        for(int nrx = 0; nrx < nseq; ) {
        	// Check timeout condition
        	if(timeoutCtr > TIMEOUT_MAX) {
        		rx.status = UFTData.Status.TIMEOUT;
//        		System.out.println("TIMEOUT");
        		return rx;
        	}
			try {
				s.receive(packet);
			} catch (SocketTimeoutException e1) {
				// no data recevied, continue
				timeoutCtr++;
				continue;
			} catch (IOException e) {
				e.printStackTrace();
			}

//			System.out.printf("received %d bytes from %s\n", packet.getLength(), packet.getAddress().toString());
//        	System.out.println(Arrays.toString(packet.getData()));
        	
			// Check for data and correct tcid
			if(getPacketType(buf) == pktType.DATA)
				
				if((buf[0]&0x7f) == tcid) {
					// Copy data from packet to buffer, increment pointer and counter
					nrx++;
//			        System.out.printf("nrx=%d\n", nrx);
					System.arraycopy(packet.getData(), 4, rxdata, rxdataptr, packet.getLength()-4);
					rxdataptr += packet.getLength()-4;
					totalrxbytes += packet.getLength()-4;
				}
        }
        
        
		
        rx.data = rxdata;
        rx.tcid = tcid;
        rx.address = packet.getAddress();
		rx.status = UFTData.Status.DATA;
        rx.length = totalrxbytes;
		return rx;
	}

	/**
	 * Send a data junk via UFT
	 * @param udata
	 * @param s
	 * @param a
	 * @param port
	 */
	public static void send (UFTData udata, DatagramSocket s, InetAddress a, int port) {
		int nseq, len;
		DatagramPacket p;

	    byte[] buf = new byte[1500];
	    
	    udata.tcid = 12;
	    
	    // calculate nseq
	    len = udata.data.length;
	    nseq = (int) Math.ceil(len/(double)TX_PACKET_DATA_SIZE);
	    		
	    // assemble start packet
	    buf[0] = 0;
	    buf[1] = 0; buf [2] = 0; buf[3] = (byte)( udata.tcid & 0x7f);
	    int nseqt = nseq;
	    

	    buf[4] = (byte) ((nseq & 0xff000000) >> 24);
	    buf[5] = (byte) ((nseq & 0x00ff0000) >> 16);
	    buf[6] = (byte) ((nseq & 0x0000ff00) >>  8);
	    buf[7] = (byte) ((nseq & 0x000000ff) >>  0);
	    
//	    buf[4] = (byte)(nseqt / (1<<24));
//	    nseqt = nseqt - buf[4]/(1<<24);
//	    buf[5] = (byte)(nseqt / (1<<16));
//	    nseqt = nseqt - buf[5]/(1<<16);
//	    buf[6] = (byte)(nseqt / (1<<8));
//	    nseqt = nseqt - buf[6]/(1<<8);
//	    buf[7] = (byte)(nseqt);
	    System.out.printf("nseq=%d\n", nseq);
	    System.out.printf("buf[4]=%d buf[5]=%d buf[6]=%d buf[7]=%d\n", buf[4], buf[5], buf[6], buf[7]);
	    // send start packet
	    p = new DatagramPacket(buf, UFT_CONTROLL_SIZE, a, port);
        Util.sendDatagram(s, p);
        
        // Send data packets
        for(int pctr = 0; pctr < nseq; pctr++) {
//        	buf[0] = (byte) (0x80 | (byte)udata.tcid);

            buf[0] = (byte) ((byte)(udata.tcid & 0x7f) | 0x80);

            buf[1] = (byte) ((pctr & 0x00ff0000) >> 16);
            buf[2] = (byte)((pctr & 0x0000ff00) >>  8);
            buf[3] = (byte)((pctr & 0x000000ff) >>  0);
            
//    	    int pctrt = pctr;
//    	    buf[1] = (byte)(pctrt / (1<<16));
//    	    pctrt = pctrt - buf[1]/(1<<16);
//    	    buf[2] = (byte)(pctrt / (1<<8));
//    	    pctrt = pctrt - buf[2]/(1<<8);
//    	    buf[3] = (byte)(pctrt);
    	    
        	if( len-(pctr*TX_PACKET_DATA_SIZE) >  TX_PACKET_DATA_SIZE) {
        		System.arraycopy(udata.data, pctr*TX_PACKET_DATA_SIZE, buf, 4, TX_PACKET_DATA_SIZE);
        		p = new DatagramPacket(buf, TX_PACKET_DATA_SIZE+4, a, port);
        	}
        	else {
        		System.arraycopy(udata.data, pctr*TX_PACKET_DATA_SIZE, buf, 4, len-(pctr*TX_PACKET_DATA_SIZE));
        		p = new DatagramPacket(buf, len-(pctr*TX_PACKET_DATA_SIZE)+4, a, port);
        	}
        		
    	    
            Util.sendDatagram(s, p);
        }
	    
        // Send stop packet
//	    buf[0] = 1;
//	    buf[1] = 0; buf [2] = 0; buf[3] = (byte) udata.tcid;
//	    buf[4] = 0;
//	    buf[5] = 0;
//	    buf[6] = 0;
//	    buf[7] = 0;
//	    // send stop packet
//	    p = new DatagramPacket(buf, 8, a, port);
//        Util.sendDatagram(s, p);		
	}
	
	/**
	 * Set UFT user register
	 * @param reg
	 * @param regdata
	 * @param s
	 * @param a
	 * @param port
	 */
	public static void setUserReg (int reg, long regdata, DatagramSocket s, InetAddress a, int port) {

		int nseq, len;
		DatagramPacket p;

	    byte[] buf = new byte[UFT_CONTROLL_SIZE];
	    
	    // assemble start packet
	    buf[0] = 4;
	    buf[1] = 0; buf [2] = 0; buf[3] = (byte) reg;

	    buf[4] = (byte)(regdata / (1<<24));
	    regdata = regdata - buf[4]/(1<<24);
	    buf[5] = (byte)(regdata / (1<<16));
	    regdata = regdata - buf[5]/(1<<16);
	    buf[6] = (byte)(regdata / (1<<8));
	    regdata = regdata - buf[6]/(1<<8);
	    buf[7] = (byte)(regdata);
	    // send start packet
	    p = new DatagramPacket(buf, UFT_CONTROLL_SIZE, a, port);
//	    System.out.println(Arrays.toString(buf));
        Util.sendDatagram(s, p);
	}
	
	/**
	 * Dissects the packet type
	 * @param b
	 * @return
	 */
	public static pktType getPacketType (byte[] b) {
		if			(b[0] == 0) return pktType.FTS;
		else if 	(b[0] == 1) return pktType.FTP;
		else if 	(b[0] == 2) return pktType.ACKFP;
		else if 	(b[0] == 3) return pktType.ACKFT;
		else if 	(b[0] == 4) return pktType.USER;
		else return pktType.DATA;
	}
}
