import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart' as ml_kit;
import 'dart:io';
import 'scan_result_screen.dart';
import 'features/barcode_result_screen.dart';
import '../services/service_provider.dart';
import '../models/history_item.dart';
import '../utils/qr_history_helper.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isFlashOn = false;
  bool _isCameraPermissionGranted = false;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isCameraPermissionGranted = status.isGranted;
    });
  }

  bool _isQRCode(String data) {
    // Check if it's a QR code format
    return data.startsWith('BEGIN:VCARD') ||
        data.startsWith('MAILTO:') ||
        data.startsWith('SMSTO:') ||
        (Uri.tryParse(data)?.hasScheme ?? false) ||
        data.contains('\n') || // QR codes often contain line breaks
        RegExp(r'[^\x20-\x7E]').hasMatch(data); // Contains non-ASCII characters
  }

  String _detectBarcodeFormat(String data) {
    // First check if it's a QR code
    if (_isQRCode(data)) return 'QR';

    // Then check specific barcode formats
    if (RegExp(r'^\d{13}$').hasMatch(data)) return 'EAN-13';
    if (RegExp(r'^\d{8}$').hasMatch(data)) return 'EAN-8';
    if (RegExp(r'^0\d{7}$').hasMatch(data)) return 'UPC-E';
    if (RegExp(r'^\d{14}$').hasMatch(data)) return 'ITF-14';
    if (RegExp(r'^[A-Z0-9\-\.\s\$\/\+%]+$').hasMatch(data)) return 'Code 39';
    if (RegExp(r'^\d{12}$').hasMatch(data)) return 'UPC-A';
    if (RegExp(r'^[0-9]+$').hasMatch(data)) return 'Code 128';

    return 'Code 128'; // Default to Code 128 for general text
  }

  Future<void> _handleScannedCode(String code, {File? imageFile}) async {
    final String format = _detectBarcodeFormat(code);

    if (format == 'QR') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultScreen(
            scannedCode: code,
            qrImage: imageFile,
          ),
        ),
      ).then((_) => controller?.resumeCamera());
    } else {
      // Save barcode to history
      final historyService = ServiceProvider.of(context).historyService;
      final historyItem = HistoryItem(
        type: 'scanned',
        title: 'Barcode : $format',
        subtitle: code,
        date: DateTime.now().toString(),
        iconPath: 'assets/icons/barcode.png',
        additionalData: {
          'type': format,
          'content': code,
          'isBarcode': true, // Add this flag to explicitly mark as barcode
        },
      );
      await historyService.addItem(historyItem);

      // Navigate to barcode result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeResultScreen(
            content: code,
            type: format,
          ),
        ),
      ).then((_) => controller?.resumeCamera());
    }
  }

  Future<void> _pickImage() async {
    if (_isProcessingImage) return;

    setState(() {
      _isProcessingImage = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final File imageFile = File(image.path);
        final ml_kit.InputImage inputImage =
            ml_kit.InputImage.fromFile(imageFile);
        final ml_kit.BarcodeScanner barcodeScanner =
            ml_kit.GoogleMlKit.vision.barcodeScanner();

        final List<ml_kit.Barcode> barcodes =
            await barcodeScanner.processImage(inputImage);
        await barcodeScanner.close();

        if (barcodes.isNotEmpty && mounted) {
          final String? code = barcodes.first.rawValue;
          if (code != null) {
            await _handleScannedCode(code, imageFile: imageFile);
          } else {
            _showError('No barcode found in the image');
          }
        } else {
          _showError('No barcode found in the image');
        }
      }
    } catch (e) {
      _showError('Error processing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code != null) {
        controller.pauseCamera();
        await _handleScannedCode(scanData.code!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraPermissionGranted) {
      return _buildPermissionRequest();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Theme.of(context).primaryColor,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      controller?.toggleFlash();
                      setState(() => _isFlashOn = !_isFlashOn);
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.flip_camera_ios,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => controller?.flipCamera(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildOptionButton(
                          icon: Icons.qr_code_scanner,
                          label: 'Camera Scan',
                          isActive: true,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildOptionButton(
                          icon: Icons.image,
                          label: 'Gallery',
                          onTap: _pickImage,
                          isLoading: _isProcessingImage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Please grant camera permission to use the QR code scanner',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermission,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).iconTheme.color,
                ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
