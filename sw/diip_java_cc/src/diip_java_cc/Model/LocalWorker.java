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
	private int txport;
    
    // Image cache
	private byte[][] imcache = new byte[CACHE_N_LINES][BRAM_SIZE];
    private int rxLines = 0;
    private int rxLinePtr = 0;
    private int readLinePtr = 0;
    private int readCachePtr = 0;
    
    private WallisParameters wapar;
    
    private double wa_par_c_gvar;
    private double wa_par_c;
    private double wa_par_ci_gvar;
    private double wa_par_b_gmean;
    private double wa_par_bi;

	// ================================================================================
	// Public methods
	// ================================================================================
    /**
     * Creates a new local worker
     * @param txport 
     */
    public LocalWorker(int txport) {
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
    	this.txport = txport;
    	
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
    	int outW = 21;
    	int readPtr = 0;
    	
    	
    	rxLines = 0;
    	readCachePtr = 0;
    	
    	InetAddress replyAdr;
    	
    	
    	running = true;
        while (running) {
        	// Receive one line
        	udata = UFT.receive(socket);
        	if(udata.status == UFTData.Status.TIMEOUT) continue;
        	if(udata.status == UFTData.Status.USER) {
        		System.out.printf("User reg %d set to %d\n", udata.uregAddress, udata.uregContent);
        		if(udata.uregAddress == 2) {
        			wapar.imgWidth = (int) udata.uregContent;
        			outW = wapar.imgWidth - wapar.winLen + 1;
        		}
        		else if(udata.uregAddress == 3) {
        			wa_par_c_gvar = udata.uregContent/64;
        		}
        		else if(udata.uregAddress == 4) {
        			wa_par_c = udata.uregContent/64;
        		}
        		else if(udata.uregAddress == 5) {
        			wa_par_ci_gvar = udata.uregContent/64;
        		}
        		else if(udata.uregAddress == 6) {
        			wa_par_b_gmean = udata.uregContent/64;
        		}
        		else if(udata.uregAddress == 7) {
        			wa_par_bi = udata.uregContent/64;
        		}
        		continue;
        	}
        	
        	// store reply address
        	replyAdr = udata.address;
        	
        	// Copy to image buffer
        	for (int i = 0; i < udata.data.length; i++) {
        		imcache[rxLinePtr][i] = udata.data[i];
			}
//        	System.arraycopy(udata.data, 0, imcache, CACHE_N_LINES*rxLinePtr, udata.length);
        	
        	// increment and wrap input pointer
        	rxLinePtr++;
        	if(rxLinePtr == CACHE_N_LINES) rxLinePtr = 0;
        	rxLines++;
        	
//        	System.out.printf("Line received. rxLines=%d rxLinePtr=%d readLinePtr=%d\n", rxLines, rxLinePtr,readLinePtr);
        	
        	// If enough data is here
        	if(rxLines >= 21) {

        		// TEST: Send data back
//        		outPixSend = new byte[outW];
//        		for(int i = 0; i < outW; i++) {
////        			outPixSend[i] = imcache[readLinePtr][i];
//        			outPixSend[i] = (byte) pixelAt(i, readPtr);
//        		}
//        		System.out.printf("reply to port %d len %d\n", 2222, outW);
//        		udata = new UFTData();
//        		udata.data = outPixSend;
//        		udata.length = outW;
//        		udata.tcid = 0;
//        		UFT.send(udata, socket, replyAdr, 2222);
//
//        		// inc and wrap read line ptr
//        		readPtr++;
//        		readLinePtr++;
//        		if(readLinePtr == CACHE_N_LINES) readLinePtr = 0;
              
        		
//        		System.out.println("Processing Wallis");
        		sum_Pixel = 0;
        		sum_Pixel2 = 0;
        		outIndex = 0;
        		// Process
        		// ********************************************************************
                // Initialization WIN
                for(int x_win = 0; x_win < WIN_LENGTH; x_win++) {
                    for(int y_win = 0; y_win < WIN_LENGTH; y_win++) {
                        sum_Pixel += pixelAt(x_win, y_win + readCachePtr);
                        sum_Pixel2 += pixelAt(x_win, y_win + readCachePtr)*pixelAt(x_win, y_win + readCachePtr);
                    }
                }
                
                // center pixel
                w_pixel = pixelAt( (WIN_LENGTH-1)/2, (readCachePtr + (WIN_LENGTH-1)/2));

                n_Mean = Cal_Mean(sum_Pixel);
                n_Var = Cal_Variance((n_Mean * n_Mean), sum_Pixel2);
                outPix[outIndex++] = Wallis(w_pixel, n_Mean, n_Var);
                


                // ********************************************************************
                // Calculate the whole width of the image
                for(int x = 0; x < outW-1; x++) {

                    // Substract old data, add new data
                    for(int y_win = 0; y_win < WIN_LENGTH; y_win++) {                    	
                        sum_Pixel -= pixelAt(x, y_win + readCachePtr);
                        sum_Pixel2 -= pixelAt(x, y_win + readCachePtr) * pixelAt(x, y_win + readCachePtr);
                        
                        sum_Pixel += pixelAt(x + WIN_LENGTH, y_win + readCachePtr);
                        sum_Pixel2 += pixelAt(x + WIN_LENGTH, y_win + readCachePtr)*pixelAt(x + WIN_LENGTH, y_win + readCachePtr);
                    }

                    
                    w_pixel = pixelAt(x + (WIN_LENGTH-1)/2 + 1, (readCachePtr + (WIN_LENGTH-1)/2) );

                    n_Mean = Cal_Mean(sum_Pixel);
                    n_Var = Cal_Variance((n_Mean * n_Mean), sum_Pixel2);
                    outPix[outIndex++] = Wallis(w_pixel, n_Mean, n_Var);
                }
                // Send data back
                outPixSend = new byte[outIndex];
                for(int i = 0; i < outIndex; i++) {
                	if(outPix[i] < 0)outPixSend[i] = (byte)0;
                	else if (outPix[i] > 255)outPixSend[i] = (byte) (255); 
                	else outPixSend[i] = (byte)outPix[i];
                }
                udata.data = outPixSend;
                udata.length = outIndex;
                udata.tcid = 0;
                UFT.send(udata, socket, replyAdr, txport);
                
                // Increment pointer
                readCachePtr++;
//        		System.out.println("Processing Wallis Done");
        	
        	
        	
        	// UDP socket TEST
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

        	}
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
    private int pixelAt(int x, int y) {
    	return imcache[y%CACHE_N_LINES][x] & 0xFF;
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

        double dgb = ((v_pixel - n_mean) * wa_par_c_gvar) / (wa_par_c * n_var + wa_par_ci_gvar);
        w_Pixel = dgb + wa_par_b_gmean + wa_par_bi * n_mean;

        if(w_Pixel > 255) w_Pixel = 255;
        if(w_Pixel < 0) w_Pixel = 0;

        return w_Pixel;
    }
}
