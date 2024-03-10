import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My App'),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, kToolbarHeight + 16.0, 16.0, 0),
          child: ListView(
            children: [
              SongCard(
                title: 'Song Title 1',
                duration: '3:45',
              ),
              SizedBox(height: 16),
              SongCard(
                title: 'Song Title 2',
                duration: '4:20',
              ),
              SizedBox(height: 16),
              SongCard(
                title: 'Song Title 3',
                duration: '5:10',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Color.fromARGB(255, 5, 122, 255),
        onTap: (index) {},
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

class SongCard extends StatelessWidget {
  final String title;
  final String duration;

  const SongCard({
    required this.title,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ListTile(
            leading: Icon(Icons.music_note, color: Colors.white),
            title: Text(title, style: TextStyle(color: Colors.white)),
            subtitle: Text(duration, style: TextStyle(color: Colors.white)),
            trailing: IconButton(
              icon: Icon(Icons.play_arrow, color: Colors.white),
              onPressed: () {
                // Add your play functionality here
              },
            ),
          ),
        ),
      ),
    );
  }
}

