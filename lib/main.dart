import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timeline_tile/timeline_tile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dashcam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const MyHomePage(title: 'Dashcam Live View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _clips = [];

  @override
  void initState() {
    super.initState();
    _fetchClips();
  }

  Future<void> _fetchClips() async {
    final response = await http.get(
        Uri.parse('https://66a503295dc27a3c190a6ab1.mockapi.io/api/clips'));
    if (response.statusCode == 200) {
      final List<dynamic> clips = json.decode(response.body);
      setState(() {
        _clips = clips.map((clip) {
          return {
            'clipUrl': clip['clipUrl'],
            'thumbnailUrl': clip['thumbnailUrl'],
            'createdAt': clip['createdAt'], // Add createdAt field
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load clips');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchClips,
            tooltip: 'Refresh Clips',
          ),
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapPage()),
              );
            },
            tooltip: 'Switch to Map View',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
            ),
            child: Stack(
              children: [
                Mjpeg(
                  stream: 'http://192.168.1.23:8080/stream',
                  isLive: true,
                ),
                Center(child: CircularProgressIndicator()),
                // Add an overlay or play button here if needed
              ],
            ),
          ),
          Expanded(
            child: _clips.isNotEmpty
                ? _buildTimeline()
                : const Center(child: Text('No events available')),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      itemCount: _clips.length,
      itemBuilder: (context, index) {
        final clip = _clips[index];
        final isFirst = index == 0;
        final isLast = index == _clips.length - 1;

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 40,
            color: Colors.deepPurple,
            iconStyle:
                IconStyle(iconData: Icons.play_arrow, color: Colors.white),
            padding: EdgeInsets.all(8),
          ),
          beforeLineStyle: LineStyle(
            color: Colors.deepPurple,
            thickness: 4,
          ),
          afterLineStyle: LineStyle(
            color: Colors.deepPurple,
            thickness: 4,
          ),
          endChild: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipThumbnail(
              url: clip['thumbnailUrl'] as String,
              clipUrl: clip['clipUrl'] as String,
              createdAt: clip['createdAt'] as String,
            ),
          ),
        );
      },
    );
  }
}

class ClipThumbnail extends StatelessWidget {
  final String url;
  final String clipUrl;
  final String createdAt;

  const ClipThumbnail({
    super.key,
    required this.url,
    required this.clipUrl,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Created At:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                createdAt, // Display the creation date
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        SizedBox(width: 16), // Space between thumbnail and text

        Container(
          width: 225, // Adjust width as needed
          height: 150, // Adjust height as needed
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

class ClipDetailPage extends StatelessWidget {
  final String url;

  const ClipDetailPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clip Detail')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Clip URL: $url'),
            // You can add a video player widget here
          ],
        ),
      ),
    );
  }
}

// Map Page
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map View')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target:
              LatLng(37.7749, -122.4194), // Default location (San Francisco)
          zoom: 10,
        ),
        onMapCreated: (GoogleMapController controller) {
          // Handle map creation if needed
        },
      ),
    );
  }
}
