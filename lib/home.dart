import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ottium_frontend/server.dart';
import 'dart:convert';
import 'VideoPlayer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var search = TextEditingController();
  onTapHandler(int i) {
    if (movieList[i].streamingurl != null)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayer(movieList[i]),
        ),
      );
  }
  String plateform = 'Zee5';
  bool searching = false;
  List<MovieData> movieList = [];
  Future<void> onPressHandler() async {
    searching = true;
    movieList.clear();
    setState(() {});
    FocusScope.of(context).requestFocus(FocusNode());
    if (plateform == 'Zee5') {
      var movies = await zee5search(search.text);
      movies.forEach((m) {
        movieList.add(m);
      });
    }
    if (plateform == 'Voot') {
      var movies = await vootSearch(search.text);
      movies.forEach((m) {
        movieList.add(m);
      });
    }
    if (plateform == 'Hungama') {
      var movies = await hungamaSearch(search.text);
      movies.forEach((m) {
        movieList.add(m);
      });
    }

    searching = false;
    setState(() {});
  }

  final spinkit = SpinKitDoubleBounce(
    color: Color(0xffa526ff),
    size: 50.0,
  );



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Column(
                children: [
                  Text(
                    'PremiumVerse',
                    style: GoogleFonts.lato(color: Colors.white, fontSize: 30),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                  ),
                  Text(
                    'Select plateform, search movies & play',
                    style: GoogleFonts.lato(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: plateform=="Voot"?Color(0xffa526ff):Color(0xff800080),
              ),
            ),
            ListTile(
              title: Text(
                'Voot',
                style: GoogleFonts.lato(
                  color: Colors.deepPurpleAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                plateform = 'Voot';
                setState(() {});
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Zee5',
                style: GoogleFonts.lato(
                  color: Colors.deepPurpleAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                plateform = 'Zee5';
                setState(() {});
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Hungama',
                style: GoogleFonts.lato(
                  color: Colors.deepPurpleAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                plateform = 'Hungama';
                setState(() {});
                Navigator.pop(context);
              },
            ),

          ],
        ),
      ),
      appBar: AppBar(
        title: Text("Search ${plateform} Movies"),
        backgroundColor: plateform=="Voot"?Color(0xffa526ff):Color(0xff800080),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: MediaQuery.of(context).size.width - 70,
                child: TextField(
                  controller: search,
                ),
              ),
              IconButton(icon: Icon(Icons.search), onPressed: onPressHandler)
            ],
          ),
          Expanded(
            child: searching
                ? spinkit
                : ListView.builder(
                    itemBuilder: (c, i) => InkWell(
                      onTap: () => onTapHandler(i),
                      child: Card(
                        elevation: 5,
                        margin: EdgeInsets.all(20),
                        color: plateform=="Voot"?Color(0xffa526ff):Color(0xff800080),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                movieList[i].title,
                                style: GoogleFonts.nunitoSans(
                                  textStyle: TextStyle(
                                      color: Colors.white,
                                      letterSpacing: .5,
                                      fontSize: 25),
                                ),
                              ),
                            ),
                            Image.network(movieList[i].thumbnail),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              // child: Text(
                              //   movieList[i].description,
                              //   style: TextStyle(color: Colors.white),
                              // ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    itemCount: movieList.length,
                  ),
          ),
        ],
      ),
    );
  }
}

List<MovieData> movieDataFromJson(String str) =>
    List<MovieData>.from(json.decode(str).map((x) => MovieData.fromJson(x)));

class MovieData {
  MovieData({
    this.id,
    this.videoUrl,
    this.thumbnail,
    this.title,
    this.plateform,
    this.streamingurl,
    this.description,
  });

  String id;
  String videoUrl;
  String thumbnail;
  String title;
  String plateform;
  String streamingurl;
  String description;
  factory MovieData.fromJson(Map<String, dynamic> json) => MovieData(
        id: json["id"],
        videoUrl: json["video_url"],
        thumbnail: json["thumbnail"],
        title: json["title"],
        plateform: json["plateform"],
        streamingurl: json["streamingurl"],
        description: json['description'],
      );
}
