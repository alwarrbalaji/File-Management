// src/main/java/com/filemanager/model/FileResponse.java
package com.filemanager.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO returned by GET /api/files.
 * This is what the Flutter app's FileItem.fromJson() deserializes.
 *
 * JSON shape:
 * {
 *   "name": "report.pdf",
 *   "size": 204800,
 *   "lastModified": "2024-06-15T10:30:00"
 * }
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FileResponse {

    /** Original file name with extension (e.g. "report.pdf") */
    private String name;

    /** File size in bytes */
    private long size;

    /**
     * Last modified timestamp as an ISO-8601 string.
     * e.g. "2024-06-15T10:30:00"
     * Flutter's DateTime.tryParse() handles this format natively.
     */
    private String lastModified;
}