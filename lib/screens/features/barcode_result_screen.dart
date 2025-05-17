import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/qr_history_helper.dart';

class BarcodeResultScreen extends StatefulWidget {
  final String content;
  final String type;

  const BarcodeResultScreen({
    Key? key,
    required this.content,
    required this.type,
  }) : super(key: key);

  @override
  _BarcodeResultScreenState createState() => _BarcodeResultScreenState();
}

class _BarcodeResultScreenState extends State<BarcodeResultScreen> {
  String get barcodeData => _validateAndFormatData(widget.content, widget.type);
  late final Barcode barcodeType;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    barcodeType = _getBarcodeType(widget.type);
    _validateAndFormatData(widget.content, widget.type);
    QRHistoryHelper.saveQRToHistoryAfterBuild(
      context,
      title: 'Barcode : ${widget.type}',
      content: widget.content,
      iconPath: 'assets/icons/barcode.png',
      additionalData: {
        'type': widget.type,
        'content': widget.content,
        'error': errorMessage,
      },
    );
  }

  String _calculateEAN13Checksum(String data) {
    if (data.length != 12) return '';

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(data[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }

    int checksum = (10 - (sum % 10)) % 10;
    return checksum.toString();
  }

  String _calculateEAN8Checksum(String data) {
    if (data.length != 7) return '';

    int sum = 0;
    for (int i = 0; i < 7; i++) {
      int digit = int.parse(data[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }

    int checksum = (10 - (sum % 10)) % 10;
    return checksum.toString();
  }

  String _convertUPCEtoUPCA(String upce) {
    if (upce.length != 7 || upce[0] != '0') return upce;

    String code = upce.substring(1, 7); // Remove the first digit (0)
    String lastDigit = code[5]; // Get the last digit
    String result = "0"; // Start with number system digit (0)

    // Apply UPC-E to UPC-A conversion rules
    switch (lastDigit) {
      case "0":
      case "1":
      case "2":
        result += code.substring(0, 2) + // Manufacturer first 2 digits
            lastDigit + // Last digit becomes 3rd digit
            "0000" + // Add 4 zeros
            code.substring(2, 5); // Product code
        break;
      case "3":
        int digit4 = int.parse(code[4]);
        if (digit4 >= 0 && digit4 <= 2) {
          result += code.substring(0, 3) + // Manufacturer first 3 digits
              "00000" + // Add 5 zeros
              code.substring(3, 5); // Product code
        }
        break;
      case "4":
        result += code.substring(0, 4) + // Manufacturer first 4 digits
            "00000" + // Add 5 zeros
            code[4]; // Product code
        break;
      default:
        result += code.substring(0, 5) + // Manufacturer first 5 digits
            "0000" + // Add 4 zeros
            lastDigit; // Product code
        break;
    }

    return result;
  }

  String _calculateUPCEChecksum(String data) {
    if (data.length != 7) return '';

    String upcA = _convertUPCEtoUPCA(data);

    int sum = 0;

    for (int i = 0; i < 11; i++) {
      int digit = int.parse(upcA[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }

    int checksum = (10 - (sum % 10)) % 10;
    return checksum.toString();
  }

  bool _isValidUPCE(String data) {
    if (data.length != 7) return false;
    if (data[0] != '0') return false; // Must start with 0

    String code = data.substring(1); // Get the 6 digits after 0
    String lastDigit = code[5]; // Get the last digit

    // Check if the code follows UPC-E compression rules
    switch (lastDigit) {
      case "0":
      case "1":
      case "2":
        // Manufacturer code cannot be larger than 99
        int mfr = int.parse(code.substring(0, 2));
        return mfr <= 99;
      case "3":
        // Check if the fourth digit is 0-2
        int digit4 = int.parse(code[4]);
        return digit4 >= 0 && digit4 <= 2;
      case "4":
        // Check if the fifth digit is valid
        return true; // Any digit is valid in this position
      default:
        // For 5-9, any configuration is valid
        return true;
    }
  }

  String _calculateITF14Checksum(String data) {
    if (data.length != 13) return '';

    int sum = 0;
    for (int i = 0; i < 13; i++) {
      int digit = int.parse(data[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }

    int checksum = (10 - (sum % 10)) % 10;
    return checksum.toString();
  }

  bool _isValidBarcode(String data, String type) {
    switch (type) {
      case 'EAN-13':
        if (data.length == 13) {
          String content = data.substring(0, 12);
          String checksum = data[12];
          String calculatedChecksum = _calculateEAN13Checksum(content);
          return checksum == calculatedChecksum;
        }
        return false;

      case 'EAN-8':
        if (data.length == 8) {
          String content = data.substring(0, 7);
          String checksum = data[7];
          String calculatedChecksum = _calculateEAN8Checksum(content);
          return checksum == calculatedChecksum;
        }
        return false;

      case 'UPC-E':
        if (data.length == 8) {
          String content = data.substring(0, 7);
          String checksum = data[7];
          String calculatedChecksum = _calculateUPCEChecksum(content);
          return checksum == calculatedChecksum;
        }
        return false;

      case 'ITF-14':
        if (data.length == 14) {
          String content = data.substring(0, 13);
          String checksum = data[13];
          String calculatedChecksum = _calculateITF14Checksum(content);
          return checksum == calculatedChecksum;
        }
        return false;

      default:
        return true;
    }
  }

  String _validateAndFormatData(String content, String type) {
    setState(() {
      errorMessage = null;
    });

    switch (type) {
      case 'ITF-14':
        if (!RegExp(r'^\d+$').hasMatch(content)) {
          setState(() {
            errorMessage = 'ITF-14 requires numeric values only';
          });
          return content;
        }
        if (content.length < 13) {
          setState(() {
            errorMessage = 'ITF-14 requires exactly 13 digits';
          });
          return content;
        }
        if (content.length == 13) {
          String checksum = _calculateITF14Checksum(content);
          return content + checksum;
        }
        if (content.length == 14 && !_isValidBarcode(content, type)) {
          String correctChecksum =
              _calculateITF14Checksum(content.substring(0, 13));
          setState(() {
            errorMessage =
                'Invalid ITF-14 checksum. The correct checksum should be: $correctChecksum';
          });
        }
        return content;

      case 'EAN-13':
        if (!RegExp(r'^\d+$').hasMatch(content)) {
          setState(() {
            errorMessage = 'EAN-13 requires numeric values only';
          });
          return content;
        }
        if (content.length < 12) {
          setState(() {
            errorMessage = 'EAN-13 requires exactly 12 digits';
          });
          return content;
        }
        if (content.length == 12) {
          String checksum = _calculateEAN13Checksum(content);
          return content + checksum;
        }
        if (content.length == 13 && !_isValidBarcode(content, type)) {
          String correctChecksum =
              _calculateEAN13Checksum(content.substring(0, 12));
          setState(() {
            errorMessage =
                'Invalid EAN-13 checksum. The correct checksum should be: $correctChecksum';
          });
        }
        return content;

      case 'EAN-8':
        if (!RegExp(r'^\d+$').hasMatch(content)) {
          setState(() {
            errorMessage = 'EAN-8 requires numeric values only';
          });
          return content;
        }
        if (content.length < 7) {
          setState(() {
            errorMessage = 'EAN-8 requires exactly 7 digits';
          });
          return content;
        }
        if (content.length == 7) {
          String checksum = _calculateEAN8Checksum(content);
          return content + checksum;
        }
        if (content.length == 8 && !_isValidBarcode(content, type)) {
          String correctChecksum =
              _calculateEAN8Checksum(content.substring(0, 7));
          setState(() {
            errorMessage =
                'Invalid EAN-8 checksum. The correct checksum should be: $correctChecksum';
          });
        }
        return content;

      case 'UPC-E':
        if (!RegExp(r'^\d+$').hasMatch(content)) {
          setState(() {
            errorMessage = 'UPC-E requires numeric values only';
          });
          return content;
        }

        if (content.length == 7) {
          if (!_isValidUPCE(content)) {
            setState(() {
              errorMessage =
                  'Invalid UPC-E format. Must start with 0 and follow compression rules';
            });
            return content;
          }
          String checksum = _calculateUPCEChecksum(content);
          return content + checksum;
        }

        if (content.length == 8) {
          String data = content.substring(0, 7);
          if (!_isValidUPCE(data)) {
            setState(() {
              errorMessage =
                  'Invalid UPC-E format. Must start with 0 and follow compression rules';
            });
            return content;
          }

          String expectedChecksum = _calculateUPCEChecksum(data);
          if (content[7] != expectedChecksum) {
            setState(() {
              errorMessage =
                  'Invalid UPC-E checksum. The correct checksum should be: $expectedChecksum';
            });
          }
        }

        if (content.length < 7) {
          setState(() {
            errorMessage = 'UPC-E requires exactly 7 digits';
          });
        }

        return content;

      case 'Code 39':
        if (!RegExp(r'^[0-9A-Z\-. \$/+%]*$').hasMatch(content)) {
          setState(() {
            errorMessage =
                'Code 39 only supports uppercase letters, numbers, and special characters (-, ., space, \$, /, +, %)';
          });
        }
        return content;

      default:
        return content;
    }
  }

  Barcode _getBarcodeType(String type) {
    switch (type) {
      case 'Code 128':
        return Barcode.code128();
      case 'Code 39':
        return Barcode.code39();
      case 'Code 93':
        return Barcode.code93();
      case 'CODABAR':
        return Barcode.codabar();
      case 'EAN-13':
        return Barcode.ean13();
      case 'EAN-8':
        return Barcode.ean8();
      case 'UPC-A':
        return Barcode.upcA();
      case 'UPC-E':
        return Barcode.upcE();
      case 'ITF-14':
        return Barcode.itf14();
      case 'PDF417':
        return Barcode.pdf417();
      case 'Data Matrix':
        return Barcode.dataMatrix();
      case 'AZTEC':
        return Barcode.aztec();
      default:
        return Barcode.code128();
    }
  }

  Future<void> _saveQRImage(BuildContext context, GlobalKey qrKey) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Storage permission is required to save barcode')),
        );
        return;
      }

      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture barcode')),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process barcode image')),
        );
        return;
      }

      // Get the downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access storage directory')),
        );
        return;
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath =
          '${directory.path}/barcode_${widget.type}_$timestamp.png';
      final buffer = byteData.buffer.asUint8List();
      final file = File(imagePath);

      await file.writeAsBytes(buffer);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode saved successfully to Downloads'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () async {
              // Try to open the containing folder
              final uri = Uri.file(directory.path);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save barcode: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrKey = GlobalKey();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Barcode Result',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: Colors.indigo,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              Text(
                widget.type,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              if (errorMessage != null)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text(
                'Barcode has been Created',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16),
                    child: errorMessage == null
                        ? BarcodeWidget(
                            barcode: barcodeType,
                            data: barcodeData,
                            width: 300,
                            height: 150,
                            drawText: true,
                          )
                        : Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Colors.red,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              if (errorMessage == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.download,
                      label: 'Save Barcode',
                      onTap: () => _saveQRImage(context, qrKey),
                    ),
                    _buildActionButton(
                      icon: Icons.qr_code,
                      label: 'Share Barcode',
                      onTap: () => Share.share(barcodeData),
                    ),
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Share Text',
                      onTap: () => Share.share(barcodeData),
                    ),
                  ],
                ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Type: ${widget.type}\nText: $barcodeData',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
