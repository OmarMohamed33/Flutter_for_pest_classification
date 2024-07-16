// ignore_for_file: avoid_print
//import 'dart:io';
// import 'dart:io';

import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:newpro/service.dart';
//import 'package:http_parser/http_parser.dart'; // For MediaType
//import 'package:async/async.dart';
//import 'package:flutter/services.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Import the camera package

//import 'package:mime/mime.dart';
// import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
//import 'package:path/path.dart';

import 'package:image_picker/image_picker.dart';

//import 'package:path_provider/path_provider.dart'; // Import image_picker package

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InsectSnap',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Set IdentifyInsectPage as the initial route
      initialRoute: '/identify-insect',
      routes: {
        '/identify-insect': (context) => IdentifyInsectPage(cameras: cameras),
        '/camera-screen': (context) => CameraScreen(cameras: cameras),
        '/app-info': (context) => const AppInfoPage(),
        '/pest-details': (context) => PestDetailsPage(),
      },
    );
  }
}

class IdentifyInsectPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  IdentifyInsectPage({super.key, required this.cameras});

  final ImagePicker _picker = ImagePicker(); // Create an ImagePicker instance

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    bool sent = false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.info),
          onPressed: () => Navigator.pushNamed(context, '/app-info'),
        ),
        // No actions property needed anymore
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Top text
            const Text(
              'Insect Detection',
              style: TextStyle(
                fontSize: 37,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Two images and buttons side by side
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // First image and button
                Column(
                  children: <Widget>[
                    Image.asset(
                      'assets/1.jpg',
                      height: 120, // Adjust image height as needed
                    ),
                    const SizedBox(
                        height: 10), // Add spacing between image and button
                    ElevatedButton(
                      onPressed: () async {
                        await availableCameras().then(
                          (value) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraScreen(
                                cameras: value,
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Take a picture'),
                    ),
                  ],
                ),
                // Second image and button
                Column(
                  children: <Widget>[
                    Image.asset(
                      'assets/2.jpg',
                      height: 120, // Adjust image height as needed
                    ),
                    const SizedBox(
                        height: 10), // Add spacing between image and button
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (image != null) {
                          Uint8List bytes = await image.readAsBytes();
                             print("Image name: ${image.name}");
                          var response = await UploadApiImage().uploadImage(bytes, image.name!);
                           print("response : $response");

                          //...

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PestDetailsPage(
                                imageBytes: bytes, // Pass the image bytes
                                pestName: response, // Replace with actual pest name
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('From Library'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  XFile? pictureFile;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: SizedBox(
              height: 400,
              width: 350,
              child: CameraPreview(controller),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              pictureFile = await controller.takePicture();
              setState(() {});
              Uint8List bytes = await pictureFile!.readAsBytes();
              UploadApiImage().uploadImage(bytes, pictureFile!.name);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    contentPadding: EdgeInsets.zero,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: const Icon(Icons.camera_alt),
          ),
        ),
        // if (pictureFile != null)
        //   Image.network(
        //     pictureFile!.path,
        //     height: 200,
        //   )
      ],
    );
  }
}

class PestDetailsPage extends StatefulWidget {
  final Uint8List? imageBytes;
  final dynamic pestName;

  PestDetailsPage({this.imageBytes, this.pestName});

  @override
  _PestDetailsPageState createState() => _PestDetailsPageState();
}

class _PestDetailsPageState extends State<PestDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pest Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display uploaded image (if available)
            widget.imageBytes != null
                ? Image.memory(
                    widget.imageBytes!,
                    fit: BoxFit.cover,
                  )
                : Text('No image uploaded'),
            // Display pest name

            Text(
              'Pest Name: ${widget.pestName}',
              style: TextStyle(fontSize: 18),
            ),
            //...
          ],
        ),
      ),
    );
  }
}

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About InsectSnap'),
      ),
      body: SingleChildScrollView(
        // Wrap the Column with SingleChildScrollView
        child: Expanded(
          // Wrap the Column with Expanded
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Add the top image
                Image.asset(
                  'assets/I.jpg', // Replace with your image path
                  height: 200,
                ),
                const SizedBox(height: 20),
                const Text(
                  'App Description:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'this app is used for agriculture pest detection.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),
                // Add the second image before creator names
                Image.asset(
                  'assets/U.jpeg', // Replace with your image path
                  height: 300,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Developers:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(child: Text('Abdelrahman Amr')),
                    SizedBox(width: 5),
                    Expanded(child: Text('Abdelrahman Zeid')),
                    SizedBox(width: 5),
                    Expanded(child: Text('Abdelrahman Refaat')),
                    SizedBox(width: 5),
                    Expanded(child: Text('Omar Mohamed')),
                    SizedBox(width: 5),
                    Expanded(child: Text('Ebtesam Hamad')),
                    SizedBox(width: 5),
                    Expanded(child: Text('Ahmed Hemida')),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showRatingDialog(context),
                  child: const Text('Rate Us'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) async {
    showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const RatingDialog(),
    );
  }
}

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double rating = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate InsectSnap'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) => _buildStar(index)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _showThankYouDialog(context);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= rating ? Icons.star : Icons.star_outline,
        color: Colors.amber,
      ),
      onPressed: () {
        // Update the rating based on the clicked star
        setState(() {
          rating = index + 0;
        });
      },
    );
  }
}

void _showThankYouDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissal by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Rating  Submitted!'),
        content: const Text('Thank you for your opinion!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}