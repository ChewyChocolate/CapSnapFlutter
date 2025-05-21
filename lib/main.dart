import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
// import 'package/flutter/foundation.dart'; // For debugPrint
import 'package:shared_preferences/shared_preferences.dart'; // For saving image paths and categories

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAP-SNAP',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Capsule logo
            Center(
              child: Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/images/meds.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // CAP-SNAP title
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                children: [
                  TextSpan(
                    text: 'CAP-',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  TextSpan(
                    text: 'SNAP',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Get Started button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenButtonsPage()),
                );
              },
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(),
            // Decorative wave at the bottom
            ClipPath(
              clipper: WaveClipperTwo(),
              child: Container(height: 100, color: Colors.teal.shade200),
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenButtonsPage extends StatefulWidget {
  const ScreenButtonsPage({super.key});

  @override
  _ScreenButtonsPageState createState() => _ScreenButtonsPageState();
}

class _ScreenButtonsPageState extends State<ScreenButtonsPage> {
  Map<String, dynamic>? _result;

  Future<void> _classifyImage(File image) async {
    try {
      final uri = Uri.parse('https://capsnaprender.onrender.com/predict');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      // Add timeout to handle slow server responses
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        setState(() {
          _result = result;
        });
      } else {
        setState(() {
          _result = {
            'error':
                'Failed to classify image. Status code: ${response.statusCode}',
          };
        });
      }
    } catch (e) {
      debugPrint('Error classifying image: $e');
      setState(() {
        _result = {'error': 'Network error: $e'};
      });
    }
  }

  Future<void> _pick(ImageSource src) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: src, maxWidth: 600);
    if (picked != null) {
      File img = File(picked.path);
      if (img.existsSync()) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Classifying image...'),
                  ],
                ),
              ),
        );
        await _classifyImage(img);
        Navigator.pop(context); // Dismiss dialog
        if (_result != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultPage(imageFile: img, result: _result),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image file does not exist.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image picking failed or was cancelled.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text('SCREEN BUTTONS', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal.shade400,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.camera_alt, size: 64, color: Colors.teal.shade400),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade200,
                foregroundColor: Colors.teal.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                elevation: 2,
              ),
              onPressed: () => _pick(ImageSource.camera),
              child: const Text('Take Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 32),
            Icon(Icons.photo_library, size: 64, color: Colors.teal.shade400),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade200,
                foregroundColor: Colors.teal.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                elevation: 2,
              ),
              onPressed: () => _pick(ImageSource.gallery),
              child: const Text('Upload Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 32),
            Icon(Icons.save, size: 64, color: Colors.teal.shade400),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade200,
                foregroundColor: Colors.teal.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedImagesPage()),
                );
              },
              child: const Text('Saved Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            ClipPath(
              clipper: WaveClipperTwo(reverse: true),
              child: Container(height: 100, color: Colors.teal.shade200),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedImagesPage extends StatefulWidget {
  const SavedImagesPage({super.key});

  @override
  State<SavedImagesPage> createState() => _SavedImagesPageState();
}

class _SavedImagesPageState extends State<SavedImagesPage> {
  List<String> painkillerImages = [];
  List<String> multivitaminImages = [];
  Map<String, Map<String, dynamic>> imageDetails = {};

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      painkillerImages = prefs.getStringList('painkillerImages') ?? [];
      multivitaminImages = prefs.getStringList('multivitaminImages') ?? [];
      // Load details for all images
      for (final path in painkillerImages + multivitaminImages) {
        final detailsString = prefs.getString('details_$path');
        if (detailsString != null) {
          imageDetails[path] = Map<String, dynamic>.from(
            json.decode(detailsString),
          );
        }
      }
    });
  }

  void _openImage(String path) {
    final details = imageDetails[path] ?? {};
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ResultPage(
              imageFile: File(path),
              result: details.isNotEmpty ? details : null,
              allowSave: false,
            ),
      ),
    );
  }

  Widget _buildList(String title, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        ...images.map(
          (path) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  path.split('/').last,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  path,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => _openImage(path),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: const Icon(Icons.image, color: Colors.teal),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Delete Image'),
                            content: const Text(
                              'Are you sure you want to delete this image?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      _deleteImage(path, title);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        if (images.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 32, thickness: 1.2),
          ),
      ],
    );
  }

  Future<void> _deleteImage(String path, String title) async {
    final prefs = await SharedPreferences.getInstance();
    String key =
        title.toLowerCase().contains('painkiller')
            ? 'painkillerImages'
            : 'multivitaminImages';
    List<String> images = prefs.getStringList(key) ?? [];
    images.remove(path);
    await prefs.setStringList(key, images);
    await prefs.remove('details_$path');
    setState(() {
      if (key == 'painkillerImages') {
        painkillerImages = images;
      } else {
        multivitaminImages = images;
      }
      imageDetails.remove(path);
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Images'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade400,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      backgroundColor: Colors.teal.shade50,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildList('Painkiller', painkillerImages),
          _buildList('Multivitamin', multivitaminImages),
        ],
      ),
    );
  }
}

class ResultPage extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic>? result;
  final bool allowSave;
  const ResultPage({
    super.key,
    required this.imageFile,
    this.result,
    this.allowSave = true,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _saved = false;
  String? _category;

  // Remove auto-save from initState
  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveImage() async {
    if (widget.result != null && widget.result!['class'] != null) {
      final classLabel = widget.result!['class'].toString().toLowerCase();
      String? category;
      if (classLabel.contains('painkiller')) {
        category = 'painkillerImages';
        _category = 'Painkiller';
      } else if (classLabel.contains('multivitamin')) {
        category = 'multivitaminImages';
        _category = 'Multivitamin';
      }
      if (category != null) {
        final prefs = await SharedPreferences.getInstance();
        final images = prefs.getStringList(category) ?? [];
        if (!images.contains(widget.imageFile.path)) {
          images.add(widget.imageFile.path);
          await prefs.setStringList(category, images);
          // Save details as JSON string
          await prefs.setString(
            'details_${widget.imageFile.path}',
            json.encode(widget.result),
          );
          setState(() {
            _saved = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image saved to $_category!')),
            );
          }
        } else {
          setState(() {
            _saved = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image already saved in $_category.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result != null && widget.result!.containsKey('error')) {
      return Scaffold(
        backgroundColor: Colors.teal.shade50,
        body: Center(
          child: Text(
            widget.result!['error'],
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    } else {
      final classLabel = widget.result?['class'] ?? 'N/A';
      final nameLabel = widget.result?['name'] ?? 'N/A';
      final colorLabel = widget.result?['color'] ?? 'N/A';

      return Scaffold(
        backgroundColor: Colors.teal.shade50,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Responsive image in a Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.file(
                    widget.imageFile,
                    height: 150,
                    width: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Improved details layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class: $classLabel',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      'Name: $nameLabel',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Color: $colorLabel',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_saved && _category != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Image saved to $_category',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => Navigator.popUntil(context, (r) => r.isFirst),
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (widget.allowSave) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saved ? null : _saveImage,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }
  }
}

Future<String> downloadFile(String url, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  if (!await file.exists()) {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download $filename');
    }
  }
  return file.path;
}
