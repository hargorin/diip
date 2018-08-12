package diip_java_cc.Model;

import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.concurrent.TimeUnit;

public class Worker extends Thread {
	public Worker(String string, int port2) {
		ip = string;
		port = port2;
	}
	public String ip;
	public int port;
	
	public int[] imData;
	public int iw;
	public int ih;
	public WallisParameters wapar;
	public byte[] outPix;
	

    public void run() {
    	DatagramSocket socket = null;
    	DatagramSocket rxsocket = null;
    	InetAddress address = null;
    	UFTData udata = new UFTData();
    	UFTData udatarx;
    	byte[] rx = new byte[(iw-wapar.winLen+1)*(ih-wapar.winLen+1)];
		
		// Create new socket
		try {
			socket = new DatagramSocket();
		} catch (SocketException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		try {
			rxsocket = new DatagramSocket(2222);
		} catch (SocketException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		// Set destination
		try {
			address = InetAddress.getByName(ip);
		} catch (UnknownHostException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
    	// Send user registers
    	UFT.setUserReg(1, iw, socket, address, port);
    	// TODO fill rest
    	
    	// Send data
    	int y = 0;
    	int ctr = 0;
    	int rxctr = 0;
    	for(y = 0; y < wapar.winLen-1; y++) {
    		udata = new UFTData();
    		udata.data = new byte[iw];
    		udata.tcid = y;
    		// copy to tx buffer
    		for(int i = 0; i < iw; i++) {
    			udata.data[i] = (byte) imData[ctr++];
    		}
    		UFT.send(udata, socket, address, port);
    	}
    	// from now on receive and send simultaneously
    	for(; y < ih; y++) {
    		udata = new UFTData();
    		udata.data = new byte[iw];
    		udata.tcid = 0;
    		// copy to tx buffer
    		for(int i = 0; i < iw; i++) {
    			udata.data[i] = (byte) imData[ctr++];
    		}
    		UFT.send(udata, socket, address, port);
    		do {
    			udatarx = UFT.receive(rxsocket);
    		} while(udatarx.status != UFTData.Status.DATA);
    		System.out.println("Result received!");
    		System.out.printf("rx len=%d iw=%d\n",udatarx.data.length, iw);
    		// copy rx to buffer
    		for(int k = 0; k < (iw-wapar.winLen+1); k++) {
    			rx[rxctr++] = udatarx.data[k];
    		}
    	}
    	socket.close();
    	outPix = rx;
    }
}
