package fr.trxyy.alternative.bootstrap;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Cursor;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.GradientPaint;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Point;
import java.awt.RadialGradientPaint;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.Shape;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Point2D;
import java.awt.geom.RoundRectangle2D;
import java.awt.image.BufferedImage;
import java.io.InputStream;
import java.util.Locale;

import javax.swing.JPanel;
import javax.swing.Timer;

/**
 * Fen\u00eatre du bootstrap, aux couleurs du launcher : logo, \u00e9tape en cours en clair et barre de
 * progression (anim\u00e9e tant que la dur\u00e9e est inconnue). Se d\u00e9place en la faisant glisser.
 */
public final class BootPanel extends JPanel {
	private static final long serialVersionUID = 3251187257756876659L;

	static final int W = 440, H = 250;
	private static final Color ORANGE = new Color(0xFF9A1F);
	private static final Color ORANGE_DARK = new Color(0xFF6A00);
	private static final Rectangle CLOSE = new Rectangle(W - 40, 14, 26, 26);

	private final Downloader downloader;
	private final BufferedImage logo;
	private final Font titleFont, textFont, smallFont;
	private final long startedAt = System.currentTimeMillis();

	// \u00c9crits par le t\u00e9l\u00e9chargement (autre fil), lus au dessin
	private volatile String status = texte("RECHERCHE");
	private volatile String detail = "";
	private volatile double progress = -1; // -1 : dur\u00e9e inconnue, barre anim\u00e9e

	private double shown; // progression affich\u00e9e, liss\u00e9e
	private boolean closeHover;
	private Point dragFrom;

	public BootPanel(final Home home) {
		this.setOpaque(true);
		this.setBackground(new Color(0x16131C));
		this.logo = BootstrapConstants.getResourceLocation().loadImageAWT("launcher.png");
		Font base = loadFont("Comfortaa-Regular.ttf");
		this.titleFont = base.deriveFont(Font.BOLD, 23F);
		this.textFont = base.deriveFont(14F);
		this.smallFont = base.deriveFont(11.5F);
		this.downloader = new Downloader(this);

		MouseAdapter mouse = new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				dragFrom = CLOSE.contains(e.getPoint()) ? null : e.getPoint();
			}

			@Override
			public void mouseReleased(MouseEvent e) {
				if (CLOSE.contains(e.getPoint()) && dragFrom == null) {
					System.exit(0);
				}
			}

			@Override
			public void mouseDragged(MouseEvent e) {
				if (dragFrom != null) {
					Point p = home.getLocation();
					home.setLocation(p.x + e.getX() - dragFrom.x, p.y + e.getY() - dragFrom.y);
				}
			}

			@Override
			public void mouseMoved(MouseEvent e) {
				boolean hover = CLOSE.contains(e.getPoint());
				if (hover != closeHover) {
					closeHover = hover;
					setCursor(Cursor.getPredefinedCursor(hover ? Cursor.HAND_CURSOR : Cursor.DEFAULT_CURSOR));
				}
			}
		};
		this.addMouseListener(mouse);
		this.addMouseMotionListener(mouse);
	}

	/** Lance l'animation et la v\u00e9rification du launcher (une fois la fen\u00eatre affich\u00e9e). */
	void start() {
		new Timer(33, e -> {
			if (progress >= 0) {
				shown += (progress - shown) * 0.22;
			}
			repaint();
		}).start();
		Thread t = new Thread(downloader::run, "MajestyLauncher-Bootstrap");
		t.start();
	}

	/** Nouvelle \u00e9tape, de dur\u00e9e inconnue. */
	void status(String step) {
		this.status = texte(step);
		this.detail = "";
		this.progress = -1;
	}

	/** \u00c9tape termin\u00e9e (barre pleine). */
	void done(String step) {
		this.status = texte(step);
		this.detail = "";
		this.progress = 100;
	}

	/** Progression du t\u00e9l\u00e9chargement. */
	void downloaded(long read, long total) {
		if (total <= 0) {
			this.detail = String.format(Locale.FRANCE, "%.1f Mo", read / 1048576.0);
			return;
		}
		this.progress = Math.min(100, read * 100.0 / total);
		this.detail = String.format(Locale.FRANCE, "%.1f Mo sur %.1f Mo", read / 1048576.0, total / 1048576.0);
	}

	private static String texte(String step) {
		switch (step) {
			case "RECHERCHE": return "Recherche de mises \u00e0 jour\u2026";
			case "TELECHARGEMENT": return "T\u00e9l\u00e9chargement du launcher\u2026";
			case "TELECHARGEMENT_MAJ": return "T\u00e9l\u00e9chargement de la mise \u00e0 jour\u2026";
			case "VERIFICATION": return "V\u00e9rification de la signature\u2026";
			case "A_JOUR": return "Le launcher est \u00e0 jour";
			case "LANCEMENT": return "Lancement du launcher\u2026";
			default: return step;
		}
	}

	private static Font loadFont(String name) {
		try (InputStream in = BootPanel.class.getResourceAsStream("/resources/" + name)) {
			if (in != null) {
				return Font.createFont(Font.TRUETYPE_FONT, in);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return new Font(Font.SANS_SERIF, Font.PLAIN, 12);
	}

	@Override
	protected void paintComponent(Graphics graphics) {
		Graphics2D g = (Graphics2D) graphics.create();
		g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
		g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
		g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
		g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
		g.setRenderingHint(RenderingHints.KEY_STROKE_CONTROL, RenderingHints.VALUE_STROKE_PURE);

		// Fond : d\u00e9grad\u00e9 sombre et lueur orange derri\u00e8re le logo, comme l'accueil du launcher
		g.setPaint(new GradientPaint(0, 0, new Color(0x1F1A26), 0, H, new Color(0x110F15)));
		g.fillRect(0, 0, W, H);
		g.setPaint(new RadialGradientPaint(new Point2D.Float(64, 66), 230, new float[] { 0F, 1F },
				new Color[] { new Color(255, 140, 30, 60), new Color(255, 140, 30, 0) }));
		g.fillRect(0, 0, W, H);
		g.setColor(new Color(255, 255, 255, 26));
		g.setStroke(new BasicStroke(1F));
		g.draw(new RoundRectangle2D.Double(0.5, 0.5, W - 1, H - 1, 26, 26));

		// Logo rond et titre
		if (this.logo != null) {
			Shape old = g.getClip();
			g.clip(new Ellipse2D.Double(28, 30, 72, 72));
			g.drawImage(this.logo, 28, 30, 72, 72, null);
			g.setClip(old);
			g.setColor(new Color(255, 154, 31, 150));
			g.setStroke(new BasicStroke(2F));
			g.draw(new Ellipse2D.Double(28, 30, 72, 72));
		}
		g.setFont(this.titleFont);
		g.setColor(Color.WHITE);
		g.drawString("Majesty", 118, 64);
		int w = g.getFontMetrics().stringWidth("Majesty");
		g.setColor(ORANGE);
		g.drawString("Launcher", 118 + w, 64);
		g.setFont(this.smallFont);
		g.setColor(new Color(255, 255, 255, 120));
		g.drawString("Pr\u00e9paration du launcher MajestyCraft", 118, 88);

		// \u00c9tape en cours et pourcentage
		g.setFont(this.textFont);
		g.setColor(new Color(255, 255, 255, 232));
		g.drawString(this.status, 28, 158);
		if (this.progress >= 0) {
			String pct = Math.round(this.shown) + " %";
			FontMetrics fm = g.getFontMetrics();
			g.setColor(ORANGE);
			g.drawString(pct, W - 28 - fm.stringWidth(pct), 158);
		}

		// Barre de progression arrondie
		int bx = 28, by = 172, bw = W - 56, bh = 8;
		RoundRectangle2D track = new RoundRectangle2D.Double(bx, by, bw, bh, bh, bh);
		g.setColor(new Color(255, 255, 255, 22));
		g.fill(track);
		g.setPaint(new GradientPaint(bx, 0, ORANGE, bx + bw, 0, ORANGE_DARK));
		if (this.progress < 0) {
			double t = ((System.currentTimeMillis() - this.startedAt) % 1500) / 1500.0;
			double ease = t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
			double seg = bw * 0.3;
			double x = bx - seg + (bw + seg) * ease;
			Shape old = g.getClip();
			g.clip(track);
			g.fill(new RoundRectangle2D.Double(x, by, seg, bh, bh, bh));
			g.setClip(old);
		} else if (this.shown > 0.5) {
			g.fill(new RoundRectangle2D.Double(bx, by, Math.max(bh, bw * this.shown / 100.0), bh, bh, bh));
		}

		// D\u00e9tail (Mo t\u00e9l\u00e9charg\u00e9s) et pied
		g.setFont(this.smallFont);
		g.setColor(new Color(255, 255, 255, 115));
		g.drawString(this.detail, 28, 202);
		g.setColor(new Color(255, 255, 255, 70));
		g.drawString("majestycraft.com", 28, H - 22);

		// Croix de fermeture
		if (this.closeHover) {
			g.setColor(new Color(255, 255, 255, 24));
			g.fill(new RoundRectangle2D.Double(CLOSE.x, CLOSE.y, CLOSE.width, CLOSE.height, 10, 10));
		}
		g.setColor(new Color(255, 255, 255, this.closeHover ? 230 : 140));
		g.setStroke(new BasicStroke(1.6F, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		int cx = CLOSE.x + CLOSE.width / 2, cy = CLOSE.y + CLOSE.height / 2;
		g.drawLine(cx - 5, cy - 5, cx + 5, cy + 5);
		g.drawLine(cx + 5, cy - 5, cx - 5, cy + 5);
		g.dispose();
	}
}
