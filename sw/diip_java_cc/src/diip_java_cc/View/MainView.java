package diip_java_cc.View;

import java.awt.BorderLayout;
import java.util.Observable;
import java.util.Observer;

import javax.swing.BoxLayout;
import javax.swing.JFrame;

import diip_java_cc.Controller.Controller;
import javax.swing.JPanel;
import java.awt.Component;
import java.awt.Image;
import java.awt.image.BufferedImage;

import javax.swing.Box;

public class MainView extends JFrame implements Observer {
	public MainView() {
//		getContentPane().setLayout(new BorderLayout(0, 0));
//		
//		JPanel panel = new JPanel();
//		getContentPane().add(panel, BorderLayout.CENTER);
//
//		MainPanel mp = new MainPanel();
//		panel.add(mp);
//		
//		Component horizontalGlue = Box.createHorizontalGlue();
//		mp.add(horizontalGlue, BorderLayout.EAST);
	}

	// ================================================================================
	// Local Variables
	// ================================================================================

	private Controller controller;
	
	private MainPanel mp;

	// ================================================================================
	// Public Functions
	// ================================================================================
	@Override
	public void update(Observable o, Object arg) {
		mp.update(o,arg);
	}

	public void setController(Controller controller) {
		this.controller = controller;
	}

	public void build() {
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 700, 600);

		// Window properties
		setTitle("diip Control Center");
		
		mp = new MainPanel(controller);
		getContentPane().setLayout(new BorderLayout(0, 0));
		getContentPane().add(mp);

//		pack();
		setMinimumSize(getPreferredSize());
		
	}
}
