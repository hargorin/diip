package diip_java_cc.Model;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.awt.image.ColorConvertOp;
import java.awt.image.Raster;
import java.awt.image.WritableRaster;
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
		int[][] outData = new int[outW][outH];
		
		// array test
//		int[][] test = imageToArray(i);
//		BufferedImage testout = arrayToImage(test, i.getWidth(), i.getHeight());
		
		// split test
//		List<int[][]> si = splitImage(i, 3);
//		return arrayToImage(si.get(1), i.getWidth()/3+(waPar.winLen-1), i.getHeight());
		
		
//		// Split image accordingly
		List<int[][]> si = splitImage(i, workers.size());
		// Configure worker and start
		int wnr = 0;
		for (Worker w : workers) {
			w.ih = i.getHeight();
			w.iw = si.get(wnr).length;
//			System.out.printf("w.ih=%d\n",w.ih);
//			System.out.printf("w.iw=%d\n",w.iw);
//			System.out.printf("len=%d\n",si.get(wnr).length);
			w.imData = si.get(wnr);
			w.wapar = waPar;
			w.start();
			wnr++;
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
			for(int y = 0; y < (w.ih-waPar.winLen+1); y++) {
				for(int x=0; x < (w.iw-waPar.winLen+1); x++) {
					outData[(x+xoff)][y] = w.outPix[x][y];
				}
			}
			xoff += w.iw-waPar.winLen+1;
		}
		
		BufferedImage outi = arrayToImage(outData, outW, outH);
		return outi;
//		return testout;
		
	}

	/**
	 * Splits input image to size overlapping chunks
	 */
	private List<int[][]> splitImage(BufferedImage i, int n) {
		int iw = i.getWidth();
		int ih = i.getHeight();

		int startendwidth = iw/n+(waPar.winLen-1)/2;
		int midwidth = iw/n+(waPar.winLen-1);
		
		int[][] imData = imageToArray(i);
		
		List<int[][]> si = new ArrayList<int[][]>();
		
		// If one then just put inside list
		if(n == 1) {
			si.add(imData);
			return si;
		}

		// if two 
		if(n == 2) {
			int[][] i1 = new int[startendwidth][ih];
			int[][] i2 = new int[startendwidth][ih];

			// i1
			int xoff = 0;
			for(int y = 0; y < ih; y++) {
				for(int x=0; x<startendwidth; x++) {
					i1[x][y] = imData[x+xoff][y];
				}
			}
			// i2
			xoff = iw/2-(waPar.winLen-1)/2;
			for(int y = 0; y < ih; y++) {
				for(int x=0; x<startendwidth; x++) {
					i2[x][y] = imData[x+xoff][y];
				}
			}

			si.add(i1);
			si.add(i2);
			return si;
		}
		
		// else
		int nctr = 0;

		int[][] it = new int[startendwidth][ih];

		// first
		int xoff = 0;
		for(int y = 0; y < ih; y++) {
			for(int x=0; x<startendwidth; x++) {
				it[x][y] = imData[x+xoff][y];
			}
		}
		si.add(it);
		nctr++;
		xoff += iw/n-(waPar.winLen-1)/2;

		// mid pieces
		for(int mid = 0; mid < (n-2); mid++) {
			it = new int[midwidth][ih];

			for(int y = 0; y < ih; y++) {
				for(int x=0; x<midwidth; x++) {
					it[x][y] = imData[x+xoff][y];
				}
			}
			si.add(it);
			nctr++;
			xoff += iw/n;
		}
		
		// end piece
		it = new int[startendwidth][ih];
		for(int y = 0; y < ih; y++) {
			for(int x=0; x<startendwidth; x++) {
				it[x][y] = imData[x+xoff][y];
			}
		}
		
		si.add(it);
		
		
		return si;
	}

	/**
	 * Converts an image to grayscale 0-255 values
	 * @param img
	 * @return
	 */
	private int[][] imageToArray(BufferedImage img) {
		int width = img.getWidth();
	    int height = img.getHeight();
	    int[][] ret = new int[width][height];
		Raster raster = img.getData();
		
		for (int x = 0; x < width; x++) {
	        for (int y = 0; y < height; y++) {
	        	ret[x][y] = raster.getSample(x, y, 0);
	        }
	    }
		
		return ret;
	}
	
	private BufferedImage arrayToImage (int[][] imData, int iw, int ih) {
		BufferedImage i = new BufferedImage(iw, ih, java.awt.image.BufferedImage.TYPE_INT_RGB);
		//WritableRaster raster=i.getRaster();
		
		Color c;

		for(int y = 0; y < ih; y++) {
			for(int x=0; x < iw; x++) {
				//raster.setSample(x, y, 0, imData[x][y]);
				i.setRGB(x, y, imData[x][y] | (imData[x][y]<<8) | (imData[x][y]<<16));
			}
		}
		
		return i;
	}
}
