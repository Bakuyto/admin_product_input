import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker for web support
import 'package:my_flutter_app/models/pub_var.dart';
import 'package:path/path.dart' show basename;
import 'package:flutter/foundation.dart'; // For checking platform type (mobile/web)

class AddNewVideo extends StatefulWidget {
  @override
  _AddNewVideoState createState() => _AddNewVideoState();
}

class _AddNewVideoState extends State<AddNewVideo> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  XFile? _videoFile;
  XFile? _thumbnailFile;
  final _picker = ImagePicker();

  // Pick video (for both mobile and web)
  Future<XFile?> _pickVideo() async {
    if (kIsWeb) {
      // For web, use file_picker to select video file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );
      if (result != null && result.files.isNotEmpty) {
        var platformFile = result.files.single;
        print('Selected Video Path: ${platformFile.path}');
        return XFile(platformFile.path!); // Return the path directly as XFile
      }
    } else {
      // For mobile, use image_picker to select video
      return await _picker.pickVideo(source: ImageSource.gallery);
    }
    return null;
  }

  // Pick thumbnail (for both mobile and web)
  Future<XFile?> _pickThumbnail() async {
    if (kIsWeb) {
      // For web, use file_picker to select image file for thumbnail
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        var platformFile = result.files.single;
        return XFile(platformFile.path!); // Return the path directly as XFile
      }
    } else {
      // For mobile, use image_picker to select image for thumbnail
      return await _picker.pickImage(source: ImageSource.gallery);
    }
    return null;
  }

  // Upload video and thumbnail to the server
  Future<void> addVideo(
    String title,
    String description,
    XFile videoFile,
    XFile? thumbnailFile,
  ) async {
    var uri = Uri.parse('${apiBasess}/save_videos.php');
    var request = http.MultipartRequest('POST', uri)
      ..fields['title'] = title
      ..fields['description'] = description;

    // Add video file to the request
    var videoMultipartFile = await http.MultipartFile.fromPath(
      'video',
      videoFile.path,
      filename: basename(videoFile.path),
    );
    request.files.add(videoMultipartFile);

    // Add thumbnail file if available
    if (thumbnailFile != null) {
      var thumbnailMultipartFile = await http.MultipartFile.fromPath(
        'thumbnail',
        thumbnailFile.path,
        filename: basename(thumbnailFile.path),
      );
      request.files.add(thumbnailMultipartFile);
    }

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      print('Video and thumbnail uploaded successfully');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Video uploaded successfully!')));
    } else {
      print('Failed to upload video and thumbnail. Response: $responseBody');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload video!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Video')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                _videoFile = await _pickVideo();
                setState(() {}); // Refresh the UI to show selected video
              },
              icon: Icon(Icons.video_collection),
              label: Text(
                _videoFile == null
                    ? 'Browse Video'
                    : 'Video Selected: ${_videoFile!.name}',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                _thumbnailFile = await _pickThumbnail();
                setState(() {}); // Refresh the UI to show selected thumbnail
              },
              icon: Icon(Icons.image),
              label: Text(
                _thumbnailFile == null
                    ? 'Browse Thumbnail (Optional)'
                    : 'Thumbnail Selected: ${_thumbnailFile!.name}',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();

                if (title.isEmpty ||
                    description.isEmpty ||
                    _videoFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please fill in all fields and select a video!',
                      ),
                    ),
                  );
                } else {
                  await addVideo(
                    title,
                    description,
                    _videoFile!,
                    _thumbnailFile,
                  );
                  titleController.clear();
                  descriptionController.clear();
                  setState(() {
                    _videoFile = null;
                    _thumbnailFile = null;
                  });
                }
              },
              child: Text('Save Video'),
            ),
          ],
        ),
      ),
    );
  }
}
