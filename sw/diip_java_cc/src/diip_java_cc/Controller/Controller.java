package diip_java_cc.Controller;


import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;

import diip_java_cc.Model.Model;
import diip_java_cc.View.MainView;

public class Controller {
	
	Model model;
	MainView view;
	
	public Controller(Model model, MainView view) {
		this.model = model;
		this.view = view;
	}

	public void contol() {
		

		model.loadSourceImage("res/mountain.png");
	}

	public void goRequest() {
		model.goRequest();
	}

	public void localWorkerChanged(int i, boolean selected) {
		model.localWorkerSetEnabled(i,selected);
	}

	public void fpgaChanged(int i, boolean selected, String ipport) {
		// TODO Auto-generated method stub
		
	}
	
}
