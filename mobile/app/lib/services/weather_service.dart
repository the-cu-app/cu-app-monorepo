import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // OpenWeatherMap API key - Replace with your own key
  static const String _apiKey = 'demo_api_key';
  
  WeatherFactory? _wf;
  Weather? _currentWeather;
  String? _locationName;

  // Initialize weather service
  void initialize() {
    _wf = WeatherFactory(_apiKey);
  }

  // Get current weather data
  Future<Weather?> getCurrentWeather() async {
    if (_currentWeather != null && 
        _currentWeather!.date != null && 
        DateTime.now().difference(_currentWeather!.date!).inMinutes < 30) {
      return _currentWeather;
    }

    try {
      final position = await _getCurrentLocation();
      if (position != null) {
        _currentWeather = await _wf?.currentWeatherByLocation(
          position.latitude, 
          position.longitude
        );
        
        // Get location name
        final placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _locationName = place.locality ?? place.administrativeArea ?? 'Unknown';
        }
        
        return _currentWeather;
      }
    } catch (e) {
      // Return mock weather data for demo
      return _getMockWeather();
    }
    
    return null;
  }

  // Get location name
  String get locationName => _locationName ?? 'Your Location';

  // Get formatted temperature
  String getFormattedTemperature(Weather? weather) {
    if (weather?.temperature == null) return '--°';
    return '${weather!.temperature!.celsius!.round()}°';
  }

  // Get weather condition text
  String getWeatherCondition(Weather? weather) {
    if (weather?.weatherDescription == null) return 'Loading...';
    return weather!.weatherDescription!;
  }

  // Get weather icon
  String getWeatherIcon(Weather? weather) {
    if (weather?.weatherIcon == null) return '☀️';
    
    switch (weather!.weatherIcon) {
      case '01d':
      case '01n':
        return '☀️';
      case '02d':
      case '02n':
      case '03d':
      case '03n':
        return '⛅';
      case '04d':
      case '04n':
        return '☁️';
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return '🌧️';
      case '11d':
      case '11n':
        return '⛈️';
      case '13d':
      case '13n':
        return '❄️';
      case '50d':
      case '50n':
        return '🌫️';
      default:
        return '☀️';
    }
  }

  // Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      return null;
    }
  }

  // Mock weather data for demo purposes
  Weather _getMockWeather() {
    return Weather({
      'coord': {'lon': -122.4194, 'lat': 37.7749},
      'weather': [
        {'id': 800, 'main': 'Clear', 'description': 'clear sky', 'icon': '01d'}
      ],
      'main': {
        'temp': 295.15, // 22°C
        'feels_like': 295.15,
        'temp_min': 293.15,
        'temp_max': 297.15,
        'pressure': 1013,
        'humidity': 60
      },
      'wind': {'speed': 3.5, 'deg': 240},
      'clouds': {'all': 0},
      'dt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'name': 'San Francisco'
    });
  }

  // Get current time formatted
  String getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Get current date formatted
  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';
  }
}