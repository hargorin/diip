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

public class LocalWorker extends Thread {
	

    private DatagramSocket socket;
    private boolean running;
    private byte[] buf = new byte[256];
	private int port;
    
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
    	running = true;
        while (running) {
            DatagramPacket packet = new DatagramPacket(buf, buf.length);
            
            // timeout in ms
            try {
				socket.setSoTimeout(10);
			} catch (SocketException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
            
            try {
				socket.receive(packet);
			} catch (SocketTimeoutException e1) {
				// no data recevied, continue
				continue;
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
             
            InetAddress address = packet.getAddress();
            int port = packet.getPort();
            packet = new DatagramPacket(buf, buf.length, address, port);
            String received = new String(packet.getData(), 0, packet.getLength());
             
            if (received.equals("end")) {
                running = false;
                continue;
            }
            try {
				socket.send(packet);
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
        }
        System.out.printf("lw on port %d closing\n", this.port);
        socket.close();
    }
    
    public void terminate() { 
    	this.running = false;
    }
    
    public int getPort() {
    	return this.port;
    }
}
