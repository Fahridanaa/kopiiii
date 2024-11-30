import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kopi1/services/detection.painter.dart';
import 'package:kopi1/services/object_detector.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  ObjectDetector? _objectDetector;
  XFile? _imageFile;
  List<dynamic> _detections = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _objectDetector = ObjectDetector();

      if (mounted) setState(() {});
    } catch (e) {
      print('Error setting up camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile image = await _controller!.takePicture();
      final results = await _objectDetector?.detectFromImage(image) ?? [];

      // Add debug print
      print('Take picture results: $results');

      setState(() {
        _imageFile = image;
        _detections = results;
        _isProcessing = false;
      });
    } catch (e) {
      print('Error taking picture: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _retake() {
    setState(() {
      _imageFile = null;
      _detections = [];
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _objectDetector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _imageFile == null ? _buildCameraPreview() : _buildResultScreen(),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize!.height,
              height: _controller!.value.previewSize!.width,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          child: FloatingActionButton(
            onPressed: _isProcessing ? null : _takePicture,
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.camera),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(_imageFile!.path),
          fit: BoxFit.cover,
        ),
        if (_detections.isNotEmpty)
          CustomPaint(
            size: size,
            painter: DetectionPainter(
              detections: _detections,
              previewSize: size,
              screenSize: size,
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 30,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _imageFile = null;
                _detections = [];
              });
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Retake'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
