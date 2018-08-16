package diip_java_cc.Controller;


import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;

import diip_java_cc.Model.Model;
import diip_java_cc.Model.WallisParameters;
import diip_java_cc.View.MainView;

public class Controller {
	
	Model model;
	MainView view;
	
	public Controller(Model model, MainView view) {
		this.model = model;
		this.view = view;
	}

	public void contol() {
		

//		model.loadSourceImage("res/mountain.png");
	}

	public void goRequest(WallisParameters wapar) {
		model.goRequest(wapar);
	}
	
	public void loadFile(File file) {
		// Read the file
		this.model.newInputFile(file);
}

	public void localWorkerChanged(int i, boolean selected) {
		model.localWorkerSetEnabled(i,selected);
	}

	public void fpgaChanged(int i, boolean selected, String ipport) {
		model.fpgaChanged(i,selected,ipport);
	}
	
	public MainView getMainView() {
		return this.view;
}
	
}
