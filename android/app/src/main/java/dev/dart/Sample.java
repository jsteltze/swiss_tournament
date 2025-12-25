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

    public static String initTournament(Activity activity, String tournamentId, int[] playerRatings, int numRounds) {
        try {
            Arrays.sort(playerRatings);
            File f = new File(activity.getCacheDir(), tournamentId);
            BufferedWriter writer = new BufferedWriter(new FileWriter(f));
            writer.write("012 " + tournamentId + "\n");
            writer.write("022 City\n");
            writer.write("032 GER\n");
            writer.write("102 Arbiter\n");
            writer.write("XXR " + numRounds + "\n");
            for (int i = 1; i <= playerRatings.length; i++) {
                String line = String.format(Locale.ENGLISH, "001 %4d m    Playername                        %4d GER     2212072 1981        0.0 %4d\n", i, playerRatings[i - 1], i);
                writer.write(line);
            }
            writer.close();

            return JaVaFoApi.exec(1000, new FileInputStream(f));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }



    }
}