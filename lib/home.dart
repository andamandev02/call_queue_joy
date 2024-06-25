import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Play Sound Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _playSound();
          },
          child: Text('Play Sound'),
        ),
      ),
    );
  }

  void _playSound() async {
    await _audioPlayer.play(AssetSource('sound/bell.mp3'));
  }
}
