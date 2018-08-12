package diip_java_cc.Model;

import java.util.List;

public class DistributedProcessor extends Thread {

	// ================================================================================
	// Local Variables
	// ================================================================================
	private List<Worker> workers;
	private Model model;

	private boolean isRunning = false;
	
	// ================================================================================
	// Public methods
	// ================================================================================
	public DistributedProcessor(Model model) {
		this.model = model;
		
	}
	
	public void setWorkers(List<Worker> workers) {
		this.workers = workers;
	}
	
	public boolean isRunning() {
		return isRunning;
	}

    public void run() {
    	isRunning = true;
    	System.out.println("DP started");
    	
    	

    	System.out.println("DP done");
    	isRunning = false;
    	model.notifyDpDone();
    }

	// ================================================================================
	// Private methods
	// ================================================================================

	
}
