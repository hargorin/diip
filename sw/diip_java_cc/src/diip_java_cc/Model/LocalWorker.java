/**
 * Starts as a thread and acts as an FPGA processing Images 
 */

package diip_java_cc.Model;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.util.Arrays;

public class LocalWorker extends Thread {
	

	// ================================================================================
	// Settings
	// ================================================================================
	// Same as in VHDL
	private static int BRAM_SIZE = 		16384;
	private static int CACHE_N_LINES =	22;
	private static int FIFO_DEPTH = 	16384; 
	
	// ================================================================================
	// Local Variables
	// ================================================================================
	// For communication
    private DatagramSocket socket;
    private boolean running;
    private byte[] buf = new byte[1500];
	private int port;
    
    // Image cache
	 private byte[] imcache = new byte[BRAM_SIZE*CACHE_N_LINES];
    private int rxLines = 0;
    private int rxLinePtr = 0;

	// ================================================================================
	// Public methods
	// ================================================================================
    /**
     * Creates a new local worker
     */
    public LocalWorker() {
    	this.port = 5000;
    	boolean portFound = false;
    	while(!portFound) {
	    	try {
				socket = new DatagramSocket(this.port);
				portFound = true;
			} catch (SocketException e) {
				this.port = this.port + 1;
			}
    	}
    	System.out.printf("new localworker on port %d\n", this.port);
    }
    
    public void run() {
    	UFTData udata;
    	
    	running = true;
        while (running) {
        	// Receive one line
        	udata = UFT.receive(socket);
        	if(udata.status == UFTData.Status.TIMEOUT) continue;
        	if(udata.status == UFTData.Status.USER) {
        		System.out.printf("User reg %d set to %d\n", udata.uregAddress, udata.uregContent);
        		continue;
        	}
        	
        	// Copy to image buffer
        	System.arraycopy(udata.data, 0, imcache, CACHE_N_LINES*rxLinePtr, udata.length);
        	
        	rxLinePtr++;
        	if(rxLinePtr == CACHE_N_LINES) rxLinePtr = 0;
        	
        	System.out.printf("Line received. rxLinePtr=%d\n", rxLinePtr);
        	
        	// If enough data is here
        	if(rxLines > 21) {
        		// Process
        	}
        	
        	
        	
//            DatagramPacket packet = new DatagramPacket(buf, buf.length);
//            
//            // timeout in ms
//            try {
//				socket.setSoTimeout(10);
//			} catch (SocketException e1) {
//				// TODO Auto-generated catch block
//				e1.printStackTrace();
//			}
//            
//            try {
//				socket.receive(packet);
//			} catch (SocketTimeoutException e1) {
//				// no data recevied, continue
//				continue;
//			} catch (IOException e) {
//				// TODO Auto-generated catch block
//				e.printStackTrace();
//			}
//             
//            InetAddress address = packet.getAddress();
//            int port = packet.getPort();
//            packet = new DatagramPacket(buf, buf.length, address, port);
//            String received = new String(packet.getData(), 0, packet.getLength());
//             
//            if (received.equals("end")) {
//                running = false;
//                continue;
//            }
//            try {
//            	System.out.printf("received %d bytes from %s\n", packet.getLength(), packet.getAddress().toString());
//            	System.out.println(Arrays.toString(packet.getData()));
//				socket.send(packet);
//			} catch (IOException e) {
//				// TODO Auto-generated catch block
//				e.printStackTrace();
//			}
        }
        System.out.printf("lw on port %d closing\n", this.port);
        socket.close();
    }
    
    /**
     * Terminate the worker thread
     */
    public void terminate() { 
    	this.running = false;
    }
    
    /**
     * Get the UDP port the worker is running on
     * @return UDP port
     */
    public int getPort() {
    	return this.port;
    }
}
