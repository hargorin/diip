package diip_java_cc.Model;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.SocketException;

public class Util {
	
	/**
	 * Try catch helper to set UDP socket timeout	
	 * @param s
	 * @param timeout
	 */
	public static void setDatagramSoTimeout(DatagramSocket s, int timeout) {
		try {
			s.setSoTimeout(timeout);
		} catch (SocketException e1) {
			e1.printStackTrace();
		}
	}
	
	/**
	 * Try catch wrapper for UDP socket send
	 * @param s
	 * @param p
	 */
	public static void sendDatagram(DatagramSocket s, DatagramPacket p) {
		try {
			s.send(p);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
