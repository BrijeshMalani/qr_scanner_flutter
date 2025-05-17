import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'barcode_result_screen.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({Key? key}) : super(key: key);

  @override
  _BarcodeScreenState createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final _textController = TextEditingController();
  String _selectedType = 'Code 128';
  String? _errorText;

  final Map<String, BarcodeFormat> _barcodeTypes = {
    'AZTEC': BarcodeFormat(
      name: 'AZTEC',
      regex: r'^[\x00-\xFF]*$',
      maxLength: 3832,
      description: 'Supports all ASCII characters',
    ),
    'CODABAR': BarcodeFormat(
      name: 'CODABAR',
      regex: r'^[0-9\-\$\:/\.\+]*$',
      maxLength: 50,
      description: 'Numbers, minus, dollar, colon, slash, dot, plus only',
    ),
    'Code 128': BarcodeFormat(
      name: 'Code 128',
      regex: r'^[\x00-\xFF]*$',
      maxLength: 80,
      description: 'Supports all ASCII characters',
    ),
    'Code 39': BarcodeFormat(
      name: 'Code 39',
      regex: r'^[0-9A-Z\-\.\s\$\/\+%]*$',
      maxLength: 50,
      description: 'Uppercase letters, numbers, and special characters',
    ),
    'Code 93': BarcodeFormat(
      name: 'Code 93',
      regex: r'^[0-9A-Z\-\.\s\$\/\+%]*$',
      maxLength: 50,
      description: 'Uppercase letters, numbers, and special characters',
    ),
    'Data Matrix': BarcodeFormat(
      name: 'Data Matrix',
      regex: r'^[\x00-\xFF]*$',
      maxLength: 2335,
      description: 'Supports all ASCII characters',
    ),
    'EAN-13': BarcodeFormat(
      name: 'EAN-13',
      regex: r'^\d{12}$',
      maxLength: 12,
      description: 'Exactly 12 digits (checksum will be added automatically)',
    ),
    'EAN-8': BarcodeFormat(
      name: 'EAN-8',
      regex: r'^\d{7}$',
      maxLength: 7,
      description: 'Exactly 7 digits (checksum will be added automatically)',
    ),
    'ITF-14': BarcodeFormat(
      name: 'ITF-14',
      regex: r'^\d{13}$',
      maxLength: 13,
      description: 'Exactly 13 digits (checksum will be added automatically)',
    ),
    'PDF417': BarcodeFormat(
      name: 'PDF417',
      regex: r'^[\x00-\xFF]*$',
      maxLength: 1850,
      description: 'Supports all ASCII characters',
    ),
    'UPC-A': BarcodeFormat(
      name: 'UPC-A',
      regex: r'^\d{11}$',
      maxLength: 11,
      description: 'Exactly 11 digits (checksum will be added automatically)',
    ),
    'UPC-E': BarcodeFormat(
      name: 'UPC-E',
      regex: r'^0\d{6}$',
      maxLength: 7,
      description:
          'Must start with 0 followed by 6 digits (checksum will be added automatically)',
    ),
  };

  bool _validateInput(String content, BarcodeFormat format) {
    if (content.isEmpty) {
      setState(() => _errorText = 'Content cannot be empty');
      return false;
    }

    if (content.length > format.maxLength) {
      setState(() => _errorText = format.description);
      return false;
    }

    if (!RegExp(format.regex).hasMatch(content)) {
      setState(() => _errorText = format.description);
      return false;
    }

    // Additional validation for numeric-only barcodes
    switch (format.name) {
      case 'EAN-13':
      case 'EAN-8':
      case 'UPC-A':
      case 'UPC-E':
      case 'ITF-14':
        if (content.length < format.maxLength) {
          setState(() => _errorText = format.description);
          return false;
        }
        break;
    }

    setState(() => _errorText = null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final selectedFormat = _barcodeTypes[_selectedType]!;

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
          'Barcode',
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
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Create Barcode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 40),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Barcode Type',
                  labelStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                items: _barcodeTypes.keys.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                    // Validate current input with new format
                    if (_textController.text.isNotEmpty) {
                      _validateInput(
                          _textController.text, _barcodeTypes[newValue]!);
                    }
                  });
                },
                dropdownColor: Theme.of(context).cardColor,
              ),
              SizedBox(height: 8),
              Text(
                selectedFormat.description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  labelStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                onChanged: (value) => _validateInput(value, selectedFormat),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    final content = _textController.text.trim();
                    if (_validateInput(content, selectedFormat)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BarcodeResultScreen(
                            content: content,
                            type: _selectedType,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create',
                    style: TextStyle(
                      color:
                          Theme.of(context).primaryTextTheme.labelLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class BarcodeFormat {
  final String name;
  final String regex;
  final int maxLength;
  final String description;

  const BarcodeFormat({
    required this.name,
    required this.regex,
    required this.maxLength,
    required this.description,
  });
}
