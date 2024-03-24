const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const ytdl = require('ytdl-core');
const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 5000;

const mongoURI = 'mongodb+srv://admin123:adminadmin@cluster0.kpibhfu.mongodb.net/sonicsurfer';

mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  connectTimeoutMS: 30000
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.error(err));

const songSchema = new mongoose.Schema({
  title: String,
  duration: Number,
  artist: String,
  genre: String,
});

const audioSchema = new mongoose.Schema({
  song_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Song'
  },
  mp3_data: String
});

const Audio = mongoose.model('Audio', audioSchema);
const Song = mongoose.model('Song', songSchema);

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.get('/api/songs', async (req, res) => {
  try {
    const songs = await Song.find();
    res.json(songs);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error fetching songs' });
  }
});

app.get('/api/songs/search', async (req, res) => {
  try {
    const searchString = req.query.q; 

    const regex = new RegExp(searchString, 'i');

    const songs = await Song.find({ title: regex }).limit(10);

    res.json(songs);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error searching songs' });
  }
});


app.get('/api/songs/:id/mp3_data', async (req, res) => {
  try {
    const songId = req.params.id;
    const song = await Audio.findOne({ song_id: songId });

    if (!song) {
      return res.status(404).json({ message: 'Song not found' });
    }

    const response = {
      title: song.title,
      duration: song.duration,
      artist: song.artist,
      genre: song.genre,
      mp3_data: song.mp3_data
    };

    res.json(response);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error fetching song data' });
  }
});

// Route to handle uploading YouTube video link
app.post('/api/upload/youtube', async (req, res) => {
  const { youtubeLink } = req.body;

  try {
    // Download YouTube audio
    const videoInfo = await ytdl.getInfo(youtubeLink);
    const title = videoInfo.videoDetails.title;
    const artist = videoInfo.videoDetails.author.name;
    const duration = parseInt(videoInfo.videoDetails.lengthSeconds);
    const genre = 'Unknown'; // You can set this based on your requirements

    const maxDuration = 10 * 60; // 10 minutes in seconds
    if (duration > maxDuration) {
      throw new Error('Video duration exceeds the maximum allowed duration of 10 mins');
    }

    // Download audio stream and convert to MP3
    const audioStream = ytdl.downloadFromInfo(videoInfo, { filter: 'audioonly' });
    const outputFilePath = `./${title}.mp3`;
    const mp3Stream = fs.createWriteStream(outputFilePath);
    audioStream.pipe(mp3Stream);

    await new Promise((resolve, reject) => {
      mp3Stream.on('finish', resolve);
      mp3Stream.on('error', reject);
    });

    // Extracted metadata from YouTube video
    const songData = {
      title,
      duration,
      artist,
      genre,
    };

    // Save song metadata to MongoDB
    const song = new Song(songData);
    const savedSong = await song.save();

    // Read MP3 file and encode to base64
    const mp3Data = fs.readFileSync(outputFilePath, { encoding: 'base64' });

    // Save MP3 data to MongoDB
    const audio = new Audio({
      song_id: savedSong._id,
      mp3_data: mp3Data,
    });

    await audio.save();

    // Cleanup: Delete temporary MP3 file
    fs.unlinkSync(outputFilePath);

    res.status(200).json({ message: 'Song uploaded successfully' });
  } catch (err) {
    console.error('Error uploading YouTube video:', err);
    res.status(500).json({ message: `Error uploading YouTube video ${err}` });
  }
});


app.listen(port, () => console.log(`Server listening on port ${port}`));
