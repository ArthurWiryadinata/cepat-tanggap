import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:vibration/vibration.dart';

class FullScreenAlertPage extends StatefulWidget {
  final String title;
  final String message;

  const FullScreenAlertPage({
    required this.title,
    required this.message,
    Key? key,
  }) : super(key: key);

  @override
  State<FullScreenAlertPage> createState() => _FullScreenAlertPageState();
}

class _FullScreenAlertPageState extends State<FullScreenAlertPage> {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _player.play(AssetSource('sounds/alarms2.mp3')); // pastikan ada di assets

    Vibration.vibrate(pattern: [0, 800, 500, 800], repeat: 0);
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    Vibration.cancel();
    super.dispose();
  }

    void _stopAlert() {
    _player.stop();
    Vibration.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _stopAlert, // <-- seluruh layar bisa di-tap
      behavior: HitTestBehavior.opaque, // penting supaya area kosong juga responsif
      child: Scaffold(
        backgroundColor: Colors.red[700],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/warning.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  "Peringatan ${widget.title} !",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
