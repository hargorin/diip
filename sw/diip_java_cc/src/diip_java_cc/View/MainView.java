package diip_java_cc.View;

import java.util.Observable;
import java.util.Observer;

import javax.swing.JFrame;

import diip_java_cc.Controller.Controller;

public class MainView extends JFrame implements Observer {

	// ================================================================================
	// Local Variables
	// ================================================================================

	private Controller controller;

	// ================================================================================
	// Public Functions
	// ================================================================================
	@Override
	public void update(Observable o, Object arg) {
		// TODO Auto-generated method stub
		
	}

	public void setController(Controller controller) {
		this.controller = controller;
	}

	public void build() {
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 553, 402);

		// Window properties
		setTitle("diip Control Center");
		

		pack();
		setMinimumSize(getPreferredSize());
		
	}

}
