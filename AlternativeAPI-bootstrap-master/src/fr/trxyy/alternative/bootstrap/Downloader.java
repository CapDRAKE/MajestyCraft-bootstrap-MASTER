package fr.trxyy.alternative.bootstrap;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.nio.charset.StandardCharsets;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.Timer;
import java.util.TimerTask;

import javax.swing.JFrame;
import javax.swing.JOptionPane;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import fr.trxyy.alternative.alternative_api.utils.file.FileUtil;

public class Downloader extends Thread {
	public JFrame frame;
	private int percentage;

	public Downloader(JFrame fra) {
		this.frame = fra;
	}

	public void run() {
		File launcher = BootstrapConstants.getLauncherFile();
		this.checkLocalMD5(launcher);
		if (launcher.isFile()) {
			this.launch(launcher);
		} else {
			exitProperly();
		}
	}

	/** Empreinte et signature du launcher en ligne, lues dans launcher.json. */
	static final class RemoteInfo {
		String md5 = "";
		String sig = "";
	}

	/**
	 * Telecharge le launcher dans un fichier temporaire et ne remplace l'ancien que si le
	 * nouveau est complet et signe par MajestyCraft (LauncherSignature).
	 * @return true si le launcher a ete mis a jour
	 */
	public boolean update(File f, String u, RemoteInfo info) {
		File temp = new File(f.getParentFile(), f.getName() + ".part");
		try {
			URL url = new URL(u.replace(" ", "%20"));
			HttpURLConnection connection = (HttpURLConnection) url.openConnection();
			connection.addRequestProperty("User-Agent", "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.124 Safari/537.36");
			f.getParentFile().mkdirs();
			long fileSize = connection.getContentLength();
			try (BufferedInputStream in = new BufferedInputStream(connection.getInputStream());
				 BufferedOutputStream bout = new BufferedOutputStream(new FileOutputStream(temp), 65536)) {
				byte[] data = new byte[65536];
				int read;
				long totalRead = 0;
				while ((read = in.read(data, 0, data.length)) >= 0) {
					bout.write(data, 0, read);
					totalRead += read;
					if (fileSize > 0) {
						this.percentage = (int) (totalRead * 100 / fileSize);
						BootPanel.getProgressBar().setValue(this.percentage);
						this.frame.repaint();
					}
				}
			}
			if (!LauncherSignature.isValid(temp, info.md5, info.sig)) {
				temp.delete();
				return false;
			}
			try {
				Files.move(temp.toPath(), f.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
			} catch (AtomicMoveNotSupportedException e) {
				Files.move(temp.toPath(), f.toPath(), StandardCopyOption.REPLACE_EXISTING);
			}
			return true;
		} catch (Exception e) {
			e.printStackTrace();
			temp.delete();
			return false;
		}
	}

	private void checkLocalMD5(File launcher) {
		if (!Downloader.netIsAvailable()) {
			if (launcher.isFile()) {
				JOptionPane.showMessageDialog(null, "Attention, vous \u00eates en mode hors ligne. Une mise \u00e0 jour pourrait \u00eatre disponible.\nSi le launcher ne d\u00e9marre pas, merci de vous connecter \u00e0 Internet.");
			} else {
				JOptionPane.showMessageDialog(null, "Connexion \u00e0 Internet impossible pour t\u00e9l\u00e9charger le launcher.");
			}
			return;
		}
		RemoteInfo info = readRemoteInfo(BootstrapConstants.getHashUrl());
		if (info.md5.isEmpty()) {
			// launcher.json illisible : on garde la version installee plutot que d'installer
			// un fichier qu'on ne peut pas verifier
			if (!launcher.isFile()) {
				JOptionPane.showMessageDialog(null, "Le serveur de MajestyCraft ne r\u00e9pond pas correctement : le launcher ne peut pas \u00eatre t\u00e9l\u00e9charg\u00e9 pour l'instant.\nR\u00e9essaie dans quelques minutes.");
			}
			return;
		}
		if (launcher.isFile() && info.md5.equalsIgnoreCase(FileUtil.getMD5(launcher))) {
			return;
		}
		if (!update(launcher, BootstrapConstants.getLauncherUrl(), info)) {
			if (launcher.isFile()) {
				JOptionPane.showMessageDialog(null, "La mise \u00e0 jour du launcher n'a pas pu \u00eatre v\u00e9rifi\u00e9e : elle n'est pas install\u00e9e.\nLa version d\u00e9j\u00e0 install\u00e9e va d\u00e9marrer.");
			} else {
				JOptionPane.showMessageDialog(null, "Le launcher t\u00e9l\u00e9charg\u00e9 n'a pas pu \u00eatre v\u00e9rifi\u00e9 (fichier incomplet ou signature invalide) : il n'est pas install\u00e9.\nR\u00e9essaie plus tard ou contacte le support MajestyCraft.");
			}
		}
	}

	/**
	 * Lit launcher.json : {"md5": "...", "sig": "..."}. L'ancien format texte brut (une
	 * seule ligne contenant le hash) donne une empreinte sans signature, donc refusee.
	 */
	static RemoteInfo readRemoteInfo(String url) {
		RemoteInfo info = new RemoteInfo();
		String raw;
		try {
			URL target = new URL(url);
			HttpURLConnection connection = (HttpURLConnection) target.openConnection();
			connection.setRequestProperty("User-Agent", "MajestyCraft-Bootstrap");
			connection.setConnectTimeout(8000);
			connection.setReadTimeout(8000);

			StringBuilder sb = new StringBuilder();
			try (BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream(), StandardCharsets.UTF_8))) {
				String line;
				while ((line = in.readLine()) != null) {
					sb.append(line).append('\n');
				}
			}
			raw = sb.toString().trim();
		} catch (IOException e) {
			e.printStackTrace();
			return info;
		}

		try {
			JsonObject obj = JsonParser.parseString(raw).getAsJsonObject();
			if (obj.has("md5") && !obj.get("md5").isJsonNull()) {
				info.md5 = obj.get("md5").getAsString().trim();
			}
			if (obj.has("sig") && !obj.get("sig").isJsonNull()) {
				info.sig = obj.get("sig").getAsString().trim();
			}
		} catch (Exception ignored) {
			// Pas du JSON valide : ancien format texte brut (launcher.cfg)
			if (raw.matches("[0-9a-fA-F]{32}")) {
				info.md5 = raw;
			}
		}
		return info;
	}

	public void launch(File f) {
		ProcessBuilder pb = new ProcessBuilder(new String[] { currentJavaExecutable(), "-jar", f.getAbsolutePath() });
		try {
			pb.start();
			exitProperly();
		} catch (Exception e) {
			e.printStackTrace();
			JOptionPane.showMessageDialog(null, e.getMessage());
			exitProperly();
		}
	}

	/**
	 * Java qui execute le bootstrap (le Java portable avec JavaFX installe par le
	 * script). La commande "java" seule designait, sous Linux et macOS, le Java du
	 * systeme : souvent absent, ou en version 17/21 sans JavaFX, et le launcher ne
	 * demarrait pas. Sous Windows on garde java.exe, comme avant.
	 */
	private static String currentJavaExecutable() {
		File bin = new File(System.getProperty("java.home"), "bin");
		boolean windows = System.getProperty("os.name", "").toLowerCase().contains("win");
		File java = new File(bin, windows ? "java.exe" : "java");
		return java.isFile() ? java.getAbsolutePath() : "java";
	}

	private static void exitProperly() {
		(new Timer()).schedule(new TimerTask() {
			public void run() {
				System.exit(0);
			}
		}, 1500L);
	}

	public int getProgress() {
		return this.percentage;
	}

	private static boolean netIsAvailable() {
	    try {
	        final URL url = new URL("https://www.google.com");
	        final URLConnection conn = url.openConnection();
	        conn.connect();
	        conn.getInputStream().close();
	        System.out.println("ok");
	        return true;
	    } catch (MalformedURLException e) {
	        throw new RuntimeException(e);
	    } catch (IOException e) {
	        System.out.println(e);
	        return false;
	    }
	}
}
