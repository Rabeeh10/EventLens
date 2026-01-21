import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';

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
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  File? _selectedStallImage;
  File? _selectedMarkerImage;

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

  /// Check if marker_id already exists in Firestore (globally unique)
  Future<bool> _isMarkerIdUnique(String markerId) async {
    try {
      final existingStall = await _firestoreService.fetchStallByMarkerId(
        markerId,
      );
      return existingStall == null; // Unique if no existing stall found
    } catch (e) {
      // If error occurs during check, assume not unique to be safe
      return false;
    }
  }

  /// Pick stall image from gallery
  Future<void> _pickStallImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedStallImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick AR marker reference image from gallery
  Future<void> _pickMarkerImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90, // Higher quality for AR recognition
      );

      if (image != null) {
        setState(() {
          _selectedMarkerImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking marker image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      // Validate marker_id is globally unique
      final markerId = _markerIdController.text.trim();
      final isUnique = await _isMarkerIdUnique(markerId);
      if (!isUnique) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Marker ID "$markerId" already exists. Please use a unique ID.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Validate event exists (defensive check)
      final events = await _firestoreService.fetchEvents();
      final eventExists = events.any((e) => e['event_id'] == widget.eventId);
      if (!eventExists) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error: Parent event no longer exists. Please refresh.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Generate stall ID for image upload paths
      final tempStallId = 'stall_${DateTime.now().millisecondsSinceEpoch}';

      // Upload stall image if selected
      String? stallImageUrl;
      if (_selectedStallImage != null) {
        stallImageUrl = await _storageService.uploadStallImage(
          stallId: tempStallId,
          imageFile: _selectedStallImage!,
        );
      }

      // Upload marker reference image if selected
      String? markerImageUrl;
      if (_selectedMarkerImage != null) {
        markerImageUrl = await _storageService.uploadMarkerImage(
          markerId: markerId,
          imageFile: _selectedMarkerImage!,
        );
      }

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
        markerId: markerId,
        location: location,
        images: stallImageUrl != null ? [stallImageUrl] : [],
        arModelUrl: markerImageUrl,
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
                  value: _categoryController.text.isEmpty
                      ? null
                      : _categoryController.text,
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
                    hintText:
                        'What products or services does this stall offer?',
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude *',
                    hintText: 'e.g., -122.4194',
                    prefixIcon: Icon(Icons.gps_not_fixed),
                  ),
                ),
                const SizedBox(height: 32),

                // Image Upload Section
                Text(
                  'Stall Media',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Stall Image
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stall Image (Optional)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedStallImage != null)
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedStallImage!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickStallImage,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Change'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() => _selectedStallImage = null);
                                  },
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Remove'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _pickStallImage,
                          icon: const Icon(Icons.add_photo_alternate, size: 20),
                          label: const Text('Upload Stall Image'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // AR Marker Reference Image
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AR Marker Reference (Optional)',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload the physical marker image for AR recognition',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedMarkerImage != null)
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedMarkerImage!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                color: Colors.black.withOpacity(0.1),
                                colorBlendMode: BlendMode.darken,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickMarkerImage,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Change'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() => _selectedMarkerImage = null);
                                  },
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Remove'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _pickMarkerImage,
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: const Text('Upload Marker Image'),
                        ),
                    ],
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
