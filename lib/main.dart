import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Emotion Recognition',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dog Emotion Recognition'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _actionResult = "No action performed yet.";
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Function to capture video
  Future<void> _clickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      setState(() {
        _actionResult = "Video captured!";
      });
      _uploadVideo(File(video.path));
    } else {
      setState(() {
        _actionResult = "No video captured.";
      });
    }
  }

  // Function to upload video
  Future<void> _uploadVideo(File videoFile) async {
    setState(() {
      _isLoading = true;
      _actionResult = "Uploading video for prediction...";
    });

    try {
      final uri = Uri.parse(
          "http://192.168.122.24:4000/predict"); // Update to match your server's IP and port
      final request = http.MultipartRequest('POST', uri);
      request.files
          .add(await http.MultipartFile.fromPath('videofile', videoFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(responseBody);
        setState(() {
          _actionResult = "Prediction: ${decodedResponse['prediction']}";
        });
      } else {
        setState(() {
          _actionResult = "Error: ${response.statusCode}, ${responseBody}";
        });
      }
    } catch (e) {
      setState(() {
        _actionResult = "Error uploading video: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    _actionResult,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _clickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text("Capture Video"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? video =
                          await _picker.pickVideo(source: ImageSource.gallery);
                      if (video != null) {
                        _uploadVideo(File(video.path));
                      } else {
                        setState(() {
                          _actionResult = "No video selected.";
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Video"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
