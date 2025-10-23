import 'package:flutter/material.dart';

class NetworkErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No internet connection.\nPlease check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
