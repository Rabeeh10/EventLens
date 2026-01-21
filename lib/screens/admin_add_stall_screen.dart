import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

/// Admin screen for adding new stalls to an event.
/// 
/// Collects stall details including AR marker ID for scanning.
class AdminAddStallScreen extends StatefulWidget {
  final String eventId;
  final String eventName;

  const AdminAddStallScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<AdminAddStallScreen> createState() => _AdminAddStallScreenState();
}

class _AdminAddStallScreenState extends State<AdminAddStallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _markerIdController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _zoneController = TextEditingController();
  
  bool _isLoading = false;

  final List<String> _categories = [
    'Technology',
    'Food & Beverage',
    'Retail',
    'Services',
    'Entertainment',
    'Education',
    'Health & Wellness',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _markerIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stall name is required';
    }
    if (value.trim().length < 2) {
      return 'Stall name must be at least 2 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? _validateMarkerId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Marker ID is required for AR scanning';
    }
    if (value.trim().length < 3) {
      return 'Marker ID must be at least 3 characters';
    }
    // Check for valid format (alphanumeric with underscores/hyphens)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Marker ID must be alphanumeric (a-z, 0-9, _, -)';
    }
    return null;
  }

  String? _validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }
    final latitude = double.tryParse(value);
    if (latitude == null) {
      return 'Invalid latitude format';
    }
    if (latitude < -90 || latitude > 90) {
      return 'Latitude must be between -90 and 90';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }
    final longitude = double.tryParse(value);
    if (longitude == null) {
      return 'Invalid longitude format';
    }
    if (longitude < -180 || longitude > 180) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all validation errors'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final location = {
        'latitude': double.parse(_latitudeController.text.trim()),
        'longitude': double.parse(_longitudeController.text.trim()),
        'zone': _zoneController.text.trim(),
      };

      final stallId = await _firestoreService.addStall(
        eventId: widget.eventId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        markerId: _markerIdController.text.trim(),
        location: location,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (stallId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Stall created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create stall. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Stall'),
            Text(
              widget.eventName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.store_mall_directory,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Create New Stall',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Add a vendor booth or exhibitor space',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Stall Name
                TextFormField(
                  controller: _nameController,
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Stall Name *',
                    hintText: 'e.g., Samsung Electronics',
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Category
                DropdownButtonFormField<String>(
                  value: _categoryController.text.isEmpty ? null : _categoryController.text,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _categoryController.text = value ?? '');
                  },
                ),
                const SizedBox(height: 20),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  validator: _validateDescription,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'What products or services does this stall offer?',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                
                // AR Marker Section
                Text(
                  'AR Marker Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This ID links physical AR markers to digital stall info',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                
                // Marker ID
                TextFormField(
                  controller: _markerIdController,
                  validator: _validateMarkerId,
                  decoration: const InputDecoration(
                    labelText: 'Marker ID *',
                    hintText: 'e.g., MKR_001 or BOOTH_A1',
                    prefixIcon: Icon(Icons.qr_code_2),
                    helperText: 'Unique ID for AR marker scanning',
                  ),
                ),
                const SizedBox(height: 32),
                
                // Location Section
                Text(
                  'Location Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                
                // Zone
                TextFormField(
                  controller: _zoneController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Zone/Hall',
                    hintText: 'e.g., Hall A, Zone 3',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Latitude
                TextFormField(
                  controller: _latitudeController,
                  validator: _validateLatitude,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude *',
                    hintText: 'e.g., 37.7749',
                    prefixIcon: Icon(Icons.gps_fixed),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Longitude
                TextFormField(
                  controller: _longitudeController,
                  validator: _validateLongitude,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude *',
                    hintText: 'e.g., -122.4194',
                    prefixIcon: Icon(Icons.gps_not_fixed),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Stall',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  '* Required fields',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
