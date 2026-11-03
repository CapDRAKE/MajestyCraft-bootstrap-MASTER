package fr.trxyy.alternative.bootstrap;

import java.awt.GraphicsDevice;
import java.awt.geom.RoundRectangle2D;
import java.io.IOException;
import javax.swing.JFrame;

public class Home extends JFrame {

	private static final long serialVersionUID = 2047851418739459065L;

	public Home() throws IOException {
		this.setTitle("MajestyLauncher");
		this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		this.setUndecorated(true);
		this.setSize(BootPanel.W, BootPanel.H);
		this.setLocationRelativeTo(null);
		// Coins arrondis quand le syst\u00e8me sait d\u00e9couper une fen\u00eatre, sinon fen\u00eatre rectangulaire
		try {
			GraphicsDevice device = this.getGraphicsConfiguration().getDevice();
			if (device.isWindowTranslucencySupported(GraphicsDevice.WindowTranslucency.PERPIXEL_TRANSPARENT)) {
				this.setShape(new RoundRectangle2D.Double(0, 0, BootPanel.W, BootPanel.H, 26, 26));
			}
		} catch (Throwable ignored) {
			// fen\u00eatre rectangulaire
		}
		BootPanel boot = new BootPanel(this);
		this.setContentPane(boot);
		this.setIconImage(BootstrapConstants.getResourceLocation().loadImageAWT("favicon.png"));
		this.setVisible(true);
		boot.start();
	}

	public static void main(String[] args) throws IOException {
		new Home();
	}
}
