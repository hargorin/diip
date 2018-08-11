package diip_java_cc.Model;

import java.net.InetAddress;

public class UFTData {


	public enum Status {
		VALID, TIMEOUT,
	};
	
	// ================================================================================
	// Local Variables
	// ================================================================================
	public int tcid;
	public byte[] data;
	public int length;
	public InetAddress address;
	public Status status;
}
