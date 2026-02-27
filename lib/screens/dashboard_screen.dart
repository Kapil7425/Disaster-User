import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late UserModel _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      final token = await AuthService.getToken();
      if (token != null) {
        await ApiService.logout(token);
      }

      await AuthService.clearAuth();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _refreshUserData() async {
    setState(() => _isLoading = true);

    final token = await AuthService.getToken();
    if (token != null) {
      final result = await ApiService.getCurrentUser(token);
      if (result['success']) {
        final updatedUser = UserModel.fromJson(result['data']['user']);
        await AuthService.saveUser(updatedUser);
        setState(() {
          _currentUser = updatedUser;
        });
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUserData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              _currentUser.name.isNotEmpty
                                  ? _currentUser.name[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentUser.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // User Details Cards
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoCard(
                            icon: Icons.phone,
                            title: 'Phone Number',
                            value: _currentUser.phone,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.location_on,
                            title: 'Current Location',
                            value: _currentUser.currentLocation.isNotEmpty
                                ? _currentUser.currentLocation
                                : '${_currentUser.latitude.toStringAsFixed(4)}, ${_currentUser.longitude.toStringAsFixed(4)}',
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.my_location,
                            title: 'Coordinates',
                            value: 'Lat: ${_currentUser.latitude.toStringAsFixed(6)}\nLng: ${_currentUser.longitude.toStringAsFixed(6)}',
                            color: Colors.purple,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.check_circle,
                            title: 'Account Status',
                            value: _currentUser.isActive ? 'Active' : 'Inactive',
                            color: _currentUser.isActive ? Colors.green : Colors.red,
                          ),
                          if (_currentUser.createdAt != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              icon: Icons.calendar_today,
                              title: 'Member Since',
                              value: _formatDate(_currentUser.createdAt!),
                              color: Colors.orange,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildActionButton(
                            icon: Icons.sos,
                            label: 'Emergency Request',
                            color: Colors.red,
                            onPressed: () {
                              // TODO: Navigate to emergency request screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Emergency request feature coming soon'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.warning,
                            label: 'View Disasters',
                            color: Colors.orange,
                            onPressed: () {
                              // TODO: Navigate to disasters list
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Disasters list feature coming soon'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.settings,
                            label: 'Settings',
                            color: Colors.grey,
                            onPressed: () {
                              // TODO: Navigate to settings
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Settings feature coming soon'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
