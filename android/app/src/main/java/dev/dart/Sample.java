package dev.dart;

import android.app.Activity;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Arrays;
import java.util.Locale;

import javafo.api.JaVaFoApi;

public class Sample {
    public static int sum(int a, int b) {
        return a + b;
    }

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
}