# ⚡ QUICK START - Get Running in 5 Minutes

## **👉 DO THIS FIRST (Required)**

### **1. Find Your PC's IP Address** (2 min)

```bash
# Windows - Open CMD and run:
ipconfig

# Look for IPv4 Address like: 192.168.1.50 or 192.168.0.100
```

### **2. Update the IP in Flutter App** (1 min)

**File:** `lib/services/api_service.dart` **Line 16**

```dart
// Change this:
String _kBaseUrl = 'http://192.168.0.100:8080';

// To your actual IP (from ipconfig):
String _kBaseUrl = 'http://192.168.1.50:8080';  // Example
```

---

## **▶️ RUN THE APPLICATION** (2 min)

### **Terminal 1: Start Backend Server**

```bash
cd "d:\File Manager"
mvn clean install
mvn spring-boot:run
```

✅ **Expected output:**

```
🚀 FILE MANAGER API STARTED
Server running at: http://localhost:8080
```

### **Terminal 2: Start Flutter App**

```bash
cd "d:\File Manager"
flutter pub get
flutter run
```

✅ **App should load and show empty file list**

---

## **✅ TEST IT**

1. Open app on phone
2. Should show empty file list
3. Tap **"Upload File"** button
4. Select a file from your phone
5. File should appear in the list
6. Done! 🎉

---

## **❌ If It Doesn't Work**

### **"Connection Failed" Error?**

1. Check IP address: `ipconfig`
2. Update `lib/services/api_service.dart` line 16 with correct IP
3. Rebuild app: `flutter clean && flutter run`

### **Server won't start?**

```bash
# Port 8080 might be in use, try:
mvn spring-boot:run -Dserver.port=9090
# Then update Flutter app IP to use :9090 instead of :8080
```

### **App crashes on upload?**

1. Create folder: `D:\FileStorage` (or check application.properties)
2. Restart server

---

## **📖 Full Documentation**

- See `SETUP_AND_DEPLOYMENT.md` for complete setup guide
- See `FIXES_APPLIED.md` for what was fixed
- See `README.md` in each src/ folder for architecture details

---

**Your app is ready! 🚀**
