package diip_java_cc.Model;

import java.net.InetAddress;

public class UFTData {


	public enum Status {
		DATA, TIMEOUT, USER,
	};
	
	// ================================================================================
	// Local Variables
	// ================================================================================
	public int tcid;
	public byte[] data;
	public int length;
	public InetAddress address;
	public Status status;
	
	// User register
	public int uregAddress;
	public long uregContent; 
}
