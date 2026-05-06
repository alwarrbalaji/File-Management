# 🚀 File Manager - Complete Setup & Deployment Guide

## **PROJECT OVERVIEW**

A hybrid **Spring Boot + Flutter** application for managing files across your local network.

**Features:**

- ✅ Upload files from phone to PC server
- ✅ Download files from server to phone
- ✅ List all stored files with metadata
- ✅ Delete files with confirmation dialogs
- ✅ Real-time upload/download progress tracking
- ✅ Material Design 3 UI with file type icons

**Architecture:**

```
Phone (Flutter)  ←→  WiFi Network  ←→  PC (Spring Boot Server)
192.168.X.X      [File Manager App]     localhost:8080
```

---

## **📋 PREREQUISITES**

### **For Backend (Java/Spring Boot)**

- ✅ Java 17+ installed
- ✅ Maven 3.8+ installed
- ✅ Windows/Linux/macOS PC

### **For Frontend (Flutter/Android)**

- ✅ Flutter 3.0+ installed
- ✅ Android SDK configured
- ✅ Connected Android device or emulator
- ✅ Same WiFi network as the PC

---

## **🔧 BACKEND SETUP (Spring Boot)**

### **Step 1: Configure File Storage Directory**

Edit: `src/main/resources/application.properties`

```properties
# Windows (default)
file.upload-dir=D:/FileStorage

# Or any other directory
file.upload-dir=C:/Users/YourName/Documents/FileStorage
file.upload-dir=/home/username/FileStorage  # Linux/macOS
```

The app will **auto-create** this directory if it doesn't exist.

### **Step 2: Build the Backend**

```bash
cd "d:\File Manager"
mvn clean install
```

Expected output:

```
[INFO] BUILD SUCCESS
[INFO] Total time: X.XXs
```

### **Step 3: Run the Spring Boot Server**

```bash
mvn spring-boot:run
```

Or use the VS Code task if configured.

**Expected output:**

```
─────────────────────────────────────────────────────
🚀 FILE MANAGER API STARTED
────────────────────────────────────────────────────
Server port:......... 8080
Upload directory:.... D:\FileStorage
Max file size:....... 500 MB
CORS policy:......... Allow all origins (dev mode)
────────────────────────────────────────────────────
✓ Server running at: http://localhost:8080
✓ Ready to accept file uploads
─────────────────────────────────────────────────────
```

### **Step 4: Find Your PC's Local IP Address**

**Windows:**

```bash
ipconfig
```

Look for "IPv4 Address" under your active network adapter.
Example: `192.168.0.100`

**Linux/macOS:**

```bash
ip a
# or
ifconfig
```

Look for inet address (not 127.0.0.1 or ::1).

---

## **📱 FRONTEND SETUP (Flutter)**

### **Step 1: Update Server IP Address**

Edit: `lib/services/api_service.dart`

```dart
// Line 16 - Replace with YOUR PC's local IP
String _kBaseUrl = 'http://192.168.0.100:8080';  // ← Change IP here
```

**Example:**

```dart
String _kBaseUrl = 'http://192.168.1.50:8080';   // Windows PC
String _kBaseUrl = 'http://192.168.100.15:8080'; // Linux PC
```

### **Step 2: Run on Android Device/Emulator**

```bash
cd "d:\File Manager"
flutter pub get
flutter run
```

Or use VS Code's Flutter debugging tools.

### **Step 3: Test Connection**

When the app starts, you should see:

- ✅ Empty file list (if no files uploaded yet)
- ✅ "Upload File" button active
- ❌ If shows "Connection Failed" → Check IP address and WiFi connection

---

## **✅ VERIFICATION CHECKLIST**

### **Backend Tests**

- [ ] Server starts on `http://localhost:8080`
- [ ] GET `/api/files` returns empty array: `[]`
- [ ] Upload directory created successfully
- [ ] Upload directory is readable/writable

**Test with curl:**

```bash
curl http://localhost:8080/api/files
# Should return: []
```

### **Frontend Tests**

- [ ] Flutter app launches without errors
- [ ] App shows empty file list
- [ ] "Upload File" button works
- [ ] Can pick a file from device storage
- [ ] Upload progress shows
- [ ] File appears in server list
- [ ] Can download file back to device
- [ ] Can delete file with confirmation

---

## **🐛 TROUBLESHOOTING**

### **"Connection Failed" Error in App**

**Problem:** App shows WiFi icon error and says "Connection Failed"

**Solutions:**

1. **Verify IP Address:**
   - Run `ipconfig` (Windows) on your PC
   - Copy the IPv4 address (NOT 127.0.0.1)
   - Update `lib/services/api_service.dart` with correct IP

2. **Check WiFi Network:**
   - Both phone and PC must be on **same WiFi network**
   - Not connected via USB tethering
   - Not using guest network if blocked

3. **Check Firewall:**
   - Windows: Allow Java/Spring Boot through Windows Defender Firewall
   - Command: `netstat -an | find "8080"` to verify port is listening

4. **Verify Server is Running:**
   - Open browser: `http://localhost:8080/api/files`
   - Should display `[]` or file list
   - If blank, server not running

5. **Rebuild & Reinstall App:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### **"File Too Large" Error**

- Increase `spring.servlet.multipart.max-file-size` in `application.properties`
- Default: 500MB
- Example: Change to `1GB` for 1GB files
- Restart server after changes

### **Uploads Work, Downloads Fail**

- Check storage directory exists: `D:/FileStorage`
- Verify file permissions allow reading
- Restart app

### **Server Won't Start**

```
Error: Address already in use: 8080
```

Another app is using port 8080:

```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux/macOS
lsof -i :8080
kill -9 <PID>
```

---

## **📂 PROJECT STRUCTURE**

```
File Manager/
├── src/
│   ├── main/
│   │   ├── java/com/filemanager/
│   │   │   ├── FileManagerApiApplication.java    (Entry point)
│   │   │   ├── controller/
│   │   │   │   └── FileController.java           (REST endpoints)
│   │   │   ├── service/
│   │   │   │   └── FileService.java              (Business logic)
│   │   │   ├── config/
│   │   │   │   └── CorsConfig.java               (CORS settings)
│   │   │   ├── model/
│   │   │   │   ├── ApiResponse.java              (Response wrapper)
│   │   │   │   └── FileResponse.java             (File metadata DTO)
│   │   │   └── exception/
│   │   │       └── GlobalExceptionHandler.java   (Error handling)
│   │   └── resources/
│   │       └── application.properties            (Server config)
│   └── test/java/...                             (Unit tests)
├── lib/
│   ├── main.dart                                 (App entry point)
│   ├── screens/
│   │   └── home_screen.dart                      (Main UI)
│   ├── services/
│   │   └── api_service.dart                      (HTTP client)
│   └── models/
│       └── file_item.dart                        (File model)
├── android/                                      (Native Android config)
├── pubspec.yaml                                  (Flutter dependencies)
└── pom.xml                                       (Java/Maven dependencies)
```

---

## **🔌 API ENDPOINTS**

### **1. List Files**

```
GET /api/files
Response: [
  {
    "name": "report.pdf",
    "size": 204800,
    "lastModified": "2024-06-15T10:30:00"
  }
]
```

### **2. Upload File**

```
POST /api/files/upload
Content-Type: multipart/form-data
Form data: file=<binary>
Response: {"success": true, "message": "File uploaded: report.pdf"}
```

### **3. Download File**

```
GET /api/files/download/{filename}
Response: <binary file content>
```

### **4. Delete File**

```
DELETE /api/files/delete/{filename}
Response: {"success": true, "message": "File deleted: report.pdf"}
```

---

## **🔒 SECURITY NOTES (Development)**

⚠️ **Current setup is for LOCAL NETWORK ONLY:**

- ✅ No authentication required (WiFi = trusted network)
- ✅ CORS allows all origins (dev mode)
- ✅ No HTTPS (HTTP only)
- ✅ No rate limiting

**For Production, Add:**

- [ ] API Key or JWT authentication
- [ ] HTTPS with SSL certificates
- [ ] CORS whitelist specific origins
- [ ] Input validation & path traversal protection
- [ ] File type restrictions
- [ ] Rate limiting
- [ ] Comprehensive logging

---

## **📦 BUILD & RELEASE**

### **Building Android APK**

```bash
cd "d:\File Manager"
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### **Building Spring Boot JAR**

```bash
mvn clean package
# Output: target/file-manager-api-*.jar
```

Run JAR:

```bash
java -jar target/file-manager-api-*.jar
```

---

## **📞 SUPPORT**

If issues persist:

1. Check this guide's **Troubleshooting** section
2. Verify both Java and Flutter are properly installed
3. Ensure correct IP address (use `ipconfig` to verify)
4. Confirm same WiFi network connection
5. Check firewall settings allow port 8080

---

**✅ Application is ready for local network file sharing!**
