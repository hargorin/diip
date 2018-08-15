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
	
	public int[][] imData;
	public int iw;
	public int ih;
	public WallisParameters wapar;
	public int[][] outPix;
	

    public void run() {

    	// Test
//    	int outw = iw-wapar.winLen+1;
//    	int outh = ih-wapar.winLen+1;
//    	byte test;
//    	
//    	outPix = new int[outw][outh];
//    	
//    	for(int y = 0; y < outh; y++) {
//        	for(int x = 0; x < outw; x++) {
//        		test = (byte)imData[x][y];
//        		outPix[x][y] = test & 0xFF;
//        	}
//    	}

    	
    	DatagramSocket socket = null;
    	DatagramSocket rxsocket = null;
    	InetAddress address = null;
    	UFTData udata = new UFTData();
    	UFTData udatarx;
    	byte[] rx = new byte[(iw-wapar.winLen+1)*(ih-wapar.winLen+1)];
    	int outw = iw-wapar.winLen+1;
    	int outh = ih-wapar.winLen+1;
    	outPix = new int[outw][outh];
    	
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
    	int outy = 0;
    	int ctr = 0;
    	int rxctr = 0;
    	for(y = 0; y < wapar.winLen-1; y++) {
    		udata = new UFTData();
    		udata.data = new byte[iw];
    		udata.tcid = y;
    		// copy to tx buffer
    		for(int i = 0; i < iw; i++) {
    			udata.data[i] = (byte) imData[i][y];
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
    			udata.data[i] = (byte) imData[i][y];
    		}
    		UFT.send(udata, socket, address, port);
    		do {
    			udatarx = UFT.receive(rxsocket);
    		} while(udatarx.status != UFTData.Status.DATA);
    		System.out.println("Result received!");
    		System.out.printf("rx len=%d iw=%d\n",udatarx.data.length, outw);
    		// copy rx to buffer
    		for(int k = 0; k < outw; k++) {
    			outPix[k][outy] = udatarx.data[k] & 0xFF;
    		}
    		outy++;
    	}
    	socket.close();
    }
}
