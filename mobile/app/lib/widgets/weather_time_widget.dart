import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import '../services/weather_service.dart';
import '../services/sound_service.dart';
import 'dart:async';

class WeatherTimeWidget extends StatefulWidget {
  const WeatherTimeWidget({super.key});

  @override
  State<WeatherTimeWidget> createState() => _WeatherTimeWidgetState();
}

class _WeatherTimeWidgetState extends State<WeatherTimeWidget> {
  final WeatherService _weatherService = WeatherService();
  final SoundService _soundService = SoundService();
  
  Weather? _currentWeather;
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timeTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _weatherService.initialize();
    _loadWeatherData();
    _startTimeUpdater();
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  void _startTimeUpdater() {
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = _weatherService.getCurrentTime();
        _currentDate = _weatherService.getCurrentDate();
      });
    }
  }

  Future<void> _loadWeatherData() async {
    try {
      final weather = await _weatherService.getCurrentWeather();
      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onRefreshTap() {
    _soundService.playRefresh();
    setState(() {
      _isLoading = true;
    });
    _loadWeatherData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Time and Date Section
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTime,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          
          // Weather Section
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: _onRefreshTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _weatherService.getWeatherIcon(_currentWeather),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _weatherService.getFormattedTemperature(_currentWeather),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weatherService.locationName,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'Geist',
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}