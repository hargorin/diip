package diip_java_cc.View;

import javax.swing.JPanel;
import javax.swing.JSplitPane;
import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.awt.GridBagLayout;
import javax.swing.JSpinner;
import java.awt.GridBagConstraints;
import java.awt.Insets;
import java.util.Observable;

import javax.swing.JLabel;
import javax.swing.JButton;
import java.awt.Component;
import javax.swing.Box;
import java.awt.Color;
import javax.swing.border.LineBorder;

import diip_java_cc.Model.Model;

public class MainPanel extends JPanel {
	private ImagePanel pnlLTop;
	private ImagePanel pnlLBot;
	/**
	 * Create the panel.
	 */
	public MainPanel() {
		setBorder(null);
		setBackground(Color.YELLOW);
		setLayout(new GridLayout(1, 1, 0, 0));
		
		JPanel panel = new JPanel();
		add(panel);
		GridBagLayout gbl_panel = new GridBagLayout();
		gbl_panel.columnWidths = new int[]{93, 0};
		gbl_panel.rowHeights = new int[]{0, 0};
		gbl_panel.columnWeights = new double[]{1.0, Double.MIN_VALUE};
		gbl_panel.rowWeights = new double[]{1.0, Double.MIN_VALUE};
		panel.setLayout(gbl_panel);
		
		JPanel panel_1 = new JPanel();
		panel_1.setBorder(null);
		GridBagConstraints gbc_panel_1 = new GridBagConstraints();
		gbc_panel_1.fill = GridBagConstraints.BOTH;
		gbc_panel_1.gridx = 0;
		gbc_panel_1.gridy = 0;
		panel.add(panel_1, gbc_panel_1);
		GridBagLayout gbl_panel_1 = new GridBagLayout();
		gbl_panel_1.columnWidths = new int[]{0, 0, 0};
		gbl_panel_1.rowHeights = new int[]{0, 0};
		gbl_panel_1.columnWeights = new double[]{1.0, 0.0, Double.MIN_VALUE};
		gbl_panel_1.rowWeights = new double[]{1.0, Double.MIN_VALUE};
		panel_1.setLayout(gbl_panel_1);
		
		JPanel panel_2 = new JPanel();
		GridBagConstraints gbc_panel_2 = new GridBagConstraints();
		gbc_panel_2.insets = new Insets(0, 0, 0, 5);
		gbc_panel_2.fill = GridBagConstraints.BOTH;
		gbc_panel_2.gridx = 0;
		gbc_panel_2.gridy = 0;
		panel_1.add(panel_2, gbc_panel_2);
		GridBagLayout gbl_panel_2 = new GridBagLayout();
		gbl_panel_2.columnWidths = new int[]{12, 0};
		gbl_panel_2.rowHeights = new int[]{98, 98, 0};
		gbl_panel_2.columnWeights = new double[]{1.0, Double.MIN_VALUE};
		gbl_panel_2.rowWeights = new double[]{1.0, 1.0, Double.MIN_VALUE};
		panel_2.setLayout(gbl_panel_2);
		
		pnlLTop = new ImagePanel();
		pnlLTop.setBorder(new LineBorder(new Color(0, 0, 0)));
		GridBagConstraints gbc_pnlLTop = new GridBagConstraints();
		gbc_pnlLTop.fill = GridBagConstraints.BOTH;
		gbc_pnlLTop.insets = new Insets(0, 0, 5, 0);
		gbc_pnlLTop.gridx = 0;
		gbc_pnlLTop.gridy = 0;
		panel_2.add(pnlLTop, gbc_pnlLTop);
		
		pnlLBot = new ImagePanel();
		pnlLBot.setBorder(new LineBorder(Color.RED));
		GridBagConstraints gbc_pnlLBot = new GridBagConstraints();
		gbc_pnlLBot.fill = GridBagConstraints.BOTH;
		gbc_pnlLBot.gridx = 0;
		gbc_pnlLBot.gridy = 1;
		panel_2.add(pnlLBot, gbc_pnlLBot);
		
		JPanel panel_3 = new JPanel();
		GridBagConstraints gbc_panel_3 = new GridBagConstraints();
		gbc_panel_3.fill = GridBagConstraints.BOTH;
		gbc_panel_3.gridx = 1;
		gbc_panel_3.gridy = 0;
		panel_1.add(panel_3, gbc_panel_3);
		GridBagLayout gbl_panel_3 = new GridBagLayout();
		gbl_panel_3.columnWidths = new int[]{237, 0};
		gbl_panel_3.rowHeights = new int[]{59, 59, 59, 59, 67, 0};
		gbl_panel_3.columnWeights = new double[]{0.0, Double.MIN_VALUE};
		gbl_panel_3.rowWeights = new double[]{0.0, 0.0, 0.0, 0.0, 1.0, Double.MIN_VALUE};
		panel_3.setLayout(gbl_panel_3);
		
		JPanel panel_4 = new JPanel();
		panel_4.setBorder(new LineBorder(new Color(0, 0, 0), 1, true));
		GridBagConstraints gbc_panel_4 = new GridBagConstraints();
		gbc_panel_4.fill = GridBagConstraints.BOTH;
		gbc_panel_4.insets = new Insets(0, 0, 5, 0);
		gbc_panel_4.gridx = 0;
		gbc_panel_4.gridy = 0;
		panel_3.add(panel_4, gbc_panel_4);
		panel_4.setLayout(new GridLayout(0, 2, 0, 0));
		
		JButton button = new JButton("Load Image");
		panel_4.add(button);
		
		JButton button_1 = new JButton("Store Image");
		panel_4.add(button_1);
		
		JPanel panel_5 = new JPanel();
		panel_5.setBorder(new LineBorder(new Color(0, 0, 0), 1, true));
		GridBagConstraints gbc_panel_5 = new GridBagConstraints();
		gbc_panel_5.fill = GridBagConstraints.BOTH;
		gbc_panel_5.insets = new Insets(0, 0, 5, 0);
		gbc_panel_5.gridx = 0;
		gbc_panel_5.gridy = 1;
		panel_3.add(panel_5, gbc_panel_5);
		panel_5.setLayout(new GridLayout(0, 2, 0, 0));
		
		JSpinner spinner_5 = new JSpinner();
		panel_5.add(spinner_5);
		
		JLabel label = new JLabel("Global Mean");
		panel_5.add(label);
		
		JSpinner spinner_6 = new JSpinner();
		panel_5.add(spinner_6);
		
		JLabel label_1 = new JLabel("Global Var");
		panel_5.add(label_1);
		
		JSpinner spinner_7 = new JSpinner();
		panel_5.add(spinner_7);
		
		JLabel label_2 = new JLabel("Brightness");
		panel_5.add(label_2);
		
		JSpinner spinner_8 = new JSpinner();
		panel_5.add(spinner_8);
		
		JLabel label_3 = new JLabel("Contrast");
		panel_5.add(label_3);
		
		JSpinner spinner_9 = new JSpinner();
		panel_5.add(spinner_9);
		
		JLabel label_4 = new JLabel("Image Width");
		panel_5.add(label_4);
		
		JPanel panel_6 = new JPanel();
		panel_6.setBorder(new LineBorder(new Color(0, 0, 0), 1, true));
		GridBagConstraints gbc_panel_6 = new GridBagConstraints();
		gbc_panel_6.fill = GridBagConstraints.BOTH;
		gbc_panel_6.insets = new Insets(0, 0, 5, 0);
		gbc_panel_6.gridx = 0;
		gbc_panel_6.gridy = 2;
		panel_3.add(panel_6, gbc_panel_6);
		
		JButton button_2 = new JButton("Go");
		panel_6.add(button_2);
		
		JPanel panel_7 = new JPanel();
		panel_7.setBorder(new LineBorder(new Color(0, 0, 0), 1, true));
		GridBagConstraints gbc_panel_7 = new GridBagConstraints();
		gbc_panel_7.fill = GridBagConstraints.BOTH;
		gbc_panel_7.insets = new Insets(0, 0, 5, 0);
		gbc_panel_7.gridx = 0;
		gbc_panel_7.gridy = 3;
		panel_3.add(panel_7, gbc_panel_7);
		
		Component verticalGlue = Box.createVerticalGlue();
		GridBagConstraints gbc_verticalGlue = new GridBagConstraints();
		gbc_verticalGlue.fill = GridBagConstraints.BOTH;
		gbc_verticalGlue.gridx = 0;
		gbc_verticalGlue.gridy = 4;
		panel_3.add(verticalGlue, gbc_verticalGlue);

	}
	
	public void update(Observable o, Object arg) {
		Model model = (Model) o;

		pnlLTop.setImage(model.getSourceImage());
		pnlLBot.setImage(model.getOutputImage());
	}

}
