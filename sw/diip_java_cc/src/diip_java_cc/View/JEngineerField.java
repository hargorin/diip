package diip_java_cc.View;

import java.awt.Color;
import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.FocusEvent;
import java.awt.event.FocusListener;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.Arrays;

import javax.swing.ButtonGroup;
import javax.swing.InputVerifier;
import javax.swing.JCheckBoxMenuItem;
import javax.swing.JComponent;
import javax.swing.JMenu;
import javax.swing.JPopupMenu;
import javax.swing.JRadioButtonMenuItem;
import javax.swing.JTextField;

/**
 * A powerful JTextField with inputverifyer, multiple outputmodes, rangecontroll
 * and a few static methods to work with doubles.
 * 
 * @author Richard Gut, FHNW
 * @author Patrick Studer, FHNW
 * @version 1.0
 * @since 30.05.2014
 */
public class JEngineerField extends JTextField implements FocusListener, ActionListener, MouseWheelListener {

	// Variabeln:
	public static final int ENG = 0, UNIT = 1, FLOAT = 2;
	public static final int ALL = 0, POS = 1, NEG = 2, NOZERO = 3, POSNOZERO = 4, NEGNOZERO = 5;
	private static final long serialVersionUID = 1L;
	private static final String[] UNITS = { "f", "p", "n", "u", "m", " ", "k", "M", "G", "T", "P" };
	private static final String[] EXP_UNITS = { "e-15", "e-12", "e-9", "e-6", "e-3", "e0", "e3", "e6", "e9", "e12",
			"e15" };
	private JEngineerField txtField = this;
	private JCheckBoxMenuItem cbmenuInputExp;
	private JCheckBoxMenuItem cbmenuInputUnit;
	private ButtonGroup group;
	private double minValue = -Double.MAX_VALUE, maxValue = Double.MAX_VALUE, value;
	private InputVerifier verifyer;
	private DecimalFormat formatter = null;
	private int digits = 3, outputMode = ENG;
	private boolean inputEXP = true, inputUNIT = true;
	private boolean edited = false, errorDisplayed = false;
	private String errorText = "invalid input", disabledText = "-";
	private int errorShowTime = 1000;
	private int nEReihe = 0;
	private double[] mEReihe;
	private boolean isEnabled = true;

	// Constructor:
	/**
	 * Builds a default JEngineerField (outputmode = ENG and digits = 3)
	 */
	public JEngineerField() {
		super();
		init();
	}

	/**
	 * Builds a formatted JEngineerField
	 * 
	 * @param formatter
	 *            The DecimalFormat defines the output format.
	 * @param col
	 *            Number of columns.
	 */
	public JEngineerField(DecimalFormat formatter, int col) {
		super(col);
		this.formatter = formatter;
		init();
	}

	/**
	 * Builds a default JEngineerField (outputmode = ENG and digits = 3)
	 * 
	 * @param col
	 *            Number of columns.
	 */
	public JEngineerField(int col) {
		super(col);
		init();
	}

	/**
	 * Constructs a JEngineerField (outputmode = ENG)
	 * 
	 * @param digits
	 *            Number of digits (e.g. 12.34e-12 = 4 digits)
	 * @param col
	 *            Number of columns.
	 */
	public JEngineerField(int digits, int col) {
		super(col);
		if (digits < 3 || digits > 16)
			throw new IllegalArgumentException();
		this.digits = digits;
		init();
	}

	/**
	 * onstructs a JEngineerField
	 * 
	 * @param digits
	 *            Anzahl angezeigter Digits (ENG und UNIT) oder Anzahl
	 *            Nachkommastellen (FLOAT)
	 * @param digits
	 *            Number of digits (e.g. 12.34e-12 = 4 digits)
	 * @param col
	 *            Number of columns.
	 * @param outputmode
	 *            Defines the output mode. (e.g. UNIT = 123.4k, ENG = 123.4e3)
	 */
	public JEngineerField(int digits, int col, int outputmode) {
		super(col);
		if (digits < 3 || digits > 16)
			throw new IllegalArgumentException();
		this.digits = digits;
		this.outputMode = outputmode;
		init();
	}

	public JEngineerField(int digits, int col, String stEReihe) {
		super(col);
		if (digits < 3 || digits > 16)
			throw new IllegalArgumentException();
		this.digits = digits;
		try {
			String[] s = stEReihe.trim().toUpperCase().split("[E ]+");
			nEReihe = Integer.parseInt(s[1]);
		} catch (NumberFormatException e) {
			throw new IllegalArgumentException();
		}

		mEReihe = new double[nEReihe];
		double rnd = 0.0;
		if (nEReihe < 48)
			rnd = 10.0;
		else
			rnd = 100.0;

		if (nEReihe == 12) {
			mEReihe = new double[] { 1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, 6.8, 8.2 };
		} else if (nEReihe == 24) {
			mEReihe = new double[] { 1.0, 1.1, 1.2, 1.3, 1.5, 1.6, 1.8, 2.0, 2.2, 2.4, 2.7, 3.0, 3.3, 3.6, 3.9, 4.3,
					4.7, 5.1, 5.6, 6.2, 6.8, 7.5, 8.2, 9.1 };
		} else {
			for (int i = 0; i < nEReihe; i++) {
				mEReihe[i] = Math.round(rnd * Math.pow(10.0, (double) i / nEReihe)) / rnd;
			}
		}

		addMouseWheelListener(this);
		init();
	}

	/**
	 * Converts a double value to a formatted String.
	 * 
	 * @param val
	 *            The value that you want to convert.
	 * @param digits
	 *            Number of digits (e.g. 12.34e-12 = 4 digits)
	 * @param outputmode
	 *            Defines the output mode. (e.g. UNIT = 123.4k, ENG = 123.4e3)
	 * @return The formatted number as a String.
	 */
	public static String DoubletoStringENG(double val, int digits, int outputmode) {
		DecimalFormatSymbols symbol = new DecimalFormatSymbols();
		final char systemDecimalSeperator = symbol.getDecimalSeparator();
		String returnVal = "";
		if (val == 0)
			return String.format("%1." + (digits - 1) + "f", 0.0);
		int exp = (int) Math.floor(Math.log10(Math.abs(val)));
		int engExp = (int) Math.floor(exp / 3.0) * 3;
		int preFix = (((exp + 330) % 3) + 1);
		double engVal = val / Math.pow(10.0, engExp);
		String stFormatter = "";
		switch (outputmode) {
		case JEngineerField.FLOAT:
			stFormatter = "%." + (digits) + "f";
			returnVal = (String.format(stFormatter, val)).trim();
			break;
		case JEngineerField.ENG:
			stFormatter = "%" + preFix + "." + (digits - preFix) + "f";
			if (engExp != 0)
				stFormatter += "e%d";
			returnVal = (String.format(stFormatter, engVal, engExp)).trim();
			break;
		case JEngineerField.UNIT:
			stFormatter = "%" + preFix + "." + (digits - preFix) + "f";
			try {
				String unit = JEngineerField.UNITS[5 + engExp / 3];
				returnVal = (String.format(stFormatter, engVal) + unit.trim()).trim();
			} catch (Exception ex) {
				if (engExp != 0)
					stFormatter += "e%d";
				returnVal = (String.format(stFormatter, engVal, engExp)).trim();
			}
			break;
		}
		returnVal = returnVal.replace('.', systemDecimalSeperator);
		return returnVal;
	}

	/**
	 * Returns the exponent of a number.
	 * 
	 * @param val
	 *            A value.
	 * @return The value's exponent.
	 */
	public static int getExpOfValue(double val) {
		int exp = (int) Math.floor(Math.log10(Math.abs(val)));
		int engExp = (int) Math.floor(exp / 3.0) * 3;
		return engExp;
	}

	/**
	 * Returns the exponent of a number and converts it to unit suffix.
	 * 
	 * @param val
	 *            A value.
	 * @return The value's unit suffix. (from 1e-15 to 1e15)
	 */
	public static String getUnitOfValue(double val) {
		String unit;
		if (val == 0) {
			return "";
		}
		int exp = (int) Math.floor(Math.log10(Math.abs(val)));
		int engExp = (int) Math.floor(exp / 3.0) * 3;
		try {
			unit = JEngineerField.UNITS[5 + engExp / 3];
		} catch (ArrayIndexOutOfBoundsException ex) {
			return null;
		}
		return unit;
	}

	@Override
	public void mouseWheelMoved(MouseWheelEvent e) {
		if (super.isFocusOwner() == false)
			return;
		if (isEnabled == false)
			return;
		fireActionPerformed();

		if (getValue() == 0.0)
			setValue(1e-15);

		double exp = Math.pow(10.0, (int) Math.floor(Math.log10(Math.abs(getValue()))));
		double mantisse = getValue() / exp;
		double dist = Double.MAX_VALUE;
		int index = 0;

		for (int i = 0; i < mEReihe.length; i++) {
			if (Math.abs(mantisse - mEReihe[i]) < dist) {
				dist = Math.abs(mantisse - mEReihe[i]);
				index = i;
			}
		}

		if (nEReihe != 0) {
			if (e.getWheelRotation() < 0) {
				if (index == mEReihe.length - 1)
					exp *= 10.0;
				setValue(mEReihe[(nEReihe + index + 1) % nEReihe] * exp);
			} else {
				if (index == 0)
					exp /= 10.0;
				setValue(mEReihe[(nEReihe + index - 1) % nEReihe] * exp);
			}

		}
	}

	/**
	 * Overwritten method.
	 * 
	 * @param e
	 *            The ActionEvent.
	 * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
	 */
	@Override
	public void actionPerformed(ActionEvent e) {
		inputEXP = cbmenuInputExp.getState();
		inputUNIT = cbmenuInputUnit.getState();
		outputMode = Integer.parseInt(group.getSelection().getActionCommand());
		setValue(getValue());
	}

	/**
	 * Adds a popup-menu to this JEngineerField. This allows to configure
	 * settings by right click into the field.
	 */
	public void addPopupMenu() {
		txtField.addPopupMenu(txtField);
	}

	// Interne Methoden
	/**
	 * Overwritten method.
	 * 
	 * @see java.awt.event.FocusListener#focusGained(java.awt.event.FocusEvent)
	 */
	@Override
	public void focusGained(FocusEvent e) {
		selectAll();
	}

	/**
	 * Overwritten method.
	 * 
	 * @see java.awt.event.FocusListener#focusLost(java.awt.event.FocusEvent)
	 */
	@Override
	public void focusLost(FocusEvent e) {
		fireActionPerformed();
	}

	/**
	 * Returns the output mode of the JEngineerField.
	 * 
	 * @return The outputMode.
	 */
	public int getOutputMode() {
		return outputMode;
	}

	/**
	 * Gets the actual JEngineerField text.
	 * 
	 * @param outputMode
	 *            Defines the output mode of the returned string.
	 * @return The JEngineerField text.
	 */
	public String getText(int outputMode) {
		return new String(DoubletoStringENG(value, digits, outputMode));
	}

	/**
	 * Gets the actual JEngineerField text.
	 * 
	 * @param digits
	 *            Defines the number of digits of the returned string.
	 * @param outputMode
	 *            Defines the output mode of the returned string.
	 * @return The JEngineerField text.
	 */
	@Override
	public String getText(int digits, int outputMode) {
		return DoubletoStringENG(value, digits, outputMode);
	}

	/**
	 * Gets the actual JEngineerField value.
	 * 
	 * @return The double JEngineerField value.
	 */
	public double getValue() {
		return value;
	}

	/**
	 * Change the disabled text of this JEngineerField (is active when field is
	 * disabled)
	 * 
	 * @param disabledText
	 *            The new disabled text.
	 */
	public void setDisabledText(String disabledText) {
		if (disabledText != null)
			this.disabledText = disabledText;
	}

	/**
	 * Overwritten method.
	 * 
	 * @param b
	 *            true = enable, false = disable
	 * @see javax.swing.JComponent#setEnabled(boolean)
	 */

	@Override
	public void setEnabled(boolean b) {
		isEnabled = b;
		if (b) {
			txtField.setValue(value);
		} else {
			edited = false;
			txtField.setText(disabledText);
		}
		super.setEnabled(b);
	}

	/**
	 * Change the error text show time.
	 * 
	 * @param millis
	 *            Milliseconds.
	 */
	public void setErrorShowTime(int millis) {
		this.errorShowTime = millis;
	}

	/**
	 * Change the error text of this JEngineerField.
	 * 
	 * @param errText
	 *            The new error text.
	 */
	public void setErrorText(String errText) {
		if (errText != null)
			this.errorText = errText;
	}

	/**
	 * Change the allowed range for the input value.
	 * 
	 * @param maxValue
	 *            The highest allowed value.
	 */
	public void setMaxValue(double maxValue) {
		this.maxValue = maxValue;
		setToolTipText("Value \u2264 " + DoubletoStringENG(maxValue, 4, JEngineerField.UNIT));
	}

	/**
	 * Change the allowed range for the input value.
	 * 
	 * @param minValue
	 *            The lowest allowed value.
	 */
	public void setMinValue(double minValue) {
		this.minValue = minValue;
		setToolTipText("Value \u2265 " + DoubletoStringENG(minValue, 4, JEngineerField.UNIT));
	}

	/**
	 * Change the output mode of the JEngineerField.
	 * 
	 * @param outputMode
	 *            The new output mode of this JEngineerField.
	 */
	public void setOutputMode(int outputMode) {
		this.outputMode = outputMode;
	}

	/**
	 * Change the allowed range for the input value.
	 * 
	 * @param minValue
	 *            The lowest allowed value.
	 * @param maxValue
	 *            The highest allowed value.
	 */
	public void setRange(double minValue, double maxValue) {
		this.minValue = minValue;
		this.maxValue = maxValue;
		setToolTipText(DoubletoStringENG(minValue, 4, JEngineerField.UNIT) + " \u2264 Value \u2264 "
				+ DoubletoStringENG(maxValue, 4, JEngineerField.UNIT));
	}

	/**
	 * Change the allowed range for the input value.
	 * 
	 * @param rangeSpecifyer
	 *            A JEngineerField constant that specifies the allowed range.
	 *            (e.g ALL, POS, NEGNOZERO,..)
	 */
	public void setRange(int rangeSpecifyer) {
		switch (rangeSpecifyer) {
		case ALL:
			minValue = -Double.MAX_VALUE;
			maxValue = Double.MAX_VALUE;
			setToolTipText("Value \u2208 {\u211D}");
			break;
		case POS:
			minValue = 0;
			maxValue = Double.MAX_VALUE;
			setToolTipText("Value \u2265 0");
			break;
		case NEG:
			minValue = -Double.MAX_VALUE;
			maxValue = 0;
			setToolTipText("Value \u2264 0");
			break;
		case NOZERO:
			minValue = -Double.MAX_VALUE;
			maxValue = Double.MAX_VALUE;
			setToolTipText("Value \u2208 {\u211D\\0}");
			break;
		case POSNOZERO:
			minValue = 0;
			maxValue = Double.MAX_VALUE;
			setToolTipText("Value > 0");
			break;
		case NEGNOZERO:
			minValue = -Double.MAX_VALUE;
			maxValue = 0;
			setToolTipText("Value < 0");
			break;
		default:
			minValue = -Double.MAX_VALUE;
			maxValue = Double.MAX_VALUE;
			setToolTipText("Value \u2208 {\u211D}");
			break;
		}
	}

	// Setter & Getter:
	/**
	 * Sets the value of the JEngineerField.
	 * 
	 * @param value
	 *            A double value.
	 */
	public void setValue(double value) {
		this.value = value;
		edited = false;
		if (formatter != null) {
			txtField.setText(formatter.format(value));
		} else if (digits != 0) {
			txtField.setText(DoubletoStringENG(value, digits, outputMode));
		} else {
			txtField.setText("" + value);
		}
	}

	private void addPopupMenu(Component component) {
		final JPopupMenu popupMenu = new JPopupMenu();
		final JMenu menuInput = new JMenu("Inputmode");
		popupMenu.add(menuInput);
		cbmenuInputExp = new JCheckBoxMenuItem("Engineering Notation enabled");
		cbmenuInputExp.addActionListener(this);
		cbmenuInputExp.setSelected(true);
		menuInput.add(cbmenuInputExp);
		cbmenuInputUnit = new JCheckBoxMenuItem("Unit Prefixes enabled");
		cbmenuInputUnit.addActionListener(this);
		cbmenuInputUnit.setSelected(true);
		menuInput.add(cbmenuInputUnit);
		final JMenu menuOutput = new JMenu("Outputmode");
		popupMenu.add(menuOutput);
		group = new ButtonGroup();
		final JRadioButtonMenuItem rbmenuOutputEng = new JRadioButtonMenuItem("Engineering Notation");
		if (outputMode == JEngineerField.ENG)
			rbmenuOutputEng.setSelected(true);
		rbmenuOutputEng.addActionListener(this);
		rbmenuOutputEng.setActionCommand("" + JEngineerField.ENG);
		group.add(rbmenuOutputEng);
		menuOutput.add(rbmenuOutputEng);
		final JRadioButtonMenuItem rbmenuOutputUnit = new JRadioButtonMenuItem("Unit Prefixes");
		if (outputMode == JEngineerField.UNIT)
			rbmenuOutputUnit.setSelected(true);
		rbmenuOutputUnit.addActionListener(this);
		rbmenuOutputUnit.setActionCommand("" + JEngineerField.UNIT);
		menuOutput.add(rbmenuOutputUnit);
		group.add(rbmenuOutputUnit);
		final JRadioButtonMenuItem rbmenuOutputFloat = new JRadioButtonMenuItem("Floating Point Number");
		if (outputMode == JEngineerField.FLOAT)
			rbmenuOutputFloat.setSelected(true);
		rbmenuOutputFloat.addActionListener(this);
		rbmenuOutputFloat.setActionCommand("" + JEngineerField.FLOAT);
		menuOutput.add(rbmenuOutputFloat);
		group.add(rbmenuOutputFloat);

		component.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				if (e.isPopupTrigger()) {
					showMenu(e);
				}
			}

			@Override
			public void mouseReleased(MouseEvent e) {
				if (e.isPopupTrigger()) {
					showMenu(e);
				}
			}

			private void showMenu(MouseEvent e) {
				popupMenu.show(e.getComponent(), e.getX(), e.getY());
			}
		});
	}

	private void errorMsg() {
		if (errorDisplayed)
			return;
		errorDisplayed = true;
		final Color color = getForeground();
		setForeground(Color.red);
		txtField.setText(errorText);
		javax.swing.Timer timer = new javax.swing.Timer(errorShowTime, new ActionListener() {
			@Override
			public void actionPerformed(ActionEvent e) {
				setForeground(color);
				if (formatter != null) {
					txtField.setText(formatter.format(value));
				} else {
					txtField.setText(DoubletoStringENG(value, digits, outputMode));
				}
				requestFocus();
				selectAll();
				edited = false;
				errorDisplayed = false;
			}
		});
		timer.setRepeats(false);
		timer.start();
	}

	// Initialisierung:
	private void init() {
		verifyer = (new InputVerifier() {
			@Override
			public boolean verify(JComponent input) {
				double v = 0.0;

				try {
					v = Double.parseDouble(unitCheck(txtField.getText()).trim());
				} catch (NumberFormatException e) {
					// errorMsg();
					return false;
				}
				if (v > maxValue || v < minValue) {
					errorMsg();
					if (v > maxValue) {
						value = 4;
					}
					if (v < minValue) {
						value = 2;
					}
					return false;
				} else {
					if (edited) {
						value = v;
						edited = false;
						if (txtField.formatter != null) {
							txtField.setText(txtField.formatter.format(value));
						} else if (digits >= 3) {
							txtField.setText(DoubletoStringENG(value, digits, outputMode));
						}
						return true;
					}
				}

				return false;

			}
		});

		addKeyListener(new KeyAdapter() {
			@Override
			public void keyTyped(KeyEvent e) {
				if (e.getKeyChar() != KeyEvent.VK_ENTER)
					edited = true;
				char caracter = e.getKeyChar();

				if (caracter == ' ' || caracter == 'd' || (!inputUNIT && caracter == 'f')) {
					e.consume();
					return;
				}
				if (caracter == ',') {
					caracter = '.';
					e.setKeyChar('.');
				}
				String preText = "";
				String postText = "";
				if (txtField.getSelectedText() == null) {
					preText = unitCheck(txtField.getText().substring(0, txtField.getCaretPosition()));
					postText = unitCheck(txtField.getText().substring(txtField.getCaretPosition()));
				} else {
					preText = unitCheck(txtField.getText().substring(0, txtField.getSelectionStart()));
					postText = unitCheck(txtField.getText().substring(txtField.getSelectionEnd()));
				}
				try {
					if (caracter == '-' || caracter == '+' || (inputEXP && caracter == 'e')) {
						Double.parseDouble(preText + caracter + "1" + postText);
					} else if (inputUNIT && Arrays.asList(JEngineerField.UNITS).contains("" + caracter)) {
						Double.parseDouble((preText + "e1" + postText));
					} else {
						Double.parseDouble(preText + caracter + postText);
					}

				} catch (Exception ex) {
					e.consume();
				}
			}

		});
		txtField.addFocusListener(this);
		txtField.addActionListener(new ActionListener() {
			@Override
			public void actionPerformed(ActionEvent e) {
				fireActionPerformed();
			}
		});
	}

	private String unitCheck(String input) {
		for (int i = 0; i < JEngineerField.UNITS.length; i++) {
			input = input.trim().replace(JEngineerField.UNITS[i], JEngineerField.EXP_UNITS[i] + " ");
		}
		return input;
	}

	@Override
	protected void fireActionPerformed() {
		if (verifyer.verify(this))
			super.fireActionPerformed();
	}

}

