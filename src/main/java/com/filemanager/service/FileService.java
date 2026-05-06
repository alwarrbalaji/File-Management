// src/main/java/com/filemanager/service/FileService.java
package com.filemanager.service;

import com.filemanager.model.FileResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.PostConstruct;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * All file system operations live here.
 * The controller stays thin — it just delegates to this service.
 */
@Slf4j
@Service
public class FileService {

    // Injected from application.properties → file.upload-dir
    @Value("${file.upload-dir}")
    private String uploadDirStr;

    private Path uploadDir;

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    // ── Initialise storage directory on startup ────────────────────────────
    @PostConstruct
    public void init() {
        try {
            uploadDir = Paths.get(uploadDirStr).toAbsolutePath().normalize();
            Files.createDirectories(uploadDir);
            log.info("File storage directory: {}", uploadDir);
        } catch (IOException e) {
            throw new RuntimeException(
                "Could not create upload directory: " + uploadDirStr, e);
        }
    }

    // ── 1. List all files ──────────────────────────────────────────────────
    /**
     * Returns metadata for every file in the storage directory.
     * Sub-directories are excluded — only flat files are listed.
     */
    public List<FileResponse> listAllFiles() throws IOException {
        try (Stream<Path> stream = Files.list(uploadDir)) {
            return stream
                .filter(Files::isRegularFile) // exclude sub-directories
                .map(this::toFileResponse)
                .sorted((a, b) -> b.getLastModified().compareTo(a.getLastModified()))
                .collect(Collectors.toList());
        }
    }

    // ── 2. Store an uploaded file ──────────────────────────────────────────
    /**
     * Saves the multipart file to the storage directory.
     * Cleans the filename to prevent path-traversal attacks.
     *
     * @return the final saved filename
     */
    public String storeFile(MultipartFile file) throws IOException {
        // Clean the original filename
        String originalName = StringUtils.cleanPath(
            file.getOriginalFilename() != null
                ? file.getOriginalFilename()
                : "unnamed_file"
        );

        // Guard against path traversal (e.g. "../../etc/passwd")
        if (originalName.contains("..")) {
            throw new IOException("Invalid filename: " + originalName);
        }

        // If a file with that name already exists, add a numeric suffix
        Path targetPath = resolveUniqueTarget(originalName);

        Files.copy(file.getInputStream(), targetPath,
                   StandardCopyOption.REPLACE_EXISTING);

        log.info("Stored file: {} ({} bytes)", targetPath.getFileName(),
                 file.getSize());
        return targetPath.getFileName().toString();
    }

    // ── 3. Load a file as a downloadable Resource ──────────────────────────
    /**
     * Resolves the filename to a Spring Resource that can be streamed
     * directly to the HTTP response.
     */
    public Resource loadFileAsResource(String filename)
            throws FileNotFoundException, MalformedURLException {

        Path filePath = uploadDir.resolve(filename).normalize();

        // Ensure the resolved path is still inside the upload directory
        if (!filePath.startsWith(uploadDir)) {
            throw new FileNotFoundException(
                "Access denied — path traversal detected: " + filename);
        }

        Resource resource = new UrlResource(filePath.toUri());

        if (resource.exists() && resource.isReadable()) {
            return resource;
        }

        throw new FileNotFoundException("File not found or unreadable: " + filename);
    }

    // ── 4. Delete a file ───────────────────────────────────────────────────
    /**
     * Permanently deletes the file from the storage directory.
     *
     * @return true if deleted, false if the file didn't exist
     */
    public boolean deleteFile(String filename) throws IOException {
        Path filePath = uploadDir.resolve(filename).normalize();

        // Guard against path traversal
        if (!filePath.startsWith(uploadDir)) {
            throw new IOException(
                "Access denied — path traversal detected: " + filename);
        }

        boolean deleted = Files.deleteIfExists(filePath);
        if (deleted) {
            log.info("Deleted file: {}", filename);
        } else {
            log.warn("Delete attempted but file not found: {}", filename);
        }
        return deleted;
    }

    // ── Private helpers ────────────────────────────────────────────────────

    /** Convert a Path to the FileResponse DTO. */
    private FileResponse toFileResponse(Path path) {
        try {
            long size = Files.size(path);
            LocalDateTime lastMod = LocalDateTime.ofInstant(
                Files.getLastModifiedTime(path).toInstant(),
                ZoneId.systemDefault()
            );
            return new FileResponse(
                path.getFileName().toString(),
                size,
                lastMod.format(FORMATTER)
            );
        } catch (IOException e) {
            log.warn("Could not read metadata for file: {}", path, e);
            return new FileResponse(path.getFileName().toString(), 0L,
                                    LocalDateTime.now().format(FORMATTER));
        }
    }

    /**
     * If "report.pdf" already exists, returns a path like "report_1.pdf",
     * "report_2.pdf", etc.
     */
    private Path resolveUniqueTarget(String filename) {
        Path target = uploadDir.resolve(filename);
        if (!Files.exists(target)) return target;

        String name = filename;
        String ext  = "";
        int dotIdx = filename.lastIndexOf('.');
        if (dotIdx > 0) {
            name = filename.substring(0, dotIdx);
            ext  = filename.substring(dotIdx); // includes the dot
        }

        int counter = 1;
        while (Files.exists(target)) {
            target = uploadDir.resolve(name + "_" + counter + ext);
            counter++;
        }
        return target;
    }
}