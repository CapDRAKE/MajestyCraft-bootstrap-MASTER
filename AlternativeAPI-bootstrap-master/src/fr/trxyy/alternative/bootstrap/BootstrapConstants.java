package fr.trxyy.alternative.bootstrap;

import java.awt.Color;
import java.awt.Paint;
import java.io.File;

import fr.trxyy.alternative.alternative_api.utils.ResourceLocation;
import fr.trxyy.alternative.alternative_api.utils.file.GameUtils;

public class BootstrapConstants {
	/** ========== DOSSIER D'INSTALLATION ========== **/
	public static File WORKING_DIRECTORY = GameUtils.getWorkingDirectory("majestycraft");
	/** ========== RESOURCE LOCATION ========== **/
	public static ResourceLocation RESOURCE_LOCATION = new ResourceLocation();
	/** ========== OU SE SITUERA LE LAUNCHER ========== **/
	public static File LAUNCHER = new File(WORKING_DIRECTORY, "MajestyCraft.jar");
	/** ========== URL DU FICHIER launcher.cfg AVEC LE MD5 ========== **/
	public static String MD5_URL = "https://majestycraft.com/minecraft/bootstrap/launcher.cfg";
	/** ========== URL DU LAUNCHER.JAR ========== **/
	public static String LAUNCHER_URL = "https://majestycraft.com/minecraft/bootstrap/MajestyCraft.jar";
	/** ========== COULEUR DU CERCLE REMPLIS ========== **/
	public static Paint color = Color.orange;

	public static File getWorkingDirectory() {
		return WORKING_DIRECTORY;
	}

	public static File getLauncherFile() {
		return LAUNCHER;
	}

	public static String getHashUrl() {
		return MD5_URL;
	}

	public static String getLauncherUrl() {
		return LAUNCHER_URL;
	}
	
	public static ResourceLocation getResourceLocation() {
		return RESOURCE_LOCATION;
	}

	public static Paint getFillColor() {
		return color ;
	}

}
