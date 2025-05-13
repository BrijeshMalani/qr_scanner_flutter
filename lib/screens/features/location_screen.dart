import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'location_result_screen.dart';
import '../../utils/colors.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Validate latitude (-90 to 90)
  String? _validateLatitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter latitude';
    }
    try {
      final latitude = double.parse(value.replaceAll(',', '.'));
      if (latitude < -90 || latitude > 90) {
        return 'Latitude must be between -90 and 90';
      }
    } catch (e) {
      return 'Please enter a valid number';
    }
    return null;
  }

  // Validate longitude (-180 to 180)
  String? _validateLongitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter longitude';
    }
    try {
      final longitude = double.parse(value.replaceAll(',', '.'));
      if (longitude < -180 || longitude > 180) {
        return 'Longitude must be between -180 and 180';
      }
    } catch (e) {
      return 'Please enter a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
          'Location',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primaryColor,
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                SizedBox(height: 40),
                TextFormField(
                  controller: _latitudeController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-\.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Latitude (-90 to 90)',
                    labelStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    hintText: 'Example: 51.5074',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.5),
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
                        color: AppColors.primaryColor,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  validator: _validateLatitude,
                  onChanged: (value) {
                    if (value.contains(',')) {
                      _latitudeController.text = value.replaceAll(',', '.');
                      _latitudeController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: _latitudeController.text.length),
                      );
                    }
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _longitudeController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-\.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Longitude (-180 to 180)',
                    labelStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    hintText: 'Example: -0.1278',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.5),
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
                        color: AppColors.primaryColor,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  validator: _validateLongitude,
                  onChanged: (value) {
                    if (value.contains(',')) {
                      _longitudeController.text = value.replaceAll(',', '.');
                      _longitudeController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: _longitudeController.text.length),
                      );
                    }
                  },
                ),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationResultScreen(
                              latitude: double.parse(_latitudeController.text
                                  .replaceAll(',', '.')),
                              longitude: double.parse(_longitudeController.text
                                  .replaceAll(',', '.')),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create',
                      style: TextStyle(
                        color: Colors.white,
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
      ),
    );
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}
