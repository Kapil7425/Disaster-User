import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/weather_service.dart';
import '../services/emergency_service.dart';
import 'login_screen.dart';
import 'create_alert_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late UserModel _currentUser;
  bool _isLoading = false;

  // Weather state
  WeatherData? _weather;
  bool _weatherLoading = true;

  // Nearby alerts state
  List<dynamic> _nearbyAlerts = [];
  bool _alertsLoading = true;

  // GPS position
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _initAll();
  }

  Future<void> _initAll() async {
    await _getLocation();
    await Future.wait([_loadWeather(), _loadNearbyAlerts()]);
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) setState(() => _currentPosition = pos);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadWeather() async {
    if (mounted) setState(() => _weatherLoading = true);
    try {
      final lat = _currentPosition?.latitude ?? _currentUser.latitude;
      final lon = _currentPosition?.longitude ?? _currentUser.longitude;
      if (lat == 0 && lon == 0) {
        if (mounted) setState(() => _weatherLoading = false);
        return;
      }
      final weather = await WeatherService.getWeatherByCoords(lat, lon);
      if (mounted) setState(() { _weather = weather; _weatherLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  Future<void> _loadNearbyAlerts() async {
    if (mounted) setState(() => _alertsLoading = true);
    try {
      final lat = _currentPosition?.latitude ?? _currentUser.latitude;
      final lon = _currentPosition?.longitude ?? _currentUser.longitude;
      Map<String, dynamic> result;
      if (lat != 0 && lon != 0) {
        result = await EmergencyService.getNearbyAlerts(
          latitude: lat,
          longitude: lon,
          range: 50,
        );
      } else {
        result = await EmergencyService.getAllAlerts();
      }
      if (mounted) {
        setState(() {
          _nearbyAlerts = result['data'] ?? [];
          _alertsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _alertsLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    await _getLocation();
    await Future.wait([_loadWeather(), _loadNearbyAlerts()]);
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
      if (token != null) await ApiService.logout(token);
      await AuthService.clearAuth();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title:  IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "Profile",
              barrierColor: Colors.black26,
              transitionDuration: const Duration(milliseconds: 300),

              pageBuilder: (context, animation, secondaryAnimation) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.only(
                        top: kToolbarHeight +
                            MediaQuery.of(context).padding.top,
                      ),
                      width: double.infinity, // ✅ full width
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // ✅ auto height
                        children: [
                          _buildHeader(), // your existing header widget
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },

              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -1), // slide from top
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
            );
          },
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildWeatherCard(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSOSButton(),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildNearbyAlerts(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Header ───────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Text(
              _currentUser.name.isNotEmpty
                  ? _currentUser.name[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(fontSize: 13, color: Colors.orange.shade100),
                ),
                Text(
                  _currentUser.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      _currentUser.phone,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Weather Card ─────────────────────────
  Widget _buildWeatherCard() {
    if (_weatherLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading weather...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    }

    if (_weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.blueGrey),
            SizedBox(width: 12),
            Text('Weather unavailable', style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
      );
    }

    final w = _weather!;
    final emoji = WeatherService.getWeatherEmoji(w.condition);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _weatherGradient(w.condition),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(w.city,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${w.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    w.description[0].toUpperCase() + w.description.substring(1),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Feels like ${w.feelsLike.toStringAsFixed(1)}°C',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Text(emoji, style: const TextStyle(fontSize: 72)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _wStat('💧', 'Humidity', '${w.humidity}%'),
              _wStat('💨', 'Wind', '${w.windSpeed.toStringAsFixed(1)} m/s'),
              _wStat('🌡️', 'Condition', w.condition),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _weatherGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return [Colors.orange.shade400, Colors.yellow.shade700];
      case 'clouds':
        return [Colors.blueGrey.shade400, Colors.blueGrey.shade700];
      case 'rain':
      case 'drizzle':
        return [Colors.blue.shade600, Colors.indigo.shade700];
      case 'thunderstorm':
        return [Colors.grey.shade700, Colors.grey.shade900];
      case 'snow':
        return [Colors.lightBlue.shade300, Colors.blue.shade400];
      default:
        return [Colors.blue.shade400, Colors.blue.shade700];
    }
  }

  Widget _wStat(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── SOS Button ───────────────────────────
  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CreateAlertScreen(user: _currentUser)),
        );
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Emergency alert sent! Refreshing...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          await _loadNearbyAlerts();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade900],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade300,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.sos, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEND EMERGENCY ALERT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Center(
                  child: Text('Tap to report a disaster',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Nearby Alerts ────────────────────────
  Widget _buildNearbyAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning_amber,
                      color: Colors.red.shade700, size: 18),
                ),
                const SizedBox(width: 8),
                const Text('Nearby Alerts',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            if (!_alertsLoading)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _nearbyAlerts.isEmpty
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_nearbyAlerts.length} active',
                  style: TextStyle(
                    fontSize: 12,
                    color: _nearbyAlerts.isEmpty
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_alertsLoading)
          const Center(child: CircularProgressIndicator())
        else if (_nearbyAlerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('No active alerts nearby. Stay safe!',
                    style: TextStyle(color: Colors.green, fontSize: 15)),
              ],
            ),
          )
        else
          ...(_nearbyAlerts.map((alert) => _buildAlertCard(alert)).toList()),
      ],
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    final type = (alert['type'] ?? 'OTHER') as String;
    final message = (alert['message'] ?? '') as String;
    final severity = (alert['severity'] ?? 'MEDIUM') as String;
    final address = (alert['address'] ?? '') as String;
    final range = alert['range'] ?? 5;
    final userName = alert['user']?['name'] ?? 'Unknown';
    final createdAt =
        alert['createdAt'] != null ? _timeAgo(alert['createdAt']) : '';

    final severityColor = _severityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: severityColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_alertEmoji(type), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.replaceAll('_', ' '),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'by $userName · $createdAt',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                        color: severityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(message,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(address,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Icon(Icons.radar, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('${range}km',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _alertEmoji(String type) {
    const map = {
      'FIRE': '🔥', 'FLOOD': '🌊', 'EARTHQUAKE': '🌍',
      'ACCIDENT': '🚗', 'MEDICAL': '🏥', 'BRIDGE_COLLAPSE': '🌉',
      'BUILDING_COLLAPSE': '🏢', 'LANDSLIDE': '⛰️',
      'TORNADO': '🌪️', 'HURRICANE': '🌀',
    };
    return map[type] ?? '⚠️';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'CRITICAL': return Colors.red.shade800;
      case 'HIGH': return Colors.red;
      case 'MEDIUM': return Colors.orange;
      case 'LOW': return Colors.green;
      default: return Colors.orange;
    }
  }

  String _timeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

