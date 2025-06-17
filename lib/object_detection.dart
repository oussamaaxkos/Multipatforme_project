import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:flutter_tts/flutter_tts.dart';  // Add this dependency
import 'dart:io';

// stream
// classifyObjects
// multipleObjects

// Simple color scheme
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFF4CAF50);
  static const Color text = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color error = Color(0xFFFF5252);
}


class SimpleObjectDetection extends StatefulWidget {
  const SimpleObjectDetection({super.key});

  @override
  State<SimpleObjectDetection> createState() => _SimpleObjectDetectionState();
}

class _SimpleObjectDetectionState extends State<SimpleObjectDetection> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  
  // ML Kit Object Detection and Image Labeling
  late ObjectDetector _objectDetector;
  late ImageLabeler _imageLabeler;
  
  // Text-to-Speech
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _speechEnabled = true;
  Set<String> _spokenObjects = {}; // Track what we've already announced
  DateTime _lastSpeechTime = DateTime.now();
  
  // Detection results
  List<DetectedObject> _detectedObjects = [];
  List<ImageLabel> _imageLabels = [];
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _initializeTTS();
    await _initializeMLKit();
    await _initializeCamera();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      _showError('Camera permission required for object detection');
    }
  }

  Future<void> _initializeTTS() async {
    _flutterTts = FlutterTts();
    
    // Configure TTS settings
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
    
    // Set up TTS callbacks
    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
    
    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
      debugPrint('TTS Error: $msg');
    });
    
    debugPrint('Text-to-Speech initialized');
  }

  Future<void> _initializeMLKit() async {
    try {
      // Object Detection for bounding boxes
      final objectOptions = ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      );
      
      // Image Labeling for better classification
      final labelOptions = ImageLabelerOptions(
        confidenceThreshold: 0.5,
      );
      
      _objectDetector = ObjectDetector(options: objectOptions);
      _imageLabeler = ImageLabeler(options: labelOptions);
      
      debugPrint('ML Kit initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ML Kit: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium, // Reduced for better performance
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.nv21,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _imageSize = Size(
              _cameraController!.value.previewSize!.height,
              _cameraController!.value.previewSize!.width,
            );
          });
        }
        
        _startRealTimeDetection();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _showError('Unable to initialize camera');
    }
  }

  void _startRealTimeDetection() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _isProcessing = true;
          _processImage(image).then((_) {
            if (mounted) {
              _isProcessing = false;
            }
          });
        }
      });
    }
  }

  Future<void> _processImage(CameraImage cameraImage) async {
    try {
      final inputImage = _inputImageFromCameraImage(cameraImage);
      if (inputImage == null) return;

      // Run both object detection and image labeling
      final objectsFuture = _objectDetector.processImage(inputImage);
      final labelsFuture = _imageLabeler.processImage(inputImage);
      
      final results = await Future.wait([objectsFuture, labelsFuture]);
      final objects = results[0] as List<DetectedObject>;
      final labels = results[1] as List<ImageLabel>;
      
      if (mounted) {
        setState(() {
          _detectedObjects = objects;
          _imageLabels = labels;
        });
        
        // Announce detected objects
        _announceDetectedObjects(objects, labels);
      }
    } catch (e) {
      debugPrint('Image processing error: $e');
    }
  }

  Future<void> _announceDetectedObjects(List<DetectedObject> objects, List<ImageLabel> labels) async {
    if (!_speechEnabled || _isSpeaking) return;
    
    // Prevent too frequent announcements
    final now = DateTime.now();
    if (now.difference(_lastSpeechTime).inSeconds < 3) return;
    
    // Get the highest confidence labels
    List<String> currentObjects = [];
    
    // Prioritize image labels (usually more accurate)
    for (var label in labels) {
      if (label.confidence > 0.7) {
        currentObjects.add(label.label.toLowerCase());
      }
    }
    
    // Add object detection labels if we don't have enough from image labeling
    if (currentObjects.length < 2) {
      for (var obj in objects) {
        if (obj.labels.isNotEmpty) {
          final label = obj.labels.first;
          if (label.confidence > 0.5) {
            currentObjects.add(label.text.toLowerCase());
          }
        }
      }
    }
    
    // Remove duplicates
    currentObjects = currentObjects.toSet().toList();
    
    // Find new objects that haven't been announced recently
    final newObjects = currentObjects.where((obj) => !_spokenObjects.contains(obj)).toList();
    
    if (newObjects.isNotEmpty) {
      String announcement;
      if (newObjects.length == 1) {
        announcement = "I see a ${newObjects.first}";
      } else if (newObjects.length == 2) {
        announcement = "I see a ${newObjects[0]} and a ${newObjects[1]}";
      } else {
        announcement = "I see a ${newObjects[0]}, a ${newObjects[1]}, and ${newObjects.length - 2} other objects";
      }
      
      await _speak(announcement);
      
      // Update spoken objects and last speech time
      _spokenObjects.addAll(newObjects);
      _lastSpeechTime = now;
      
      // Clear spoken objects after some time to allow re-announcement
      Future.delayed(const Duration(seconds: 10), () {
        _spokenObjects.clear();
      });
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
      debugPrint('Speaking: $text');
    } catch (e) {
      debugPrint('Speech error: $e');
    }
  }

  void _toggleSpeech() {
    setState(() {
      _speechEnabled = !_speechEnabled;
    });
    
    if (!_speechEnabled && _isSpeaking) {
      _flutterTts.stop();
    }
    
    _speak(_speechEnabled ? "Speech enabled" : "Speech disabled");
  }

  InputImage? _inputImageFromCameraImage(CameraImage cameraImage) {
    try {
      final camera = _cameras![0];
      final sensorOrientation = camera.sensorOrientation;
      
      InputImageRotation? rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation = _orientations[_cameraController!.value.deviceOrientation];
        if (rotationCompensation == null) return null;
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
      if (format == null) return null;

      if (cameraImage.planes.length != 1) return null;
      final plane = cameraImage.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Image conversion error: $e');
      return null;
    }
  }

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _objectDetector.close();
    _imageLabeler.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Object Detection',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Speech toggle button
          IconButton(
            icon: Icon(
              _speechEnabled ? Icons.volume_up : Icons.volume_off,
              color: _speechEnabled ? AppColors.accent : AppColors.textSecondary,
            ),
            onPressed: _toggleSpeech,
          ),
          // Speaking indicator
          if (_isSpeaking)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera view
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCameraView(),
              ),
            ),
          ),
          
          // Detection results
          Container(
            height: 120,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: _buildDetectionResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return Container(
        color: AppColors.surface,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Starting camera...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        
        // Detection overlays - simplified bounding boxes
        ..._detectedObjects.map((obj) => _buildDetectionBox(obj)),
        
        // Detection count indicator
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_detectedObjects.length} objects, ${_imageLabels.length} labels',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        
        // Speech status indicator
        if (_speechEnabled)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isSpeaking ? AppColors.accent.withOpacity(0.8) : Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSpeaking ? Icons.record_voice_over : Icons.volume_up,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isSpeaking ? 'Speaking...' : 'Voice On',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetectionBox(DetectedObject detectedObject) {
    final rect = detectedObject.boundingBox;
    
    // Try to match detected object with image labels
    String labelText = 'Object';
    if (_imageLabels.isNotEmpty) {
      labelText = _imageLabels.first.label;
    } else if (detectedObject.labels.isNotEmpty) {
      labelText = detectedObject.labels.first.text;
    }
    
    return Positioned(
      left: rect.left,
      top: rect.top,
      child: Container(
        width: rect.width,
        height: rect.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.accent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labelText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionResults() {
    // Combine object detection and image labeling results
    List<String> allLabels = [];
    
    // Add image labels (usually more accurate)
    for (var label in _imageLabels) {
      if (label.confidence > 0.5) {
        allLabels.add('${label.label} (${(label.confidence * 100).toInt()}%)');
      }
    }
    
    // Add object detection labels as fallback
    for (var obj in _detectedObjects) {
      if (obj.labels.isNotEmpty) {
        final label = obj.labels.first;
        if (label.confidence > 0.3) {
          allLabels.add('${label.text} (${(label.confidence * 100).toInt()}%)');
        }
      }
    }
    
    // Remove duplicates
    allLabels = allLabels.toSet().toList();
    
    if (allLabels.isEmpty) {
      return const Center(
        child: Text(
          'Point camera at objects to detect them',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Detected Items (${allLabels.length})',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isSpeaking) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allLabels.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    allLabels[index],
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}