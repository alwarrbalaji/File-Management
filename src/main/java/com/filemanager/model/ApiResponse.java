// src/main/java/com/filemanager/model/ApiResponse.java
package com.filemanager.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Generic JSON wrapper for success and error responses.
 *
 * Success: { "success": true,  "message": "File uploaded successfully." }
 * Error:   { "success": false, "message": "File not found: report.pdf"  }
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse {

    private boolean success;
    private String message;

    // ── Static factory helpers ─────────────────────────────────────────────
    public static ApiResponse ok(String message) {
        return new ApiResponse(true, message);
    }

    public static ApiResponse error(String message) {
        return new ApiResponse(false, message);
    }
}