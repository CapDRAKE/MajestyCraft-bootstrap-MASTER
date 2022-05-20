package fr.trxyy.alternative.bootstrap;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.image.BufferedImage;

import javax.swing.JPanel;

import fr.trxyy.alternative.alternative_api.utils.FontLoader;
import fr.trxyy.alternative.bootstrap.ui.JCircleProgressBar;

public final class BootPanel extends JPanel {
	private static final long serialVersionUID = 3251187257756876659L;
	public static JCircleProgressBar progressBar = new JCircleProgressBar();
	public Downloader launcherDownloader;
	private BufferedImage logoIcon;

	public BootPanel(final Home home) {
		this.setLayout(new BorderLayout());
		/** ================= ON RECUPERE LE LOGO DU SERVEUR ================= **/
		this.logoIcon = BootstrapConstants.getResourceLocation().loadImageAWT("launcher.png");
		this.setFont(FontLoader.loadFontAWT("minecraft.ttf", "Minecraftia", 20F));
		this.launcherDownloader = new Downloader(home);
		this.add(progressBar);
		/** ================= DEMARRAGE DE LA MISE A JOUR ================= **/
		this.updateJar();
	}
	
	private void updateJar() {
		Thread thread = new Thread() {
			public void run() {
				launcherDownloader.run();
			}
		};
		thread.start();
	}
	
	public void paint(Graphics g) {
		super.paint(g);
		if (this.logoIcon != null) {
			g.drawImage(this.logoIcon, 70, 20, 160, 160, this);
		}
		g.setColor(Color.orange);
		String percentageToDisplay = String.valueOf(launcherDownloader.getProgress()) + "%";
		g.drawString(percentageToDisplay, 415 - g.getFontMetrics(FontLoader.loadFontAWT("minecraft.ttf", "Minecraftia", 30F)).stringWidth(percentageToDisplay) / 2 - 103, 105);
	}

	public static JCircleProgressBar getProgressBar() {
		return progressBar;
	}
}
