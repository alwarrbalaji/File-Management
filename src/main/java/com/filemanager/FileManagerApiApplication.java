// src/main/java/com/filemanager/FileManagerApiApplication.java
package com.filemanager;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class FileManagerApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(FileManagerApiApplication.class, args);
        System.out.println("\n========================================");
        System.out.println("  File Manager API is running!");
        System.out.println("  URL: http://localhost:8080");
        System.out.println("  Endpoints:");
        System.out.println("    GET    /api/files");
        System.out.println("    POST   /api/files/upload");
        System.out.println("    GET    /api/files/download/{filename}");
        System.out.println("    DELETE /api/files/delete/{filename}");
        System.out.println("========================================\n");
    }
}