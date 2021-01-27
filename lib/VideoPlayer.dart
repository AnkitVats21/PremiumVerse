import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yoyo_player/yoyo_player.dart';

import 'home.dart';

class VideoPlayer extends StatefulWidget {
  final MovieData url;
  VideoPlayer(this.url);
  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  bool full = false;

  final spinkit=SpinKitChasingDots(
    color: Colors.white,
    size: 30,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: full
          ? null
          : AppBar(
              title: Text(widget.url.title),
            ),
      backgroundColor: widget.url.plateform=="Voot"?Color(0xffa526ff):Color(0xff800080),
      body: SingleChildScrollView(
        child: Column(
          children: [
            YoYoPlayer(
              aspectRatio: full
                  ? MediaQuery.of(context).size.width /
                      MediaQuery.of(context).size.height
                  : 16 / 9,
              url: widget.url.streamingurl,
              videoStyle: VideoStyle(
                play: Icon(Icons.pause),
                pause: Icon(Icons.play_arrow),
                fullscreen: Icon(Icons.fullscreen),
                forward: Icon(Icons.skip_next),
                backward: Icon(Icons.skip_previous),
                playedColor: Colors.red,
              ),
              videoLoadingStyle: VideoLoadingStyle(
                loading: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      spinkit,
                      Text(
                          "Loading",
                        style: GoogleFonts.nunitoSans(
                          color: Colors.white
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onfullscreen: (t) {
                setState(() {
                  full = t;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(widget.url.description,
                  style: GoogleFonts.nunitoSans(
                    textStyle: TextStyle(
                        color: Colors.white, letterSpacing: .5, fontSize: 15),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
