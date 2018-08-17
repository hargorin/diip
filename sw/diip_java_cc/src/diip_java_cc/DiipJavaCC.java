package diip_java_cc;

import javax.swing.SwingUtilities;
import javax.swing.UIManager;

import diip_java_cc.Controller.Controller;
import diip_java_cc.Model.Model;
import diip_java_cc.View.MainView;

public class DiipJavaCC {
	
	static Model model = new Model();

	public static void main(String[] args) {
		System.out.printf("Hello World\n");
		

		// TEST
//		model.udpTest();
//		model.uftTest();
		
		// look and feel
		try {
			UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		} catch (Exception e) {
		}
		
		SwingUtilities.invokeLater(new Runnable() {
			@Override
			public void run() {
				Thread.currentThread().setPriority(8); // Thread.MAX_PRIORITY
				Model model = new Model();
				MainView view = new MainView();
				Controller controller = new Controller(model, view);

				view.setController(controller);

				view.build();
				view.setVisible(true);

				// Add observers
				model.addObserver(view);
				controller.contol();
			}
		});

		
		System.out.println("Exiting main()");
	}

}
