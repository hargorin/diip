package diip_java_cc.View;

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.Toolkit;
import java.awt.event.ComponentEvent;
import java.awt.event.ComponentListener;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;
import javax.swing.JPanel;

public class ImagePanel extends JPanel implements ComponentListener {

    private BufferedImage image;
    private Image scaledimage;
    private boolean componentChanged = true;

    public ImagePanel() {
    	addComponentListener(this);
    }

    public void setImage (BufferedImage image) {
        this.image = image;
    }
    /**
     * Resizes an Image by stretching it to a new size by x factor and y factor.
     *
     * @param picture the initial image.
     * @param xFactor the width stretching factor.
     * @param yFactor the height stretching factor.
     * @return the stretched image.
     */
    public static Image resize(Image picture, double xFactor, double yFactor)
    {
       BufferedImage buffer;
       Graphics2D g;
       AffineTransform transformer;
       AffineTransformOp operation;

       buffer = new BufferedImage
       (
          picture.getWidth(null),
          picture.getHeight(null),
          BufferedImage.TYPE_INT_ARGB
       );
       g = buffer.createGraphics();
       g.drawImage(picture, 0, 0, null);
       transformer = new AffineTransform();
       transformer.scale(xFactor, yFactor);
       operation = new AffineTransformOp(transformer, AffineTransformOp.TYPE_BILINEAR);
       buffer = operation.filter(buffer, null);
       return(Toolkit.getDefaultToolkit().createImage(buffer.getSource()));
    }
    
    @Override
    protected void paintComponent(Graphics g) {
        
        double scale;

//		System.out.println("paintComponent");
        if (componentChanged == true) {
            super.paintComponent(g);
	        try {
	            if((double)super.getWidth()/image.getWidth() < (double)super.getHeight()/image.getHeight() )
	            	scale = (double)super.getWidth()/image.getWidth();
	            else
	            	scale = (double)super.getHeight()/image.getHeight();
	
	            scaledimage = resize(image,scale,scale);
//	            System.out.printf("scale=%f\n",scale);
	            
	            int newImageWidth = (int) (image.getWidth() * scale);
	            int newImageHeight = (int) (image.getHeight() * scale);
	            BufferedImage resizedImage = new BufferedImage(newImageWidth , newImageHeight, image.getType());
	            Graphics2D g2 = resizedImage.createGraphics();
	            g2.drawImage(image, 0, 0, newImageWidth , newImageHeight , null);
	            g2.dispose();
	            g.drawImage(resizedImage, 0, 0, this); // see javadoc for more info on the parameters
	            
//	            g.drawImage(image, 0, 0, this); // see javadoc for more info on the parameters
	            componentChanged = false;
			} catch (Exception e) {
				// TODO: handle exception
			}     
        }
    }
    @Override
	public void componentResized(ComponentEvent e) {
		componentChanged = true;
	}

	@Override
	public void componentMoved(ComponentEvent e) {
		// TODO Auto-generated method stub
		componentChanged = true;
		
	}

	@Override
	public void componentShown(ComponentEvent e) {
		// TODO Auto-generated method stub
		componentChanged = true;
		
	}

	@Override
	public void componentHidden(ComponentEvent e) {
		// TODO Auto-generated method stub
		componentChanged = true;
		
	}

}