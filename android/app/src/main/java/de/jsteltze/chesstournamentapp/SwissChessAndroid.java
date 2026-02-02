package de.jsteltze.chesstournamentapp;

import android.app.Activity;
import android.os.Environment;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;

import javafo.api.JaVaFoApi;

public class SwissChessAndroid {

    public static String initTournament(Activity activity, String trfFileContent) {
        try {
            File f = new File(activity.getCacheDir(), "tournament.trf");
            BufferedWriter writer = new BufferedWriter(new FileWriter(f));
            writer.write(trfFileContent);
            writer.close();
            String response = JaVaFoApi.exec(1000, new FileInputStream(f));
            f.delete();
            return response;
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public static String exportToFile(Activity activity, String content, String fileName) {
        try {
            File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs();
            }
            File file = new File(downloadsDir, fileName);
            BufferedWriter writer = new BufferedWriter(new FileWriter(file));
            writer.write(content);
            writer.close();
            return file.getAbsolutePath();
        } catch (IOException e) {
            return "Error: " + e.getMessage();
        }
    }
}