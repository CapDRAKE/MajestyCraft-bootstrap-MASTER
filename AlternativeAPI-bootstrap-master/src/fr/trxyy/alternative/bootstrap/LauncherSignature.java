package fr.trxyy.alternative.bootstrap;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.RSAPublicKeySpec;
import java.util.Base64;

/**
 * Verifie qu'un launcher telecharge a bien ete publie par MajestyCraft : signature RSA
 * (SHA-256) de tout le fichier, faite avec la cle privee qui reste sur le PC de l'editeur
 * (deploy/signature-launcher.ps1 du depot du launcher). Un pirate qui prendrait la main sur le site ne pourrait
 * pas diffuser un faux launcher : sans signature valide, la mise a jour n'est pas installee.
 */
public final class LauncherSignature {

	/** Cle publique RSA 3072 bits : module et exposant (Base64, octets big-endian). */
	private static final String MODULUS = "zj1kJidaXhpKL19rJGk89DhrEUegjp0E00xy1Sk+gkJYHf1VV0mfAU+ubSwGR4QuEXla2hmHo2RTxJOYdURxI0FAk6vb97VssYW8UxSr403rweYXj23sxWYeQ75UUtOYXNEom/qemJpoQ+UksVz9fwB0YVGC46xfukDnw32aLw25OZZ7H4dd7gZ2EXCA16fS4PanLvuucWgFUtyf61Avy5JGmvwIGvpXHaOXVCepMmqP2bMGnD0lnjbszq/8JBAnP4+U8NxkAagoNIR7RrsJKDpr6cJOOfXdx+9baEndBJx2juG1w5G0xzpxZKNsWR6PtjHgzLQrOrYgG83X66ypZUWnW7CTuTRehbavcqwb/tKESpAHKfJuhrzUcu9dHIy1elsR/W+5H05B2ozNIlLxH+oW4cWh1+KY7NY18z3XofpsNVvS4zZ2XiD0ftKJWFqzDh6fiSUAUrqHBCRG4D68BlxxVvjVd7pUAjLVjLldyTQXHIULZlTnK3p8YCsp0yuZ";
	private static final String EXPONENT = "AQAB";

	private LauncherSignature() {
	}

	/**
	 * @param jar le launcher telecharge
	 * @param md5 l'empreinte annoncee par launcher.json
	 * @param signatureBase64 la signature annoncee par launcher.json
	 * @return true si le fichier est complet (MD5) et signe par MajestyCraft
	 */
	public static boolean isValid(File jar, String md5, String signatureBase64) {
		if (md5 == null || md5.trim().isEmpty() || signatureBase64 == null || signatureBase64.trim().isEmpty()) {
			System.out.println("launcher.json sans empreinte ou sans signature");
			return false;
		}
		try {
			Base64.Decoder b64 = Base64.getDecoder();
			PublicKey key = KeyFactory.getInstance("RSA").generatePublic(new RSAPublicKeySpec(
					new BigInteger(1, b64.decode(MODULUS)), new BigInteger(1, b64.decode(EXPONENT))));
			Signature signature = Signature.getInstance("SHA256withRSA");
			signature.initVerify(key);
			MessageDigest digest = MessageDigest.getInstance("MD5");
			try (InputStream in = new FileInputStream(jar)) {
				byte[] buffer = new byte[65536];
				int read;
				while ((read = in.read(buffer)) > 0) {
					signature.update(buffer, 0, read);
					digest.update(buffer, 0, read);
				}
			}
			String actualMd5 = String.format("%032x", new BigInteger(1, digest.digest()));
			if (!actualMd5.equalsIgnoreCase(md5.trim())) {
				System.out.println("Launcher telecharge incomplet ou abime (MD5 " + actualMd5 + ")");
				return false;
			}
			boolean ok = signature.verify(b64.decode(signatureBase64.trim()));
			System.out.println(ok ? "Signature du launcher valide" : "Signature du launcher INVALIDE");
			return ok;
		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}
}
