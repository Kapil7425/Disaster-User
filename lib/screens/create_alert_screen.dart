import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/emergency_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class CreateAlertScreen extends StatefulWidget {
  final UserModel user;

  const CreateAlertScreen({super.key, required this.user});

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedType = 'OTHER';
  String _selectedSeverity = 'MEDIUM';
  double _range = 5.0;
  bool _isLoading = false;
  Position? _currentPosition;

  final List<Map<String, dynamic>> _alertTypes = [
    {'value': 'FIRE', 'label': 'Fire', 'icon': '🔥'},
    {'value': 'FLOOD', 'label': 'Flood', 'icon': '🌊'},
    {'value': 'EARTHQUAKE', 'label': 'Earthquake', 'icon': '🌍'},
    {'value': 'ACCIDENT', 'label': 'Accident', 'icon': '🚗'},
    {'value': 'MEDICAL', 'label': 'Medical Emergency', 'icon': '🏥'},
    {'value': 'BRIDGE_COLLAPSE', 'label': 'Bridge Collapse', 'icon': '🌉'},
    {'value': 'BUILDING_COLLAPSE', 'label': 'Building Collapse', 'icon': '🏢'},
    {'value': 'LANDSLIDE', 'label': 'Landslide', 'icon': '⛰️'},
    {'value': 'TORNADO', 'label': 'Tornado', 'icon': '🌪️'},
    {'value': 'HURRICANE', 'label': 'Hurricane', 'icon': '🌀'},
    {'value': 'OTHER', 'label': 'Other', 'icon': '⚠️'},
  ];

  final List<Map<String, dynamic>> _severityLevels = [
    {'value': 'LOW', 'label': 'Low', 'color': Colors.green},
    {'value': 'MEDIUM', 'label': 'Medium', 'color': Colors.orange},
    {'value': 'HIGH', 'label': 'High', 'color': Colors.deepOrange},
    {'value': 'CRITICAL', 'label': 'Critical', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _createAlert() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting your location... Please wait'),
          backgroundColor: Colors.orange,
        ),
      );
      await _getCurrentLocation();
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get location. Please enable GPS'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final token = await AuthService.getToken();

    final result = await EmergencyService.createAlert(
      userId: widget.user.id,
      token: token ?? '',
      type: _selectedType,
      message: _messageController.text.trim(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      address: _addressController.text.trim(),
      range: _range,
      severity: _selectedSeverity,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final notifiedCount = result['data']['notifiedCount'] ?? 0;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Emergency alert sent successfully!\n$notifiedCount nearby users notified',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to create alert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Emergency Alert'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alert Type Selection
              const Text(
                'Emergency Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _alertTypes.map((type) {
                  final isSelected = _selectedType == type['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type['value']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red.shade700 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${type['icon']} ${type['label']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Message
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Emergency Message *',
                  hintText: 'Describe the emergency situation...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  if (value.trim().length < 10) {
                    return 'Message must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Location/Address',
                  hintText: 'Enter location details (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 24),

              // Severity Selection
              const Text(
                'Severity Level',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _severityLevels.map((severity) {
                  final isSelected = _selectedSeverity == severity['value'];
                  return ChoiceChip(
                    label: Text(severity['label']),
                    selected: isSelected,
                    selectedColor: severity['color'],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedSeverity = severity['value']);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Range Slider
              const Text(
                'Alert Range',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _range,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${_range.toInt()} km',
                      onChanged: (value) => setState(() => _range = value),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_range.toInt()} km',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Users within ${_range.toInt()}km will be notified',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Location Info
              if (_currentPosition != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2),
                      const SizedBox(width: 8),
                      Text(
                        'Getting your location...',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '🚨 Send Emergency Alert',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 16),

              // Warning Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber, color: Colors.yellow.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will send immediate notifications to all nearby users and authorities. Only use for genuine emergencies.',
                        style: TextStyle(fontSize: 12, color: Colors.yellow.shade900),
                      ),
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
}
