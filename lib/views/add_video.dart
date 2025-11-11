import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_flutter_app/models/pub_var.dart';
import 'package:path/path.dart' show basename;
import 'package:video_player/video_player.dart';

class AddNewVideo extends StatefulWidget {
  const AddNewVideo({super.key});
  @override
  State<AddNewVideo> createState() => _AddNewVideoState();
}

class _AddNewVideoState extends State<AddNewVideo>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  XFile? _videoFile;
  XFile? _thumbFile;
  Uint8List? _thumbBytes;
  Uint8List? _videoBytes; // <-- NEW: Stores video bytes for web upload fix
  VideoPlayerController? _videoController;

  final _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    // Add listeners for TextFormFields to update the clear button state
    _titleCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _fadeController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // 1. PICK VIDEO (FIXED STREAM ISSUE FOR WEB)
  // ──────────────────────────────────────────────────────────────
  Future<void> _pickVideo() async {
    XFile? picked;
    Uint8List? videoData;

    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      videoData = file.bytes;
      picked = XFile.fromData(
        videoData!,
        name: file.name,
        // DO NOT set `path:` – it’s meaningless on web
      );
    } else {
      picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        videoData = await picked.readAsBytes(); // Pre-read for consistency
      }
    }

    if (picked != null) {
      setState(() {
        _videoFile = picked;
        _videoBytes = videoData;
      });
      _fadeController.forward();
      _initVideoPreview(picked);
    }
  }

  void _initVideoPreview(XFile file) async {
    _videoController?.dispose();
    if (!kIsWeb) {
      // Keep initialization logic for mobile video player cleanup
      final controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      controller.setLooping(true);
      controller.pause();
      setState(() => _videoController = controller);
    } else {
      _videoController = null;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 2. PICK THUMBNAIL
  // ──────────────────────────────────────────────────────────────
  Future<void> _pickThumbnail() async {
    final XFile? picked;
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      setState(() {
        _thumbFile = XFile.fromData(
          file.bytes!,
          name: file.name,
          path: 'web_thumbnail.jpg',
        );
        _thumbBytes = file.bytes;
      });
    } else {
      picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _thumbFile = picked;
          _thumbBytes = null;
        });
      }
    }
    _fadeController.forward();
  }

  // ──────────────────────────────────────────────────────────────
  // 3. CLEAR FUNCTIONS
  // ──────────────────────────────────────────────────────────────
  void _clearTitle() {
    _titleCtrl.clear();
  }

  void _clearDescription() {
    _descCtrl.clear();
  }

  void _clearVideo() async {
    await _videoController?.pause();
    _videoController?.dispose();
    setState(() {
      _videoFile = null;
      _videoController = null;
      _videoBytes = null; // Clear video bytes
    });
    if (_thumbFile == null) _fadeController.reverse();
  }

  void _clearThumbnail() {
    setState(() {
      _thumbFile = null;
      _thumbBytes = null;
    });
    if (_videoFile == null) _fadeController.reverse();
  }

  void _resetAll() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _clearVideo();
    _clearThumbnail();
  }

  // ──────────────────────────────────────────────────────────────
  // 4. UPLOAD (USING PRE-READ BYTES FOR WEB)
  Future<void> _upload() async {
    if (!_formKey.currentState!.validate() || _videoFile == null) {
      _showError('Please select a video.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final uri = Uri.parse('${apiBasess}/save_videos.php');
    final request = http.MultipartRequest('POST', uri)
      ..fields['title'] = _titleCtrl.text.trim()
      ..fields['description'] = _descCtrl.text.trim();

    // VIDEO: Always use bytes (web + mobile)
    final videoMultipart = http.MultipartFile.fromBytes(
      'video',
      _videoBytes!,
      filename: _videoFile!.name,
    );
    request.files.add(videoMultipart);

    // THUMBNAIL (optional)
    if (_thumbFile != null) {
      final thumbBytes = kIsWeb
          ? _thumbBytes!
          : await _thumbFile!.readAsBytes();
      final thumbMultipart = http.MultipartFile.fromBytes(
        'thumbnail',
        thumbBytes,
        filename: _thumbFile!.name,
      );
      request.files.add(thumbMultipart);
    }

    try {
      final streamedResponse = await request.send();

      // === READ STREAM ONCE ONLY ===
      final responseBytes = <int>[];
      int received = 0;
      final total = streamedResponse.contentLength ?? 0;

      await for (final chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          setState(() => _uploadProgress = received / total);
        }
      }

      // === RECONSTRUCT RESPONSE ===
      final response = http.Response.bytes(
        responseBytes,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: streamedResponse.request,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );

      // === FINAL CHECK ===
      if (response.statusCode == 200) {
        _showSuccess();
        _resetAll();
      } else {
        _showError('Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Video uploaded successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red),
        title: const Text('Upload Failed'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 5. UI
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Video'),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Title ──
                _InputWithClear(
                  controller: _titleCtrl,
                  label: 'Video Title',
                  icon: Icons.title,
                  onClear: _clearTitle,
                  validator: (v) => v?.trim().isEmpty ?? true
                      ? 'Video title is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Description ──
                _InputWithClear(
                  controller: _descCtrl,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 5,
                  onClear: _clearDescription,
                  validator: (v) => v?.trim().isEmpty ?? true
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 24),

                // ── Video Picker (Enhanced) ──
                _MediaCard(
                  title: 'Select Video',
                  fileName: _videoFile?.name,
                  icon: Icons.video_file,
                  onTap: _pickVideo,
                  onClear: _videoFile != null ? _clearVideo : null,
                  color: cs.primaryContainer,
                  hint: 'Required',
                ),
                const SizedBox(height: 12),

                // ── Thumbnail Picker (Enhanced) ──
                _MediaCard(
                  title: 'Select Thumbnail',
                  fileName: _thumbFile?.name,
                  icon: Icons.image,
                  onTap: _pickThumbnail,
                  onClear: _thumbFile != null ? _clearThumbnail : null,
                  color: cs.secondaryContainer,
                  hint: 'Optional',
                ),
                const SizedBox(height: 20),

                // ── Previews (Thumbnail Only) ──
                if (_thumbFile != null) // Only show if thumbnail is selected
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Thumbnail Preview:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Divider(),

                        // Thumbnail Preview
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: kIsWeb && _thumbBytes != null
                                  ? Image.memory(
                                      _thumbBytes!,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_thumbFile!.path),
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Upload Button ──
                if (!_isUploading)
                  FilledButton.icon(
                    onPressed: _upload,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text(
                      'Upload Video',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Reset All ──
                if (!_isUploading)
                  OutlinedButton.icon(
                    onPressed: _resetAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Upload Progress Overlay ──
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    elevation: 10,
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Uploading Video...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 16, color: cs.primary),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Please do not close the app.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Reusable: TextField with Clear Button
// ──────────────────────────────────────────────────────────────
class _InputWithClear extends StatelessWidget {
  const _InputWithClear({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onClear,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onClear;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    // Using ValueListenableBuilder to rebuild the suffix icon only
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.isNotEmpty;
        return TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: validator,
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Reusable: Media Picker Card with Clear (Enhanced)
// ──────────────────────────────────────────────────────────────
class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
    this.onClear,
    this.fileName,
    this.hint,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final VoidCallback? onClear;
  final String? fileName;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = fileName != null;
    final cs = Theme.of(context).colorScheme;

    return Card(
      // Highlight card when a file is selected
      color: isSelected ? color.withOpacity(0.8) : cs.surfaceContainerHigh,
      elevation: isSelected ? 5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Add a primary border when selected
        side: isSelected
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: isSelected ? cs.onPrimaryContainer : cs.primary,
          size: 30,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hint != null)
              Text(
                hint!,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? cs.onPrimaryContainer.withOpacity(0.8)
                      : cs.onSurfaceVariant,
                ),
              ),
            if (isSelected)
              Text(
                fileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
              ),
          ],
        ),

        // Use a trailing icon for clear or chevron for selection
        trailing: onClear != null
            ? IconButton(
                icon: Icon(
                  Icons.close,
                  size: 24,
                  color: isSelected ? cs.onErrorContainer : cs.error,
                ),
                onPressed: onClear,
              )
            : Icon(Icons.add_circle_outline, color: cs.primary),

        onTap: isSelected ? null : onTap, // Only allow tap if not selected
      ),
    );
  }
}
