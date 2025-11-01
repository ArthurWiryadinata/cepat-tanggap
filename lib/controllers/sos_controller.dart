import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

final AudioPlayer _audioPlayer = AudioPlayer();

class SosController extends GetxController {
  RxBool isActive = false.obs;

  Future<void> playAlarm() async {
    isActive.value = true;

    await _audioPlayer.play(AssetSource('sounds/alarms2.mp3'));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // loop terus
    print("alramn on");
    if ((Platform.isAndroid || Platform.isIOS) &&
        await (Vibration.hasVibrator())) {
      print("vibrate on");
      await Vibration.vibrate(duration: 1000);
    } else
      print("gada vibrarte");
  }

  Future<void> stopAlarm() async {
    isActive.value = false;
    await _audioPlayer.stop();

    isActive.value = false;
    await _audioPlayer.stop();

    // hanya jika device mendukung dan platform mendukung
    if ((Platform.isAndroid || Platform.isIOS) &&
        await Vibration.hasVibrator()) {
      await Vibration.cancel();
    }
  }
}
