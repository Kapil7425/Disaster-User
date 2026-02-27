import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String city;
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final double feelsLike;
  final String condition; // Clear, Clouds, Rain, etc.

  WeatherData({
    required this.city,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.condition,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['name'] ?? 'Unknown',
      temperature: (json['main']['temp'] as num).toDouble() - 273.15, // Convert Kelvin to Celsius
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble() - 273.15,
      condition: json['weather'][0]['main'] ?? 'Clear',
    );
  }
}

class WeatherService {
  static const String _apiKey = 'dc661552602e65bb452373645bfdc5e5';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<WeatherData?> getWeatherByCoords(double lat, double lon) async {
    try {
      final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('WeatherService error: $e');
      return null;
    }
  }

  static String getWeatherEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      case 'sand':
      case 'dust':
        return '🌪️';
      default:
        return '🌤️';
    }
  }
}
