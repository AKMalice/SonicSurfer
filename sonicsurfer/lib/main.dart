import 'dart:ui';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';


import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  

  final List<Widget> _screens = [
    HomeScreen(),
    SearchPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Sonic Surfer',style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Color.fromARGB(255, 5, 122, 255),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/songs'));
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        // print(parsed);
        setState(() {
          _songs = parsed;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch songs';
        });
      }
    } catch (err) {
      setState(() {
        _error = 'An error occurred: $err';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


@override
Widget build(BuildContext context) {
  return Container(
    color: Colors.blue,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0 , 16.0, 0),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Text(_error, style: TextStyle(color: Colors.red))
              : ListView.builder(
                  itemCount: _songs.length + 1, // Add 1 for the featured tag
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Display the featured tag as the first item
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0), // Add bottom padding
                        child: Text(
                          'Featured',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      );
                    } else {
                      // Subtract 1 from index to account for the featured tag
                      final song = _songs[index - 1];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SongCard(
                          title: song['title'] ?? '',
                          duration: (song['duration'] ~/ 60).toString() + ":" + (song['duration'] % 60).toString() ?? '0:00',
                          id: song['_id'],
                          artist: song['artist'],
                        ),
                      );
                    }
                  },
                ),
    ),
  );
}


}

class SongCard extends StatefulWidget {
  final String title;
  final String duration;
  final String artist;
  final String id;

  const SongCard({
    required this.title,
    required this.duration,
    required this.id,
    required this.artist,
  });

  @override
  _SongCardState createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  bool _isLoading = false; // Track loading state

  void _playSong(BuildContext context, String songId) async {
    setState(() {
      _isLoading = true; // Set loading state to true when play button is pressed
    });

    try {
      final response = await http.get(Uri.parse(
          'http://localhost:5000/api/songs/$songId/mp3_data'));

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final mp3Data = parsed['mp3_data'] as String;
        final bytes = base64Decode(mp3Data);

        // Use the audio player to play the decoded bytes
        final AudioPlayer _audioPlayer = AudioPlayer();
        await _audioPlayer.play(BytesSource(bytes)); // Play the audio from bytes

        // Show the expanded song card
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return ExpandedSongCard(
              title: widget.title,
              artist: widget.artist,
              duration: widget.duration,
              audioPlayer: _audioPlayer,
            );
          },
        );
      } else {
        // Handle server errors (non-200 status codes)
        debugPrint('Failed to fetch song data: ${response.statusCode}');
      }
    } catch (err) {
      // Handle other errors (network issues, parsing errors, etc.)
      debugPrint('Error fetching song: $err');
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state after operation is complete
      });
    }
  }

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
            title: Text(widget.title, style: TextStyle(color: Colors.white)),
            subtitle: Text(widget.duration, style: TextStyle(color: Colors.white)),
            trailing: _isLoading
                ? CircularProgressIndicator() // Display loading spinner if loading
                : IconButton(
                    icon: Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      _playSong(context, widget.id);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}


class ExpandedSongCard extends StatefulWidget {
  final String title;
  final String artist;
  final String duration;
  final AudioPlayer audioPlayer;

  const ExpandedSongCard({
    required this.title,
    required this.artist,
    required this.duration,
    required this.audioPlayer,
  });

  @override
  _ExpandedSongCardState createState() => _ExpandedSongCardState();

}

class _ExpandedSongCardState extends State<ExpandedSongCard> {
  bool _isPlaying = true; // Track playback state
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _duration = _parseDuration(widget.duration);
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Update position every second
      if(_position+Duration(seconds: 1) >= _duration)
      {
        setState(() {_isPlaying = false;_position = Duration.zero;});
        widget.audioPlayer.seek(Duration(milliseconds:0));

      }
      if (_isPlaying && _position < _duration) {
        setState(() {
          _position += Duration(seconds: 1);
        });
      }
    });
  }

Duration _parseDuration(String durationString) {
  List<String> parts = durationString.split(':');
  int minutes = int.parse(parts[0]);
  int seconds = int.parse(parts[1]);
  return Duration(minutes: minutes, seconds: seconds);
}

  @override
  Widget build(BuildContext context) {
    Duration remainingTime = _duration - _position;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      widget.audioPlayer.stop();
                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(widget.artist),
              SizedBox(height: 10),
              // Add audio controls and remaining time display here
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      _togglePlayback(); // Toggle play/pause state
                    },
                  ),
                  Expanded(
                    child: Slider(
                      min: 0.0,
                      max: _duration.inMilliseconds.toDouble(),
                      value: _position.inMilliseconds.toDouble(),
                      onChanged: (double value) {
                        setState(() {
                          _position = Duration(milliseconds: value.toInt());
                        });
                      },
                      onChangeEnd: (double value) {
                        widget.audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  Text(formatDuration(remainingTime)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDuration(Duration duration) {
    return '${duration.inMinutes.remainder(60)}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      await widget.audioPlayer.resume();
    }
    setState(() {
      _isPlaying = !_isPlaying; // Toggle _isPlaying state
    });
  }
}


class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchSongs(String query) async {
    try {
      print(query);
      final url = Uri.parse('http://localhost:5000/api/songs/search?q=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Failed to fetch search results: ${response.statusCode}');
      }
    } catch (err) {
      print('Error searching songs: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchBar(),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final song = _searchResults[index];
                        return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SongCard(
                          title: song['title'] ?? '',
                          duration: (song['duration'] ~/ 60).toString() + ":" + (song['duration'] % 60).toString() ?? '0:00',
                          id: song['_id'],
                          artist: song['artist'],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.only(top: 16), // Add top margin here
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  _searchSongs(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
        ),
        child: Center(
          child: GlassProfileCard(
            name: 'Guest',
            imageUrl: 'https://via.placeholder.com/150',
            minutesWatched: 245,
            favoriteGenre: 'R&B',
          ),
        ),
      ),
    );
  }
}

class GlassProfileCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final int minutesWatched;
  final String favoriteGenre;

  const GlassProfileCard({
    required this.name,
    required this.imageUrl,
    required this.minutesWatched,
    required this.favoriteGenre,
  });

  @override
  _GlassProfileCardState createState() => _GlassProfileCardState();
}

class _GlassProfileCardState extends State<GlassProfileCard> {
  final TextEditingController _textEditingController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.imageUrl),
                ),
                SizedBox(height: 26),
                Text(
                  widget.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Minutes Listened: ${widget.minutesWatched}',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Favorite Genre: ${widget.favoriteGenre}',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 16), // Add space between the existing text and the new elements
                Container( // Separate card for "Add Song from YouTube" section
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  padding: EdgeInsets.all(20), // Add padding around the section
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add your song using a YouTube link',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          hintText: 'Paste YouTube link here',
                          hintStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _uploadSong(context);
                        },
                        child: Text('Add Song', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _uploadSong(BuildContext context) async {
    String youtubeLink = _textEditingController.text;
    final url = Uri.parse('http://localhost:5000/api/upload/youtube');
    final response = await http.post(
      url,
      body: {'youtubeLink': youtubeLink},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Song uploaded successfully'),
        ),
      );
      _textEditingController.clear();
    } else {
      Map<String, dynamic> responseData = json.decode(response.body);
      String errorMessage = responseData['message'] ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Dispose the controller when not needed
    _textEditingController.dispose();
    super.dispose();
  }
}
