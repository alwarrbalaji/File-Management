// lib/screens/home_screen.dart
// ---------------------------------------------------------------------------
// Main screen: lists files, supports upload / download / delete.
// State management: simple setState + FutureBuilder (no extra packages needed).
// ---------------------------------------------------------------------------

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/file_item.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  late Future<List<FileItem>> _filesFuture;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Tracks which file is currently being downloaded {filename: progress 0-1}
  final Map<String, double> _downloadProgress = {};

  // ── Animation for FAB ─────────────────────────────────────────────────────
  late final AnimationController _fabAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────
  void _loadFiles() {
    setState(() {
      _filesFuture = ApiService.instance.listFiles();
    });
  }

  // ── Upload ─────────────────────────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    // Step 1: Let user pick any file from the device
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false, // stream from path — memory-efficient for large files
    );

    if (result == null || result.files.isEmpty) return; // user cancelled
    final picked = result.files.first;
    if (picked.path == null) {
      _showSnackBar('Could not access the selected file path.', isError: true);
      return;
    }

    final file = File(picked.path!);

    // Step 2: Upload with progress tracking
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      await ApiService.instance.uploadFile(
        file,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      _showSnackBar('✓ "${picked.name}" uploaded successfully.');
      _loadFiles(); // refresh the list
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // ── Download ───────────────────────────────────────────────────────────────
  Future<void> _downloadFile(FileItem item) async {
    if (_downloadProgress.containsKey(item.name)) return; // already in progress

    setState(() => _downloadProgress[item.name] = 0.0);

    try {
      final saved = await ApiService.instance.downloadFile(
        item.name,
        onProgress: (p) => setState(() => _downloadProgress[item.name] = p),
      );
      _showSnackBar('✓ Saved to: ${saved.path}');
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } finally {
      setState(() => _downloadProgress.remove(item.name));
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(FileItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete File'),
        content: RichText(
          text: TextSpan(
            style: Theme.of(ctx).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' from the server? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.instance.deleteFile(item.name);
      _showSnackBar('✓ "${item.name}" deleted.');
      _loadFiles();
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: Duration(seconds: isError ? 5 : 3),
        ),
      );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      floatingActionButton: _buildFab(colorScheme),
      body: Column(
        children: [
          // Upload progress bar (visible only while uploading)
          if (_isUploading) _buildUploadBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme cs) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: cs.surface,
      surfaceTintColor: cs.primary,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.folder_rounded, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Manager',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
              Text(
                'Spring Boot Storage',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh file list',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadFiles,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFab(ColorScheme cs) {
    return FloatingActionButton.extended(
      onPressed: _isUploading ? null : _pickAndUpload,
      backgroundColor: _isUploading ? cs.surfaceContainerHighest : cs.primary,
      foregroundColor: _isUploading ? cs.onSurfaceVariant : cs.onPrimary,
      elevation: _isUploading ? 0 : 4,
      icon: _isUploading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: _uploadProgress > 0 ? _uploadProgress : null,
                color: cs.primary,
              ),
            )
          : const Icon(Icons.upload_rounded),
      label: Text(
        _isUploading
            ? 'Uploading ${(_uploadProgress * 100).toStringAsFixed(0)}%'
            : 'Upload File',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildUploadBanner() {
    return Container(
      color:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploading file… ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<FileItem>>(
      future: _filesFuture,
      builder: (context, snapshot) {
        // ── Loading ──────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading files from server…',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // ── Error ────────────────────────────────────────────────────────
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final files = snapshot.data ?? [];

        // ── Empty ────────────────────────────────────────────────────────
        if (files.isEmpty) {
          return _buildEmptyState();
        }

        // ── File List ────────────────────────────────────────────────────
        return RefreshIndicator(
          onRefresh: () async => _loadFiles(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            // Extra bottom padding so FAB doesn't cover last item
            itemCount: files.length,
            itemBuilder: (ctx, i) => _buildFileTile(files[i]),
          ),
        );
      },
    );
  }

  Widget _buildFileTile(FileItem item) {
    final cs = Theme.of(context).colorScheme;
    final isDownloading = _downloadProgress.containsKey(item.name);
    final dlProgress = _downloadProgress[item.name] ?? 0.0;
    final dateLabel =
        DateFormat('dd MMM yyyy, HH:mm').format(item.lastModified);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      color: cs.surface,
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            // ── File type icon ─────────────────────────────────────────
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                    _extensionColor(item.extension, cs).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _extensionIcon(item.extension),
                color: _extensionColor(item.extension, cs),
                size: 24,
              ),
            ),

            // ── File name & meta ───────────────────────────────────────
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: cs.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${item.readableSize}  •  $dateLabel',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),

            // ── Action buttons ─────────────────────────────────────────
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Download button
                _ActionIconButton(
                  tooltip: 'Download',
                  icon: isDownloading
                      ? Icons.downloading_rounded
                      : Icons.download_rounded,
                  color: cs.primary,
                  isLoading: isDownloading,
                  loadingProgress: dlProgress,
                  onTap: isDownloading ? null : () => _downloadFile(item),
                ),
                const SizedBox(width: 4),
                // Delete button
                _ActionIconButton(
                  tooltip: 'Delete from server',
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  onTap: () => _confirmDelete(item),
                ),
              ],
            ),
          ),

          // Download progress bar (shown only during active download)
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading… ${(dlProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: dlProgress > 0 ? dlProgress : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: cs.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No files yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the Upload button below to send\nyour first file to the server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onErrorContainer,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadFiles,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: Edit lib/services/api_service.dart\nand set _kBaseUrl to your PC\'s local IP.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Extension → icon mapping ──────────────────────────────────────────────
  IconData _extensionIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return Icons.image_rounded;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Icons.audio_file_rounded;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'txt':
      case 'md':
        return Icons.article_rounded;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        return Icons.data_object_rounded;
      case 'dart':
      case 'java':
      case 'kt':
      case 'py':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
        return Icons.code_rounded;
      case 'apk':
        return Icons.android_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _extensionColor(String ext, ColorScheme cs) {
    switch (ext) {
      case 'pdf':
        return Colors.red.shade600;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple.shade400;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Colors.deepOrange.shade400;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Colors.pink.shade400;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.amber.shade700;
      case 'doc':
      case 'docx':
        return Colors.blue.shade600;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Colors.green.shade600;
      case 'ppt':
      case 'pptx':
        return Colors.orange.shade600;
      case 'dart':
      case 'java':
      case 'kt':
      case 'py':
      case 'js':
        return Colors.teal.shade500;
      case 'apk':
        return Colors.lightGreen.shade600;
      default:
        return cs.primary;
    }
  }
}

// ============================================================================
// Small reusable icon button used in each list tile
// ============================================================================
class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.loadingProgress = 0.0,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final double loadingProgress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: loadingProgress > 0 ? loadingProgress : null,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
