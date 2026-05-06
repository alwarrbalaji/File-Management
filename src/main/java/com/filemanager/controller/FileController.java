// src/main/java/com/filemanager/controller/FileController.java
package com.filemanager.controller;

import com.filemanager.model.ApiResponse;
import com.filemanager.model.FileResponse;
import com.filemanager.service.FileService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.List;

/**
 * REST Controller — exposes all 4 file management endpoints.
 *
 *  GET    /api/files                      → list all files
 *  POST   /api/files/upload               → upload a file
 *  GET    /api/files/download/{filename}  → download a file
 *  DELETE /api/files/delete/{filename}    → delete a file
 */
@Slf4j
@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileController {

    private final FileService fileService;

    // =========================================================================
    //  1. GET /api/files
    //     Returns a JSON array of all stored files.
    //
    //  Response 200:
    //  [
    //    { "name": "report.pdf", "size": 204800, "lastModified": "2024-06-15T10:30:00" },
    //    { "name": "photo.jpg",  "size": 1048576, "lastModified": "2024-06-14T08:00:00" }
    //  ]
    // =========================================================================
    @GetMapping
    public ResponseEntity<?> listFiles() {
        try {
            List<FileResponse> files = fileService.listAllFiles();
            log.debug("Listing {} file(s)", files.size());
            return ResponseEntity.ok(files);
        } catch (IOException e) {
            log.error("Failed to list files", e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Could not list files: " + e.getMessage()));
        }
    }

    // =========================================================================
    //  2. POST /api/files/upload
    //     Accepts a multipart/form-data request with field name "file".
    //
    //  Request: multipart form-data, field: file
    //  Response 200: { "success": true,  "message": "File uploaded: report.pdf" }
    //  Response 400: { "success": false, "message": "No file provided." }
    //  Response 500: { "success": false, "message": "Upload failed: ..." }
    // =========================================================================
    @PostMapping("/upload")
    public ResponseEntity<ApiResponse> uploadFile(
            @RequestParam("file") MultipartFile file) {

        // Guard: reject empty uploads
        if (file.isEmpty()) {
            return ResponseEntity
                .badRequest()
                .body(ApiResponse.error("No file provided or the file is empty."));
        }

        try {
            String savedName = fileService.storeFile(file);
            log.info("Uploaded: {} ({} bytes)", savedName, file.getSize());
            return ResponseEntity.ok(
                ApiResponse.ok("File uploaded successfully: " + savedName));
        } catch (IOException e) {
            log.error("Upload failed for: {}", file.getOriginalFilename(), e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Upload failed: " + e.getMessage()));
        }
    }

    // =========================================================================
    //  3. GET /api/files/download/{filename}
    //     Streams the requested file as a binary download.
    //
    //  Response 200: binary file stream with Content-Disposition header
    //  Response 404: { "success": false, "message": "File not found: ..." }
    //  Response 500: { "success": false, "message": "Download failed: ..." }
    // =========================================================================
    @GetMapping("/download/{filename:.+}")
    public ResponseEntity<?> downloadFile(
            @PathVariable String filename) {

        try {
            Resource resource = fileService.loadFileAsResource(filename);

            // Determine MIME type — default to octet-stream for unknown types
            String contentType = "application/octet-stream";

            log.info("Downloading: {}", filename);

            return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                // "attachment" forces the browser / app to download rather than display
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + resource.getFilename() + "\"")
                .body(resource);

        } catch (FileNotFoundException e) {
            log.warn("Download requested for missing file: {}", filename);
            return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error("File not found: " + filename));
        } catch (Exception e) {
            log.error("Download failed for: {}", filename, e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Download failed: " + e.getMessage()));
        }
    }

    // =========================================================================
    //  4. DELETE /api/files/delete/{filename}
    //     Permanently removes the file from the server storage.
    //
    //  Response 200: { "success": true,  "message": "Deleted: report.pdf" }
    //  Response 404: { "success": false, "message": "File not found: ..." }
    //  Response 500: { "success": false, "message": "Delete failed: ..." }
    // =========================================================================
    @DeleteMapping("/delete/{filename:.+}")
    public ResponseEntity<ApiResponse> deleteFile(
            @PathVariable String filename) {

        try {
            boolean deleted = fileService.deleteFile(filename);

            if (deleted) {
                log.info("Deleted: {}", filename);
                return ResponseEntity.ok(
                    ApiResponse.ok("Deleted successfully: " + filename));
            } else {
                return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("File not found: " + filename));
            }

        } catch (IOException e) {
            log.error("Delete failed for: {}", filename, e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Delete failed: " + e.getMessage()));
        }
    }
}