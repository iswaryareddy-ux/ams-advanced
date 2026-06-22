package com.ams.util;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.Properties;

/**
 * Central JDBC connection helper for the Asset Management System.
 *
 * Reads connection settings from /WEB-INF/classes/db.properties so the
 * driver, URL, username and password can be changed without recompiling
 * any code (and so MySQL / Oracle can be swapped by editing one file).
 *
 * Example db.properties (MySQL):
 *   db.driver=com.mysql.cj.jdbc.Driver
 *   db.url=jdbc:mysql://localhost:3306/ams_db?useSSL=false&serverTimezone=UTC
 *   db.user=ams_user
 *   db.password=ams_password
 *
 * Example db.properties (Oracle):
 *   db.driver=oracle.jdbc.driver.OracleDriver
 *   db.url=jdbc:oracle:thin:@localhost:1521:xe
 *   db.user=ams_user
 *   db.password=ams_password
 */
public class DBConnection {

    private static final Properties props = new Properties();
    private static boolean driverLoaded = false;

    private static synchronized void loadConfig() {
        if (!props.isEmpty()) return;
        try (InputStream in = DBConnection.class.getClassLoader()
                .getResourceAsStream("db.properties")) {
            if (in == null) {
                throw new RuntimeException(
                    "db.properties not found on classpath (expected at WEB-INF/classes/db.properties)");
            }
            props.load(in);
        } catch (Exception e) {
            throw new RuntimeException("Unable to load db.properties", e);
        }
    }

    /**
     * Returns a new JDBC connection using the settings from db.properties.
     * Callers are responsible for closing the connection (use
     * try-with-resources).
     */
    public static Connection getConnection() throws Exception {
        loadConfig();
        if (!driverLoaded) {
            Class.forName(props.getProperty("db.driver"));
            driverLoaded = true;
        }
        return DriverManager.getConnection(
                props.getProperty("db.url"),
                props.getProperty("db.user"),
                props.getProperty("db.password"));
    }
}
