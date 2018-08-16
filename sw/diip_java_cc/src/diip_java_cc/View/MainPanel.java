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

import diip_java_cc.Controller.Controller;
import diip_java_cc.Model.Model;
import javax.swing.SwingConstants;
import javax.swing.JCheckBox;
import javax.swing.JTextField;
import javax.swing.SpinnerModel;
import javax.swing.SpinnerNumberModel;

import java.awt.event.ActionListener;
import java.io.File;
import java.awt.event.ActionEvent;

public class MainPanel extends JPanel implements ActionListener {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	private Controller controller;
	
	private FileChooser fileChooser;
	
	private ImagePanel pnlLTop;
	private ImagePanel pnlLBot;
	private JTextField tfFPGA1;
	private JTextField tfFPGA2;

	private JCheckBox cbFPGA1;
	private JCheckBox cbFPGA2;
	private JCheckBox cbLW1;
	private JCheckBox cbLW2;
	private JButton btGo;
	private JButton btLoadImg;
	private JButton btStoreImg;
	private JLabel lblFPGA1;
	private JLabel lblFPGA2;
	private JLabel lblLW1;
	private JLabel lblLW2;
	private JLabel lblImageWidth;
	private JLabel lblImageHeight, lblWorkers;
	/**
	 * Create the panel.
	 */
	public MainPanel(Controller c) {
		controller = c;
		
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
		gbl_panel_3.rowHeights = new int[]{59, 59, 59, 59, 0, 67, 0};
		gbl_panel_3.columnWeights = new double[]{1.0, Double.MIN_VALUE};
		gbl_panel_3.rowWeights = new double[]{0.0, 0.0, 0.0, 0.0, 1.0, 1.0, Double.MIN_VALUE};
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
		
		
		// Load Image
		btLoadImg = new JButton("Load Image");
		btLoadImg.addActionListener(this);
		panel_4.add(btLoadImg);		
		
		//Store Image
		btStoreImg = new JButton("Store Image");
		btStoreImg.addActionListener(this);
		panel_4.add(btStoreImg);
				
		JPanel panel_5 = new JPanel();
		panel_5.setBorder(new LineBorder(new Color(0, 0, 0), 1, true));
		GridBagConstraints gbc_panel_5 = new GridBagConstraints();
		gbc_panel_5.fill = GridBagConstraints.BOTH;
		gbc_panel_5.insets = new Insets(0, 0, 5, 0);
		gbc_panel_5.gridx = 0;
		gbc_panel_5.gridy = 1;
		panel_3.add(panel_5, gbc_panel_5);
		panel_5.setLayout(new GridLayout(0, 2, 0, 0));
		
		// Global Mean
		JEngineerField spinner_5 = new JEngineerField();
		spinner_5.setHorizontalAlignment(SwingConstants.RIGHT);
		spinner_5.setValue(127.0);
		spinner_5.setMinValue(0.0);
		spinner_5.setMaxValue(255.0);
		panel_5.add(spinner_5);
			
		JLabel label = new JLabel("Global Mean");
		panel_5.add(label);
		
		// Global Variance
		JEngineerField spinner_6 = new JEngineerField();
		spinner_6.setHorizontalAlignment(SwingConstants.RIGHT);
		spinner_6.setValue(3600.0);
		spinner_6.setMinValue(0.0);
		spinner_6.setMaxValue(16384.0);
		panel_5.add(spinner_6);
		
		JLabel label_1 = new JLabel("Global Var");
		panel_5.add(label_1);
		
		// Brightness
		JEngineerField spinner_7 = new JEngineerField();
		spinner_7.setValue(0.5);
		spinner_7.setMinValue(0.0);
		spinner_7.setMaxValue(1.0);
		spinner_7.setHorizontalAlignment(SwingConstants.RIGHT);
		panel_5.add(spinner_7);
		
		JLabel label_2 = new JLabel("Brightness");
		panel_5.add(label_2);
		
		// Contrast
		JEngineerField spinner_8 = new JEngineerField();
		spinner_8.setHorizontalAlignment(SwingConstants.RIGHT);
		spinner_8.setValue(0.8);
		spinner_8.setMinValue(0.0);
		spinner_8.setMaxValue(1.0);
		panel_5.add(spinner_8);
		
		JLabel label_3 = new JLabel("Contrast");
		panel_5.add(label_3);
		
		// Window Length
		JEngineerField spinner_9 = new JEngineerField();
		spinner_9.setHorizontalAlignment(SwingConstants.RIGHT);
		spinner_9.setValue(21.0);
		spinner_9.setMinValue(11.0);
		spinner_9.setMaxValue(41.0);
		panel_5.add(spinner_9);
		
		JLabel label_4 = new JLabel("Window Length");
		panel_5.add(label_4);
		
		JPanel panel_6 = new JPanel();
		panel_6.setBorder(new LineBorder(new Color(0, 0, 0), 1, true));
		GridBagConstraints gbc_panel_6 = new GridBagConstraints();
		gbc_panel_6.fill = GridBagConstraints.BOTH;
		gbc_panel_6.insets = new Insets(0, 0, 5, 0);
		gbc_panel_6.gridx = 0;
		gbc_panel_6.gridy = 2;
		panel_3.add(panel_6, gbc_panel_6);
		GridBagLayout gbl_panel_6 = new GridBagLayout();
		gbl_panel_6.columnWidths = new int[]{81, 75, 0};
		gbl_panel_6.rowHeights = new int[] {0, 0, 0, 0, 0, 0};
		gbl_panel_6.columnWeights = new double[]{0.0, 1.0, Double.MIN_VALUE};
		gbl_panel_6.rowWeights = new double[]{0.0, 0.0, 0.0, 0.0, 0.0, Double.MIN_VALUE};
		panel_6.setLayout(gbl_panel_6);
		
		JLabel lblImageWidht = new JLabel("Image Widht");
		lblImageWidht.setHorizontalAlignment(SwingConstants.LEFT);
		GridBagConstraints gbc_lblImageWidht = new GridBagConstraints();
		gbc_lblImageWidht.anchor = GridBagConstraints.NORTHWEST;
		gbc_lblImageWidht.insets = new Insets(0, 0, 5, 5);
		gbc_lblImageWidht.gridx = 0;
		gbc_lblImageWidht.gridy = 0;
		panel_6.add(lblImageWidht, gbc_lblImageWidht);
		
		lblImageWidth = new JLabel("-");
		GridBagConstraints gbc_lblImageWidth = new GridBagConstraints();
		gbc_lblImageWidth.anchor = GridBagConstraints.NORTH;
		gbc_lblImageWidth.insets = new Insets(0, 0, 5, 0);
		gbc_lblImageWidth.gridx = 1;
		gbc_lblImageWidth.gridy = 0;
		panel_6.add(lblImageWidth, gbc_lblImageWidth);
		
		JLabel lblImageHeightStatic = new JLabel("Image Height");
		lblImageHeightStatic.setHorizontalAlignment(SwingConstants.LEFT);
		GridBagConstraints gbc_lblImageHeightStatic = new GridBagConstraints();
		gbc_lblImageHeightStatic.anchor = GridBagConstraints.NORTHWEST;
		gbc_lblImageHeightStatic.insets = new Insets(0, 0, 5, 5);
		gbc_lblImageHeightStatic.gridx = 0;
		gbc_lblImageHeightStatic.gridy = 1;
		panel_6.add(lblImageHeightStatic, gbc_lblImageHeightStatic);
		
		lblImageHeight = new JLabel("-");
		GridBagConstraints gbc_lblImageHeight = new GridBagConstraints();
		gbc_lblImageHeight.anchor = GridBagConstraints.NORTH;
		gbc_lblImageHeight.insets = new Insets(0, 0, 5, 0);
		gbc_lblImageHeight.gridx = 1;
		gbc_lblImageHeight.gridy = 1;
		panel_6.add(lblImageHeight, gbc_lblImageHeight);
		
		JLabel lblSplitIntoStatic = new JLabel("Split into");
		lblSplitIntoStatic.setHorizontalAlignment(SwingConstants.LEFT);
		GridBagConstraints gbc_lblSplitIntoStatic = new GridBagConstraints();
		gbc_lblSplitIntoStatic.anchor = GridBagConstraints.NORTHWEST;
		gbc_lblSplitIntoStatic.insets = new Insets(0, 0, 5, 5);
		gbc_lblSplitIntoStatic.gridx = 0;
		gbc_lblSplitIntoStatic.gridy = 2;
		panel_6.add(lblSplitIntoStatic, gbc_lblSplitIntoStatic);
		
		JLabel lblSplitInto = new JLabel("-");
		GridBagConstraints gbc_lblSplitInto = new GridBagConstraints();
		gbc_lblSplitInto.anchor = GridBagConstraints.NORTH;
		gbc_lblSplitInto.insets = new Insets(0, 0, 5, 0);
		gbc_lblSplitInto.gridx = 1;
		gbc_lblSplitInto.gridy = 2;
		panel_6.add(lblSplitInto, gbc_lblSplitInto);
		
		btGo = new JButton("Go");
		btGo.addActionListener(this);
		
		JLabel lblWorkersstatic = new JLabel("Workers");
		GridBagConstraints gbc_lblWorkersstatic = new GridBagConstraints();
		gbc_lblWorkersstatic.anchor = GridBagConstraints.WEST;
		gbc_lblWorkersstatic.insets = new Insets(0, 0, 5, 5);
		gbc_lblWorkersstatic.gridx = 0;
		gbc_lblWorkersstatic.gridy = 3;
		panel_6.add(lblWorkersstatic, gbc_lblWorkersstatic);
		
		lblWorkers = new JLabel("-");
		GridBagConstraints gbc_lblWorkers = new GridBagConstraints();
		gbc_lblWorkers.insets = new Insets(0, 0, 5, 0);
		gbc_lblWorkers.gridx = 1;
		gbc_lblWorkers.gridy = 3;
		panel_6.add(lblWorkers, gbc_lblWorkers);
		GridBagConstraints gbc_btGo = new GridBagConstraints();
		gbc_btGo.fill = GridBagConstraints.BOTH;
		gbc_btGo.gridwidth = 2;
		gbc_btGo.anchor = GridBagConstraints.NORTHWEST;
		gbc_btGo.gridx = 0;
		gbc_btGo.gridy = 4;
		panel_6.add(btGo, gbc_btGo);
		
		JPanel panel_7 = new JPanel();
		panel_7.setBorder(new LineBorder(new Color(0, 0, 0), 1, true));
		GridBagConstraints gbc_panel_7 = new GridBagConstraints();
		gbc_panel_7.fill = GridBagConstraints.BOTH;
		gbc_panel_7.insets = new Insets(0, 0, 5, 0);
		gbc_panel_7.gridx = 0;
		gbc_panel_7.gridy = 3;
		panel_3.add(panel_7, gbc_panel_7);
		GridBagLayout gbl_panel_7 = new GridBagLayout();
		gbl_panel_7.columnWidths = new int[]{0, 0, 43, 0};
		gbl_panel_7.rowHeights = new int[]{0, 0, 0, 0};
		gbl_panel_7.columnWeights = new double[]{0.0, 0.0, 1.0, Double.MIN_VALUE};
		gbl_panel_7.rowWeights = new double[]{0.0, 0.0, 0.0, Double.MIN_VALUE};
		panel_7.setLayout(gbl_panel_7);
		
		JLabel lblLocalWorkers = new JLabel("Local Workers");
		GridBagConstraints gbc_lblLocalWorkers = new GridBagConstraints();
		gbc_lblLocalWorkers.insets = new Insets(0, 0, 5, 5);
		gbc_lblLocalWorkers.anchor = GridBagConstraints.WEST;
		gbc_lblLocalWorkers.gridwidth = 2;
		gbc_lblLocalWorkers.gridx = 0;
		gbc_lblLocalWorkers.gridy = 0;
		panel_7.add(lblLocalWorkers, gbc_lblLocalWorkers);
		
		cbLW1 = new JCheckBox("");
		cbLW1.addActionListener(this);
		GridBagConstraints gbc_cbLW1 = new GridBagConstraints();
		gbc_cbLW1.insets = new Insets(0, 0, 5, 5);
		gbc_cbLW1.gridx = 0;
		gbc_cbLW1.gridy = 1;
		panel_7.add(cbLW1, gbc_cbLW1);
		
		JLabel lblWorker = new JLabel("Worker 1");
		GridBagConstraints gbc_lblWorker = new GridBagConstraints();
		gbc_lblWorker.insets = new Insets(0, 0, 5, 5);
		gbc_lblWorker.gridx = 1;
		gbc_lblWorker.gridy = 1;
		panel_7.add(lblWorker, gbc_lblWorker);
		
		lblLW1 = new JLabel("-");
		GridBagConstraints gbc_lblLW1 = new GridBagConstraints();
		gbc_lblLW1.anchor = GridBagConstraints.WEST;
		gbc_lblLW1.insets = new Insets(0, 0, 5, 0);
		gbc_lblLW1.gridx = 2;
		gbc_lblLW1.gridy = 1;
		panel_7.add(lblLW1, gbc_lblLW1);
		
		cbLW2 = new JCheckBox("");
		cbLW2.addActionListener(this);
		GridBagConstraints gbc_cbLW2 = new GridBagConstraints();
		gbc_cbLW2.insets = new Insets(0, 0, 0, 5);
		gbc_cbLW2.gridx = 0;
		gbc_cbLW2.gridy = 2;
		panel_7.add(cbLW2, gbc_cbLW2);
		
		JLabel lblWorker_1 = new JLabel("Worker 2");
		GridBagConstraints gbc_lblWorker_1 = new GridBagConstraints();
		gbc_lblWorker_1.insets = new Insets(0, 0, 0, 5);
		gbc_lblWorker_1.gridx = 1;
		gbc_lblWorker_1.gridy = 2;
		panel_7.add(lblWorker_1, gbc_lblWorker_1);
		
		lblLW2 = new JLabel("-");
		GridBagConstraints gbc_lblLW2 = new GridBagConstraints();
		gbc_lblLW2.anchor = GridBagConstraints.WEST;
		gbc_lblLW2.gridx = 2;
		gbc_lblLW2.gridy = 2;
		panel_7.add(lblLW2, gbc_lblLW2);
		
		JPanel panel_8 = new JPanel();
		panel_8.setBorder(new LineBorder(new Color(0, 0, 0), 1, true));
		GridBagConstraints gbc_panel_8 = new GridBagConstraints();
		gbc_panel_8.insets = new Insets(0, 0, 5, 0);
		gbc_panel_8.fill = GridBagConstraints.BOTH;
		gbc_panel_8.gridx = 0;
		gbc_panel_8.gridy = 4;
		panel_3.add(panel_8, gbc_panel_8);
		GridBagLayout gbl_panel_8 = new GridBagLayout();
		gbl_panel_8.columnWidths = new int[]{31, 154, 48, 0};
		gbl_panel_8.rowHeights = new int[]{0, 0, 0, 0};
		gbl_panel_8.columnWeights = new double[]{0.0, 0.0, 1.0, Double.MIN_VALUE};
		gbl_panel_8.rowWeights = new double[]{0.0, 0.0, 0.0, Double.MIN_VALUE};
		panel_8.setLayout(gbl_panel_8);
		
		JLabel lblFpgaWorkers = new JLabel("FPGA Workers");
		GridBagConstraints gbc_lblFpgaWorkers = new GridBagConstraints();
		gbc_lblFpgaWorkers.anchor = GridBagConstraints.WEST;
		gbc_lblFpgaWorkers.gridwidth = 2;
		gbc_lblFpgaWorkers.insets = new Insets(0, 0, 5, 5);
		gbc_lblFpgaWorkers.gridx = 0;
		gbc_lblFpgaWorkers.gridy = 0;
		panel_8.add(lblFpgaWorkers, gbc_lblFpgaWorkers);
		
		cbFPGA1 = new JCheckBox("");
		cbFPGA1.addActionListener(this);
		GridBagConstraints gbc_cbFPGA1 = new GridBagConstraints();
		gbc_cbFPGA1.insets = new Insets(0, 0, 5, 5);
		gbc_cbFPGA1.gridx = 0;
		gbc_cbFPGA1.gridy = 1;
		panel_8.add(cbFPGA1, gbc_cbFPGA1);
		
		tfFPGA1 = new JTextField();
		tfFPGA1.setText("192.168.5.9:42042");
		GridBagConstraints gbc_tfFPGA1 = new GridBagConstraints();
		gbc_tfFPGA1.fill = GridBagConstraints.BOTH;
		gbc_tfFPGA1.anchor = GridBagConstraints.WEST;
		gbc_tfFPGA1.insets = new Insets(0, 0, 5, 5);
		gbc_tfFPGA1.gridx = 1;
		gbc_tfFPGA1.gridy = 1;
		panel_8.add(tfFPGA1, gbc_tfFPGA1);
		tfFPGA1.setColumns(10);
		
		lblFPGA1 = new JLabel("-");
		GridBagConstraints gbc_lblFPGA1 = new GridBagConstraints();
		gbc_lblFPGA1.anchor = GridBagConstraints.WEST;
		gbc_lblFPGA1.insets = new Insets(0, 0, 5, 0);
		gbc_lblFPGA1.gridx = 2;
		gbc_lblFPGA1.gridy = 1;
		panel_8.add(lblFPGA1, gbc_lblFPGA1);
		
		cbFPGA2 = new JCheckBox("");
		cbFPGA2.addActionListener(this);
		GridBagConstraints gbc_cbFPGA2 = new GridBagConstraints();
		gbc_cbFPGA2.insets = new Insets(0, 0, 0, 5);
		gbc_cbFPGA2.gridx = 0;
		gbc_cbFPGA2.gridy = 2;
		panel_8.add(cbFPGA2, gbc_cbFPGA2);
		
		tfFPGA2 = new JTextField();
		tfFPGA2.setText("192.168.5.8:42042");
		GridBagConstraints gbc_tfFPGA2 = new GridBagConstraints();
		gbc_tfFPGA2.fill = GridBagConstraints.BOTH;
		gbc_tfFPGA2.anchor = GridBagConstraints.WEST;
		gbc_tfFPGA2.insets = new Insets(0, 0, 0, 5);
		gbc_tfFPGA2.gridx = 1;
		gbc_tfFPGA2.gridy = 2;
		panel_8.add(tfFPGA2, gbc_tfFPGA2);
		tfFPGA2.setColumns(10);
		
		lblFPGA2 = new JLabel("-");
		GridBagConstraints gbc_lblFPGA2 = new GridBagConstraints();
		gbc_lblFPGA2.anchor = GridBagConstraints.WEST;
		gbc_lblFPGA2.gridx = 2;
		gbc_lblFPGA2.gridy = 2;
		panel_8.add(lblFPGA2, gbc_lblFPGA2);
		
		Component verticalGlue = Box.createVerticalGlue();
		GridBagConstraints gbc_verticalGlue = new GridBagConstraints();
		gbc_verticalGlue.fill = GridBagConstraints.BOTH;
		gbc_verticalGlue.gridx = 0;
		gbc_verticalGlue.gridy = 5;
		panel_3.add(verticalGlue, gbc_verticalGlue);
		
		
		// FileChooser
		this.fileChooser = new FileChooser(controller);
		fileChooser.fileFilter();

	}
	
	public void update(Observable o, Object arg) {
		Model model = (Model) o;

		pnlLTop.setImage(model.getSourceImage());
		pnlLBot.setImage(model.getOutputImage());

		lblImageHeight.setText(String.valueOf(model.getSourceImage().getWidth()));
		lblImageWidth.setText(String.valueOf(model.getSourceImage().getHeight()));
		
		lblWorkers.setText(String.valueOf(model.getNWorkers()));
		
		btGo.setEnabled(!model.getDP().isRunning());
		pnlLTop.updateme();
		pnlLBot.updateme();
	}

	@Override
	public void actionPerformed(ActionEvent e) {
		if(e.getSource() == cbFPGA1) {
			controller.fpgaChanged(1,cbFPGA1.isSelected(),tfFPGA1.getText());
			tfFPGA1.setEnabled(!cbFPGA1.isSelected()); 
		}
		if(e.getSource() == cbFPGA2) {
			controller.fpgaChanged(2,cbFPGA1.isSelected(),tfFPGA2.getText());
			tfFPGA2.setEnabled(!cbFPGA2.isSelected()); 
		}
		if(e.getSource() == cbLW1) {
			controller.localWorkerChanged(1,cbLW1.isSelected());
		}
		if(e.getSource() == cbLW2) {
			controller.localWorkerChanged(2,cbLW2.isSelected());
		}
		if(e.getSource() == btGo) {
			controller.goRequest();
		}
		if(e.getSource() == btLoadImg) {
			String fName = fileChooser.showFileChooser();
			File f = fileChooser.getFile();
			if (fName != null) {
				controller.loadFile(f);
			}
		}
		
	}

}
