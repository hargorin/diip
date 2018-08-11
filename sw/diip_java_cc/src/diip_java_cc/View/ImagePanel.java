package diip_java_cc.View;

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.Toolkit;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;
import javax.swing.JPanel;

public class ImagePanel extends JPanel{

    private BufferedImage image;

    public ImagePanel() {
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
        super.paintComponent(g);
        
        double scale;
        
        
        try {
            if((double)super.getWidth()/image.getWidth() < (double)super.getHeight()/image.getHeight() )
            	scale = (double)super.getWidth()/image.getWidth();
            else
            	scale = (double)super.getHeight()/image.getHeight();

            System.out.printf("scale=%f\n",scale);
//            Image scaledImage = image.getScaledInstance(super.getWidth(), super.getHeight(),
//                    Image.SCALE_SMOOTH);
//            Image scaledImage = image.getScaledInstance(this.getWidth(),this.getHeight(),Image.SCALE_SMOOTH);
            g.drawImage(resize(image,scale,scale), 0, 0, this); // see javadoc for more info on the parameters			
		} catch (Exception e) {
			// TODO: handle exception
		}            
    }

}