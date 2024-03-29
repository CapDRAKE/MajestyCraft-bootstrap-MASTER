package fr.trxyy.alternative.bootstrap;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.Timer;
import java.util.TimerTask;

import javax.swing.JFrame;
import javax.swing.JOptionPane;

import fr.trxyy.alternative.alternative_api.utils.file.FileUtil;

public class Downloader extends Thread {
	public JFrame frame;
	private int percentage;

	public Downloader(JFrame fra) {
		this.frame = fra;
	}

	public void run() {
		this.checkLocalMD5(BootstrapConstants.getLauncherFile());
		this.launch(BootstrapConstants.getLauncherFile());
	}


	public void update(File f, String u) {
		try {
			URL url = new URL(u.replace(" ", "%20"));
			HttpURLConnection connection = (HttpURLConnection) url.openConnection();
			connection.addRequestProperty("User-Agent", "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.124 Safari/537.36");
			if (!f.exists()) {
				f.getParentFile().mkdirs();
				f.createNewFile();
			}
			BufferedInputStream in = new BufferedInputStream(connection.getInputStream());
			FileOutputStream fos = new FileOutputStream(f);
			BufferedOutputStream bout = new BufferedOutputStream(fos, 1024);
			byte[] data = new byte[1024];
			int read = 0;

			long totalRead = 0;
			long fileSize = connection.getContentLength();

			while ((read = in.read(data, 0, 1024)) >= 0) {
				bout.write(data, 0, read);
				totalRead += read;
				this.percentage = (int) (totalRead * 100 / fileSize);
				BootPanel.getProgressBar().setValue(this.percentage);
				this.frame.repaint();

			}
			bout.close();
			in.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	private void checkLocalMD5(File launcher) {
		if (!launcher.exists()) {
			if(Downloader.netIsAvailable()) {
				update(launcher, BootstrapConstants.getLauncherUrl());
			}
			else {
				JOptionPane.showMessageDialog(null, "Connexion � internet impossible pour t�l�charger le launcher");
			}
		} else {
			String localMD5 = FileUtil.getMD5(launcher);
			if(Downloader.netIsAvailable()) {
				String hostMD5 = FileUtil.readMD5(BootstrapConstants.getHashUrl());
				if (!localMD5.equals(hostMD5)) {
					update(launcher, BootstrapConstants.getLauncherUrl());
				}
			}
			else {
				JOptionPane.showMessageDialog(null, "Attention, vous �tes en mode offline. Une mise � jour pourrait �tre disponible.\nSi le launcher ne d�marre pas, merci de vous connecter � internet.");
			}
		}
	}
	
	public void launch(File f) {
		ProcessBuilder pb = new ProcessBuilder(new String[] { "java", "-jar", f.getAbsolutePath() });
		try {
			System.out.println("test");
			pb.start();
			exitProperly();
		} catch (Exception e) {
			e.printStackTrace();
			JOptionPane.showMessageDialog(null, e.getMessage());
			exitProperly();
		}
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
