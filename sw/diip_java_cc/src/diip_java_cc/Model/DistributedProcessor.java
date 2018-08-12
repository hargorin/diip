package diip_java_cc.Model;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.awt.image.ColorConvertOp;
import java.util.ArrayList;
import java.util.List;

public class DistributedProcessor extends Thread {

	// ================================================================================
	// Local Variables
	// ================================================================================
	private List<Worker> workers;
	private Model model;
	private WallisParameters waPar;

	private List<BufferedImage> images;
	private List<BufferedImage> outImages;
	
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
	public void setImagess(List<BufferedImage> images) {
		this.images = images;
	}
	public void setWaPar(WallisParameters wapar) {
		this.waPar = wapar;
	}
	
	public boolean isRunning() {
		return isRunning;
	}
	public List<BufferedImage> getOutImages() {
		return outImages;
	}

    public void run() {
    	isRunning = true;
    	System.out.println("DP started");
    	System.out.printf("Available Workers = %d\n", workers.size());
    	
    	for (Worker worker : workers) {
    		System.out.printf("  IP:%s port:%d\n", worker.ip, worker.port);
		}
    	
    	if(workers.size() < 1) {
    		System.out.println("DP ERROR: Too few workers");
    		done();
    		return;
    	}

    	System.out.printf("Images to process = %d\n", images.size());
    	if(images.size() < 1) {
    		System.out.println("DP ERROR: No images to process");
    		done();
    		return;
    	}
    	
    	/**
    	 * Real stuff starts here
    	 */
    	outImages = new ArrayList<BufferedImage>();
    	for (BufferedImage i : images) {
    		
    		
    		
    		outImages.add(processImage(i));
		}
    	
    	done();
    }

	// ================================================================================
	// Private methods
	// ================================================================================
    private void done() {
    	System.out.println("DP done");
    	isRunning = false;
    	model.notifyDpDone();
    }


	private BufferedImage processImage(BufferedImage i) {
		int outW = (i.getWidth()-waPar.winLen+1);
		int outH = (i.getHeight()-waPar.winLen+1);
		int[] outData = new int[outW*outH];
		
		// Split image accordingly
		List<int[]> si = splitImage(i, workers.size());
		// Configure worker and start
		int wnr = 0;
		for (Worker w : workers) {
			w.ih = i.getHeight();
			w.iw = si.get(wnr).length/w.ih;
			w.imData = si.get(wnr);
			w.wapar = waPar;
			w.start();
		}
		// Wait for all to complete
		for (Worker w : workers) {
			try {
				w.join();
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		// copy data back
		int xoff = 0;
		for (Worker w : workers) {
			for(int y = 0; y < outH; y++) {
				for(int x=0; x<outW; x++) {
					outData[(x+xoff) + y*outW] = w.outPix[(x) + y*outW] & 0xFF;
				}
			}
		}
		
		return arrayToImage(outData, outW);
		
	}

	/**
	 * Splits input image to size overlapping chunks
	 */
	private List<int[]> splitImage(BufferedImage i, int n) {
		int iw = i.getWidth();
		int ih = i.getHeight();

		int startendwidth = iw/n+waPar.winLen/2;
		int midwidth = iw/n+(waPar.winLen-1);
		
		int[] imData = imageToArray(i);
		
		List<int[]> si = new ArrayList<int[]>();
		
		// If one then just put inside list
		if(n == 1) {
			si.add(imData);
			return si;
		}

		// if two 
		if(n ==2) {
			int[] i1 = new int[startendwidth*ih];
			int[] i2 = new int[startendwidth*ih];

			// i1
			int xoff = 0;
			int ctr = 0;
			for(int y = 0; y < ih; y++) {
				for(int x=0; x<startendwidth; x++) {
					i1[ctr++] = imData[(xoff+x)+y*iw];
				}
			}
			// i2
			xoff = iw/2-waPar.winLen/2;
			ctr = 0;
			for(int y = 0; y < ih; y++) {
				for(int x=0; x<startendwidth; x++) {
					i2[ctr++] = imData[(xoff+x)+y*iw];
				}
			}

			si.add(i1);
			si.add(i2);
			return si;
		}
		
		// else
		int[] itmp = new int[startendwidth*ih];
		int xoff = 0;
		int ctr = 0;
		int nctr = 0;
		for(int y = 0; y < ih; y++) {
			for(int x=0; x<startendwidth; x++) {
				itmp[ctr++] = imData[(xoff+x)+y*iw];
			}
		}
		si.add(itmp);
		nctr++;
		
		// mid pieces
		for(int mid = 0; mid < n-2; mid++) {
			itmp = new int[midwidth*ih];
			xoff = nctr*iw/n-waPar.winLen/2;
			ctr = 0;
			for(int y = 0; y < ih; y++) {
				for(int x=0; x<midwidth; x++) {
					itmp[ctr++] = imData[(xoff+x)+y*iw];
				}
			}
			si.add(itmp);
			nctr++;
		}
		
		// end piece
		itmp = new int[startendwidth*ih];
		xoff = nctr*iw/n-waPar.winLen/2;
		ctr = 0;
		for(int y = 0; y < ih; y++) {
			for(int x=0; x<startendwidth; x++) {
				itmp[ctr++] = imData[(xoff+x)+y*iw];
			}
		}
		si.add(itmp);
		
		
		return si;
	}

	/**
	 * Converts an image to grayscale 0-255 values
	 * @param i
	 * @return
	 */
	private int[] imageToArray(BufferedImage i) {
		int[] ret = new int[i.getWidth()*i.getHeight()];
		Color c;
		
		int ctr = 0;
		for(int y = 0; y < i.getHeight(); y++) {
			for(int x=0; x<i.getWidth(); x++) {
				c = new Color(i.getRGB(x, y));
				ret[ctr++] = (c.getRed() + c.getGreen() + c.getBlue())/3;
			}
		}
		
		return ret;
	}
	
	private BufferedImage arrayToImage (int[] imData, int iw) {
		BufferedImage i = new BufferedImage(iw, imData.length/iw, java.awt.image.BufferedImage.TYPE_INT_RGB);
		Color c;

		for(int y = 0; y < imData.length/iw; y++) {
			for(int x=0; x<iw; x++) {
				c = new Color(imData[y*iw+x], imData[y*iw+x], imData[y*iw+x]);
				i.setRGB(x, y, c.getRGB());
			}
		}
		
		return i;
	}
}
