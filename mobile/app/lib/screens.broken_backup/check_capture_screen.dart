import 'dart:io';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/camera_overlay_widget.dart';
import '../models/check_deposit_model.dart';

class CheckCaptureScreen extends StatefulWidget {
  final CheckSide side;
  final Function(File) onImageCaptured;

  const CheckCaptureScreen({
    super.key,
    required this.side,
    required this.onImageCaptured,
  });

  @override
  State<CheckCaptureScreen> createState() => _CheckCaptureScreenState();
}

class _CheckCaptureScreenState extends State<CheckCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // Check camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      _showPermissionError();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (!mounted) return;
        _showCameraError();
        return;
      }

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
      if (!mounted) return;
      _showCameraError();
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      final File imageFile = File(image.path);
      
      if (!mounted) return;
      
      // Show preview
      final confirmed = await _showImagePreview(imageFile);
      
      if (confirmed && mounted) {
        widget.onImageCaptured(imageFile);
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error capturing image: $e');
      if (!mounted) return;
      
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Failed to capture image: $e)),

          );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        final File imageFile = File(image.path);
        final confirmed = await _showImagePreview(imageFile);
        
        if (confirmed && mounted) {
          widget.onImageCaptured(imageFile);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (!mounted) return;
      
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Failed to pick image: $e)),

          );
    }
  }

  Future<bool> _showImagePreview(File image) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('Review ${widget.side == CheckSide.front ? 'Front' : 'Back'} Image'),
                automaticallyImplyLeading: false,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Retake'),
                  ),
                ],
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Image.file(
                  image,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Make sure the check is clearly visible and all corners are in the frame.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Retake'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Use This Photo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    
    return result ?? false;
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera access to capture check images. Please grant camera permission in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showCameraError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Error'),
        content: const Text(
          'Unable to access camera. You can still select an image from your gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickFromGallery();
            },
            child: const Text('Choose from Gallery'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          
          // Camera overlay
          CameraOverlayWidget(
            title: widget.side == CheckSide.front 
                ? 'Capture Front of Check' 
                : 'Capture Back of Check',
            subtitle: widget.side == CheckSide.front
                ? 'Place the front of your check within the guides'
                : 'Sign the back and place within the guides',
            onCapture: _captureImage,
            onCancel: () => Navigator.pop(context),
          ),
          
          // Gallery button
          Positioned(
            bottom: 60,
            right: 20,
            child: SafeArea(
              child: IconButton(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}