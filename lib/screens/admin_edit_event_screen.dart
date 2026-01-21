import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

/// Admin screen for editing existing events.
/// 
/// Pre-fills form with existing event data and allows updates.
/// Validates all changes before saving to Firestore.
class AdminEditEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const AdminEditEventScreen({
    super.key,
    required this.event,
  });

  @override
  State<AdminEditEventScreen> createState() => _AdminEditEventScreenState();
}

class _AdminEditEventScreenState extends State<AdminEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _organizerController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _imageUrlController;
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'upcoming';
  bool _isLoading = false;

  final List<String> _categories = [
    'Technology',
    'Music',
    'Sports',
    'Food & Beverage',
    'Arts & Culture',
    'Business',
    'Education',
    'Health & Wellness',
    'Other',
  ];

  final List<String> _statusOptions = [
    'upcoming',
    'active',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  /// Initializes controllers with existing event data
  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.event['name'] ?? '');
    _categoryController = TextEditingController(text: widget.event['category'] ?? '');
    _descriptionController = TextEditingController(text: widget.event['description'] ?? '');
    _organizerController = TextEditingController(text: widget.event['organizer'] ?? '');
    _imageUrlController = TextEditingController(text: widget.event['image_url'] ?? '');

    // Initialize location data
    final location = widget.event['location'] as Map<String, dynamic>?;
    _addressController = TextEditingController(
      text: location?['address']?.toString() ?? '',
    );
    _latitudeController = TextEditingController(
      text: location?['latitude']?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: location?['longitude']?.toString() ?? '',
    );

    // Initialize dates
    final startTimestamp = widget.event['start_date'] as Timestamp?;
    final endTimestamp = widget.event['end_date'] as Timestamp?;
    _startDate = startTimestamp?.toDate();
    _endDate = endTimestamp?.toDate();

    // Initialize status
    _selectedStatus = widget.event['status'] ?? 'upcoming';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _organizerController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  /// Validation methods (same as add screen)
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Event name is required';
    }
    if (value.trim().length < 3) {
      return 'Event name must be at least 3 characters';
    }
    if (value.length > 100) {
      return 'Event name must not exceed 100 characters';
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
    if (value.length > 1000) {
      return 'Description must not exceed 1000 characters';
    }
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category is required';
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

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final urlPattern = RegExp(r'^https?:\/\/.+\..+', caseSensitive: false);
    if (!urlPattern.hasMatch(value)) {
      return 'Invalid URL format (must start with http:// or https://)';
    }
    return null;
  }

  String? _validateDates() {
    if (_startDate == null) {
      return 'Start date is required';
    }
    if (_endDate == null) {
      return 'End date is required';
    }
    if (_endDate!.isBefore(_startDate!)) {
      return 'End date must be after start date';
    }
    return null;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    
    if (picked != null) {
      final time = await _selectTime();
      if (time != null) {
        setState(() {
          _startDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    
    if (picked != null) {
      final time = await _selectTime();
      if (time != null) {
        setState(() {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<TimeOfDay?> _selectTime() async {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  /// Handles form submission and updates event in Firestore
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

    final dateError = _validateDates();
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare update data
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'organizer': _organizerController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'status': _selectedStatus,
        'location': {
          'latitude': double.parse(_latitudeController.text.trim()),
          'longitude': double.parse(_longitudeController.text.trim()),
          'address': _addressController.text.trim(),
        },
        'start_date': Timestamp.fromDate(_startDate!),
        'end_date': Timestamp.fromDate(_endDate!),
      };

      // Update event in Firestore
      final eventId = widget.event['event_id'] as String;
      final success = await _firestoreService.updateEvent(eventId, updates);

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Event updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Return true to indicate successful update
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update event. Please try again.'),
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
        title: const Text('Edit Event'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
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
                  Icons.edit_note_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Edit Event Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Update event information below',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Event Name
                TextFormField(
                  controller: _nameController,
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Event Name *',
                    hintText: 'e.g., Tech Summit 2026',
                    prefixIcon: Icon(Icons.event),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _categories.contains(_categoryController.text) 
                      ? _categoryController.text 
                      : null,
                  validator: _validateCategory,
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
                    setState(() {
                      _categoryController.text = value ?? '';
                    });
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
                    hintText: 'Detailed event description...',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Organizer
                TextFormField(
                  controller: _organizerController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Organizer',
                    hintText: 'Event organizer name',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Start Date
                InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Date & Time *',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: _startDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _startDate = null),
                            )
                          : null,
                    ),
                    child: Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} ${_startDate!.hour}:${_startDate!.minute.toString().padLeft(2, '0')}'
                          : 'Select start date',
                      style: TextStyle(
                        color: _startDate != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // End Date
                InkWell(
                  onTap: _selectEndDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End Date & Time *',
                      prefixIcon: const Icon(Icons.event_available),
                      suffixIcon: _endDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _endDate = null),
                            )
                          : null,
                    ),
                    child: Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year} ${_endDate!.hour}:${_endDate!.minute.toString().padLeft(2, '0')}'
                          : 'Select end date',
                      style: TextStyle(
                        color: _endDate != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'upcoming';
                    });
                  },
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
                
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Event venue address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 20),
                
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
                
                // Optional Section
                Text(
                  'Optional Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _imageUrlController,
                  validator: _validateUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.image),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Update Button
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
                            'Update Event',
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
