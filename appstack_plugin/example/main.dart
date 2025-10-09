import 'package:flutter/material.dart';
import 'package:appstack_plugin/appstack_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Not configured';
  bool _isConfigured = false;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set a placeholder API key for demonstration
    _apiKeyController.text = 'your-api-key-here';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _configureSDK() async {
    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _status = 'Error: Please enter an API key';
      });
      return;
    }

    setState(() {
      _status = 'Configuring...';
    });

    try {
      final success = await AppstackPlugin.configure(
        _apiKeyController.text,
        isDebug: true, // Enable debug mode for this example
        logLevel: 0, // DEBUG level
      );

      setState(() {
        _isConfigured = success;
        _status = success ? 'SDK configured successfully!' : 'Failed to configure SDK';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _sendEvent(EventType eventType, {String? eventName, double? revenue}) async {
    if (!_isConfigured) {
      setState(() {
        _status = 'Please configure the SDK first';
      });
      return;
    }

    try {
      final success = await AppstackPlugin.sendEvent(
        eventType,
        eventName: eventName,
        revenue: revenue,
      );

      setState(() {
        _status = success 
          ? 'Event sent: ${eventType.name}${eventName != null ? ' ($eventName)' : ''}${revenue != null ? ' (Revenue: \$${revenue.toStringAsFixed(2)})' : ''}'
          : 'Failed to send event';
      });
    } catch (e) {
      setState(() {
        _status = 'Error sending event: $e';
      });
    }
  }

  Future<void> _enableAppleAdsAttribution() async {
    if (!_isConfigured) {
      setState(() {
        _status = 'Please configure the SDK first';
      });
      return;
    }

    try {
      final success = await AppstackPlugin.enableAppleAdsAttribution();
      setState(() {
        _status = success 
          ? 'Apple Ads Attribution enabled successfully!'
          : 'Failed to enable Apple Ads Attribution';
      });
    } catch (e) {
      setState(() {
        _status = 'Error enabling Apple Ads Attribution: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appstack Plugin Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Appstack Plugin Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Configuration Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SDK Configuration',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'API Key',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your Appstack API key',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _configureSDK,
                        child: const Text('Configure SDK'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Status Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_status),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Event Buttons
              if (_isConfigured) ...[
                const Text(
                  'Send Events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Lifecycle Events
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.install),
                      child: const Text('Install'),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.login),
                      child: const Text('Login'),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.signUp),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Monetization Events
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.purchase, revenue: 29.99),
                      child: const Text('Purchase (\$29.99)'),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.addToCart),
                      child: const Text('Add to Cart'),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.subscribe, revenue: 9.99),
                      child: const Text('Subscribe (\$9.99)'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Engagement Events
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.tutorialComplete),
                      child: const Text('Tutorial Complete'),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.viewItem, eventName: 'Product View'),
                      child: const Text('View Item'),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.search, eventName: 'Search Query'),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Custom Event
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _sendEvent(EventType.custom, eventName: 'Custom Event'),
                      child: const Text('Custom Event'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Apple Ads Attribution (iOS only)
                ElevatedButton(
                  onPressed: _enableAppleAdsAttribution,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enable Apple Ads Attribution (iOS only)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
