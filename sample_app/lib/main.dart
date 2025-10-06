import 'package:flutter/material.dart';
import 'package:appstack_plugin/appstack_plugin.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure Appstack SDK
  // Replace with your actual API keys
  final apiKey = Platform.isIOS 
      ? 'mff1e8e083990ep2p80bdnbc' 
      : 'yfueim3gw78vbhitonesie6w';

  final endpointBaseUrl = Platform.isIOS 
      ? 'https://api.event.dev.appstack.tech'
      : 'https://api.event.dev.appstack.tech/android/';
  
  try {
    await AppstackPlugin.configure(
      apiKey,
      isDebug: true,
      logLevel: 0, // DEBUG
      endpointBaseUrl: endpointBaseUrl,
    );
    
    // Enable Apple Search Ads attribution on iOS
    if (Platform.isIOS) {
      await AppstackPlugin.enableAppleAdsAttribution();
    }
    
    print('Appstack SDK configured successfully');
  } catch (e) {
    print('Failed to configure Appstack SDK: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _lastEvent = 'None';

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    
    // Track the button press event
    _trackEvent(EventType.custom, eventName: 'button_pressed');
  }
  
  void _trackEvent(EventType eventType, {String? eventName, double? revenue}) async {
    try {
      await AppstackPlugin.sendEvent(
        eventType,
        eventName: eventName,
        revenue: revenue,
      );
      setState(() {
        _lastEvent = eventName ?? eventType.name;
      });
      print('Event tracked: ${eventName ?? eventType.name}');
    } catch (e) {
      print('Failed to track event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Appstack SDK Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('You have pushed the button this many times:'),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text('Last event tracked: $_lastEvent'),
              const SizedBox(height: 40),
              const Text(
                'Try these events:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _trackEvent(EventType.signUp),
                    child: const Text('Sign Up'),
                  ),
                  ElevatedButton(
                    onPressed: () => _trackEvent(EventType.login),
                    child: const Text('Login'),
                  ),
                  ElevatedButton(
                    onPressed: () => _trackEvent(EventType.purchase, revenue: 29.99),
                    child: const Text('Purchase \$29.99'),
                  ),
                  ElevatedButton(
                    onPressed: () => _trackEvent(EventType.addToCart, revenue: 15.99),
                    child: const Text('Add to Cart \$15.99'),
                  ),
                  ElevatedButton(
                    onPressed: () => _trackEvent(EventType.viewItem),
                    child: const Text('View Item'),
                  ),
                  ElevatedButton(
                    onPressed: () => _trackEvent(EventType.custom, eventName: 'custom_event'),
                    child: const Text('Custom Event'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
