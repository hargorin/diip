package diip_java_cc.Model;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.Observable;

public class Model extends Observable {

	// ================================================================================
	// Public Data
	// ================================================================================
	

	// ================================================================================
	// Private Data
	// ================================================================================
	
	public Model() {
	}

	// ================================================================================
	// Private Functions
	// ================================================================================
	public void udpTest() {
		DatagramSocket socket = null;
		InetAddress address = null;
		
		LocalWorker lw = new LocalWorker();
		lw.start();
		
		// Create new socket
		try {
			socket = new DatagramSocket();
		} catch (SocketException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		// Set destination
		try {
			address = InetAddress.getByName("localhost");
		} catch (UnknownHostException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		// Message to send
		String msg = "Hello World";
		
		byte[] buf = msg.getBytes();
        DatagramPacket packet = new DatagramPacket(buf, buf.length, address, lw.getPort());
        try {
			socket.send(packet);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        packet = new DatagramPacket(buf, buf.length);
        try {
			socket.receive(packet);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        String received = new String(packet.getData(), 0, packet.getLength());
        System.out.printf("Received: %s\n", received);
		
		// Message to send
		msg = "end";
		
		buf = msg.getBytes();
        packet = new DatagramPacket(buf, buf.length, address, lw.getPort());
        try {
			socket.send(packet);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        packet = new DatagramPacket(buf, buf.length);
        try {
			socket.receive(packet);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        received = new String(packet.getData(), 0, packet.getLength());
        System.out.printf("Received: %s\n", received);
		
        lw.terminate();
	}

	// ================================================================================
	// Public Functions
	// ================================================================================
	
}
