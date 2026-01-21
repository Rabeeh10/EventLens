import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

/// Admin screen for editing existing stalls.
///
/// Pre-fills form with existing stall data and allows updates.
class AdminEditStallScreen extends StatefulWidget {
  final Map<String, dynamic> stall;

  const AdminEditStallScreen({super.key, required this.stall});

  @override
  State<AdminEditStallScreen> createState() => _AdminEditStallScreenState();
}

class _AdminEditStallScreenState extends State<AdminEditStallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _markerIdController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _zoneController;

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
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.stall['name'] ?? '');
    _categoryController = TextEditingController(
      text: widget.stall['category'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.stall['description'] ?? '',
    );
    _markerIdController = TextEditingController(
      text: widget.stall['marker_id'] ?? '',
    );

    final location = widget.stall['location'] as Map<String, dynamic>?;
    _latitudeController = TextEditingController(
      text: location?['latitude']?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: location?['longitude']?.toString() ?? '',
    );
    _zoneController = TextEditingController(
      text: location?['zone']?.toString() ?? '',
    );
  }

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

  /// Check if marker_id already exists in Firestore (excluding current stall)
  Future<bool> _isMarkerIdUnique(String markerId, String currentStallId) async {
    try {
      final existingStall = await _firestoreService.fetchStallByMarkerId(
        markerId,
      );
      if (existingStall == null) {
        return true; // No stall with this marker_id exists
      }
      // If exists, check if it's the current stall being edited
      return existingStall['stall_id'] == currentStallId;
    } catch (e) {
      // If error occurs during check, assume not unique to be safe
      return false;
    }
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
      // Validate marker_id is globally unique (excluding current stall)
      final markerId = _markerIdController.text.trim();
      final stallId = widget.stall['stall_id'] as String;
      final isUnique = await _isMarkerIdUnique(markerId, stallId);

      if (!isUnique) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Marker ID "$markerId" is already used by another stall. Please use a unique ID.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'marker_id': markerId,
        'location': {
          'latitude': double.parse(_latitudeController.text.trim()),
          'longitude': double.parse(_longitudeController.text.trim()),
          'zone': _zoneController.text.trim(),
        },
      };

      final success = await _firestoreService.updateStall(stallId, updates);

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Stall updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update stall. Please try again.'),
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
      appBar: AppBar(title: const Text('Edit Stall')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.edit_location_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                Text(
                  'Edit Stall Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Stall Name *',
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _categories.contains(_categoryController.text)
                      ? _categoryController.text
                      : null,
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

                TextFormField(
                  controller: _descriptionController,
                  validator: _validateDescription,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'AR Marker Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _markerIdController,
                  validator: _validateMarkerId,
                  decoration: const InputDecoration(
                    labelText: 'Marker ID *',
                    prefixIcon: Icon(Icons.qr_code_2),
                    helperText: 'Unique ID for AR marker scanning',
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Location Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _zoneController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Zone/Hall',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _latitudeController,
                  validator: _validateLatitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude *',
                    prefixIcon: Icon(Icons.gps_fixed),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _longitudeController,
                  validator: _validateLongitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude *',
                    prefixIcon: Icon(Icons.gps_not_fixed),
                  ),
                ),
                const SizedBox(height: 32),

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
                            'Update Stall',
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
