// src/main/java/com/filemanager/exception/GlobalExceptionHandler.java
package com.filemanager.exception;

import com.filemanager.model.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

/**
 * Catches any unhandled exceptions across all controllers
 * and returns a clean JSON ApiResponse instead of an HTML error page.
 *
 * This is what the Flutter app will see if something goes wrong
 * that isn't explicitly handled in FileController.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Triggered when the uploaded file exceeds spring.servlet.multipart.max-file-size.
     * Returns HTTP 413 Payload Too Large.
     */
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse> handleMaxSizeException(
            MaxUploadSizeExceededException ex) {
        log.warn("Upload rejected — file too large: {}", ex.getMessage());
        return ResponseEntity
            .status(HttpStatus.PAYLOAD_TOO_LARGE)
            .body(ApiResponse.error(
                "File is too large. Maximum allowed size is 500 MB. "
                + "You can increase this in application.properties."));
    }

    /**
     * Catch-all for any other unexpected runtime exceptions.
     * Returns HTTP 500 Internal Server Error.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse> handleGenericException(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity
            .status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error(
                "An unexpected server error occurred: " + ex.getMessage()));
    }
}