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
	private static int WIN_LENGTH = 	21;
	
	// ================================================================================
	// Local Variables
	// ================================================================================
	// For communication
    private DatagramSocket socket;
    private boolean running = false;
    private byte[] buf = new byte[1500];
	private int port;
    
    // Image cache
	 private byte[] imcache = new byte[BRAM_SIZE*CACHE_N_LINES];
    private int rxLines = 0;
    private int rxLinePtr = 0;
    private int readCachePtr = 0;
    
    private WallisParameters wapar;

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
    	
    	wapar = new WallisParameters();
    	wapar.brightness = 0.5;
    	wapar.contrast = 0.8125;
    	wapar.gMean = 127;
    	wapar.gVar = 3600;
    	wapar.winLen = 21;
    }
    
    public void run() {
    	
    	UFTData udata;
    	
    	double sum_Pixel, sum_Pixel2, w_pixel, n_Mean, n_Var;
    	double outPix[] = new double[BRAM_SIZE];
    	byte outPixSend[];
    	int outIndex = 0;
    	
    	running = true;
        while (running) {
        	// Receive one line
        	udata = UFT.receive(socket);
        	if(udata.status == UFTData.Status.TIMEOUT) continue;
        	if(udata.status == UFTData.Status.USER) {
        		System.out.printf("User reg %d set to %d\n", udata.uregAddress, udata.uregContent);
        		if(udata.uregAddress == 1) wapar.imgWidth = (int) udata.uregContent;
        		continue;
        	}
        	
        	// Copy to image buffer
        	System.arraycopy(udata.data, 0, imcache, CACHE_N_LINES*rxLinePtr, udata.length);
        	
        	rxLinePtr++;
        	rxLines++;
        	if(rxLinePtr == CACHE_N_LINES) rxLinePtr = 0;
        	
        	System.out.printf("Line received. rxLines=%d\n", rxLines);
        	
        	// If enough data is here
        	if(rxLines >= 21) {

              // Send data back
              outPixSend = new byte[udata.length];
              for(int i = 0; i < udata.length-21+1; i++) {
            	  outPixSend[i] = (byte)imcache[CACHE_N_LINES*(rxLinePtr-1)+i];
              }
              udata.data = outPixSend;
              udata.length = udata.length-21+1;
              udata.tcid = 0;
              UFT.send(udata, socket, udata.address, 2222);
              
        		
        		
//        		System.out.println("Processing Wallis");
//        		sum_Pixel = 0;
//        		sum_Pixel2 = 0;
//        		outIndex = 0;
//        		// Process
//        		// ********************************************************************
//                // Initialization WIN
//                for(int x_win = 0; x_win < WIN_LENGTH; x_win++) {
//                    for(int y_win = 0; y_win < WIN_LENGTH; y_win++) {
////                    	pixelAt(x_win, y_win);
////                        System.out.printf("%02x\n",pixelAt(x_win, y_win));
//                        sum_Pixel += pixelAt(x_win, y_win);
//                        sum_Pixel2 += pixelAt(x_win, y_win)*pixelAt(x_win, y_win);
//                    }
//                }
//                
//                // center pixel
//                w_pixel = pixelAt( (WIN_LENGTH-1)/2, (readCachePtr + (WIN_LENGTH-1)/2) % CACHE_N_LINES );
//
//                n_Mean = Cal_Mean(sum_Pixel);
//                n_Var = Cal_Variance((n_Mean * n_Mean), sum_Pixel2);
//                outPix[outIndex++] = Wallis(w_pixel, n_Mean, n_Var);
//                
//
//
//                // ********************************************************************
//                // Calculate the whole width of the image
//                for(int x = 0; x < (wapar.imgWidth - 1); x++) {
//
//                    // Substract old data, add new data
//                    for(int y_win = 0; y_win < WIN_LENGTH; y_win++) {                    	
//                        sum_Pixel -= pixelAt(x, y_win);
//                        sum_Pixel2 -= pixelAt(x, y_win) * pixelAt(x, y_win);
//                        
//                        sum_Pixel += pixelAt(x + WIN_LENGTH, y_win);
//                        sum_Pixel2 += Math.pow(pixelAt(x + WIN_LENGTH, y_win), 2);
////                        System.out.printf("%02x\n", pixelAt(x + WIN_LENGTH, y_win));
//                    }
//
//                    
//                    w_pixel = pixelAt(x + (WIN_LENGTH-1)/2, (readCachePtr + (WIN_LENGTH-1)/2) % CACHE_N_LINES );
//
//                    n_Mean = Cal_Mean(sum_Pixel);
//                    n_Var = Cal_Variance((n_Mean * n_Mean), sum_Pixel2);
//                    outPix[outIndex++] = Wallis(w_pixel, n_Mean, n_Var);
//                }
//                // Send data back
//                outPixSend = new byte[outIndex];
//                for(int i = 0; i < outIndex; i++) {
//                	outPixSend[i] = (byte)outPix[i];
//                }
//                udata.data = outPixSend;
//                udata.length = outIndex;
//                udata.tcid = 0;
//                UFT.send(udata, socket, udata.address, 2222);
//                
//                // Increment pointer
//                readCachePtr++;
//                readCachePtr%=CACHE_N_LINES;
//        		System.out.println("Processing Wallis Done");
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

    public boolean isRunning() {
    	return running;
    }
	// ================================================================================
	// private methods
	// ================================================================================
    /**
     * Returns pixel from image cache
     * @param x loc of pixel
     * @param y loc of pixel
     * @return
     */
    private byte pixelAt(int x, int y) {
    	return imcache[((readCachePtr+y)%CACHE_N_LINES)*BRAM_SIZE + x];
    }
    /*
     * Calculate the mean
     */
    double Cal_Mean(double sum_Pixel) {
    	double mean;

        mean = sum_Pixel / (WIN_LENGTH*WIN_LENGTH);

        return mean;
    }

    /*
     * Calculate the variance
     */
    double Cal_Variance(double mean2, double sum_pixel2) {
    	double var;
        
        var = (sum_pixel2 / (WIN_LENGTH*WIN_LENGTH)) - mean2;

        return var;
    }

    /*
     * Calculate the Wallis Pixel
     */
    double Wallis(double v_pixel, double n_mean, double n_var) {
    	double w_Pixel;

        double dgb = ((v_pixel - n_mean) * wapar.contrast * wapar.gVar) / (wapar.contrast * n_var + (1 - wapar.contrast) * wapar.gVar);
        w_Pixel = dgb + wapar.brightness * wapar.gMean + (1 - wapar.brightness) * n_mean;

        if(w_Pixel > 255) w_Pixel = 255;
        if(w_Pixel < 0) w_Pixel = 0;

        return w_Pixel;
    }
}
