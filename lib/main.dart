import 'package:material_ui/material_ui.dart';
import 'screens/events_page.dart';
import 'screens/garden_page.dart';

void main() {
  runApp(const GrowYourGardenApp());
}

class GrowYourGardenApp extends StatelessWidget {
  const GrowYourGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grow Your Garden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF287A49)),
        scaffoldBackgroundColor: const Color(0xFFFFFCF7),
        useMaterial3: true,
      ),
      initialRoute: '/garden',
      routes: {
        '/': (context) => const HomePage(),
        '/garden': (context) => const GardenPage(),
        '/events': (context) => const EventsPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grow Your Garden')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.spa_outlined,
                size: 72,
                color: Color(0xFF287A49),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Grow Your Garden!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/garden');
                },
                icon: const Icon(Icons.spa),
                label: const Text('Explore Garden'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/events');
                },
                icon: const Icon(Icons.event_outlined),
                label: const Text('See events'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
