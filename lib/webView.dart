import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_share/flutter_share.dart';

import 'VideoPlayer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MyWebView extends StatefulWidget {
  @override
  _MyWebViewState createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  bool isLoad = false;
  var _currentWebPlatform;
  Color getColor(WebPlatforms c) {
    switch (c) {
      case WebPlatforms.Zee5:
        return Color.fromRGBO(29, 0, 30, 1);
      case WebPlatforms.Voot:
        return Color.fromRGBO(13, 6, 32, 1);
      case WebPlatforms.Hungama:
        return Color.fromRGBO(15, 126, 243, 1);
    }
  }

  String getName(WebPlatforms c) {
    switch (c) {
      case WebPlatforms.Zee5:
        return 'Zee5';
      case WebPlatforms.Voot:
        return 'Voot';
      case WebPlatforms.Hungama:
        return 'Hungama';
    }
  }

  String getUrl(WebPlatforms c) {
    switch (c) {
      case WebPlatforms.Zee5:
        return 'https://www.zee5.com';
      case WebPlatforms.Voot:
        return 'https://www.voot.com/';
      case WebPlatforms.Hungama:
        return 'https://www.hungama.com/';
    }
  }

  Widget getTiles(WebPlatforms c) {
    return ListTile(
      title: Text(
        getName(c),
        style: GoogleFonts.lato(
          color: getColor(_currentWebPlatform),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        isLoad = true;
        _currentWebPlatform = c;
        _controller.future.then(
            (value) => value.loadUrl(getUrl(c)).whenComplete(() => setState(() {
                  isLoad = false;
                })));
        setState(() {});
        Navigator.pop(context);
      },
    );
  }

  Future getStreamUrl(String url) async {
    String streamUrl;
    if(_currentWebPlatform == WebPlatforms.Zee5)
        {
          String token, id = url.split('/').last;
          await http.get("https://useraction.zee5.com/tokennd/").then((value) {
            if (value.statusCode != 200) return false;
            token = json.decode(value.body)['video_token'];
          }).whenComplete(() => http.get(
                  "https://gwapi.zee5.com/content/details/$id?translation=en&country=IN&version=2",
                  headers: {
                    "x-access-token": token,
                    'Content-Type': 'application/json'
                  }).then((value) {
                if (value.statusCode != 200) return false;
                final String result = json
                    .decode(value.body)['hls'][0]
                    .replaceFirst('drm', 'hls');
                streamUrl= 'https://zee5vodnd.akamaized.net$result$token';
              }));
        }
    if(_currentWebPlatform ==WebPlatforms.Voot
    )
        {
          String id = url.split('/').last;
          await  http
              .get(
                  "https://wapi.voot.com/ws/ott/getMediaInfo.json?platform=Web&pId=2&mediaId=$id")
              .then((value) {
            if (value.statusCode != 200) return false;
            streamUrl= json.decode(value.body)['assets']['Files'][3]['URL'];
          });
        }
    if(_currentWebPlatform ==WebPlatforms.Hungama)
        {
          var lst = url.split('/')[url.split('/').length - 2];
          String id = lst[lst.length - 2];
          await http
              .post(
                  "https://www.hungama.com/index.php?c=common&m=get_video_mdn_url",
                  headers: {
                    "accept": "*/*",
                    "content-type":
                        "application/x-www-form-urlencoded; charset=UTF-8",
                    "x-requested-with": "XMLHttpRequest"
                  },
                  body:
                      "content_id=$id&action=movie&cnt_type=movie&movie_rights=TVOD-Premium&lang=english")
              .then((value) {
            if (value.statusCode != 200) return false;
            streamUrl= json.decode(value.body)['stream_url'];
          });
        }
    return streamUrl;
    }

  @override
  void initState() {
    super.initState();
    _currentWebPlatform = WebPlatforms.Zee5;
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

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
              decoration: BoxDecoration(color: getColor(_currentWebPlatform)),
            ),
            for (var c in WebPlatforms.values) getTiles(c),
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: getColor(_currentWebPlatform),
        title: Text(getName(_currentWebPlatform)),
        actions: <Widget>[
          NavigationControls(_controller.future),
          // SampleMenu(_controller.future),
        ],
      ),
      body: Builder(builder: (BuildContext context) {
        return Stack(
          children: [
            WebView(
              initialUrl: getUrl(_currentWebPlatform),
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) async {
                _controller.complete(webViewController);
              },
              gestureNavigationEnabled: true,
            ),
            if (isLoad)
              SpinKitChasingDots(
                color: Colors.white,
                size: 50.0,
              ),
          ],
        );
      }),
      floatingActionButton: favoriteButton(),
    );
  }


  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          // ignore: deprecated_member_use
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  Future<void> share() async {
    await FlutterShare.share(
        title: 'Example share',
        text: 'Example share text',
        linkUrl: 'https://flutter.dev/',
        chooserTitle: 'Example Chooser Title'
    );
  }

  Widget favoriteButton() {
    return FutureBuilder<WebViewController>(
        future: _controller.future,
        builder: (BuildContext context,
            AsyncSnapshot<WebViewController> controller) {
          if (controller.hasData) {
            return Column(
              children: [
                FloatingActionButton(
                  tooltip: 'Play media',
                  backgroundColor: getColor(_currentWebPlatform),
                  onPressed: () async {
                    setState(() => isLoad = true);
                    final String url = await controller.data.currentUrl();
                    getStreamUrl(url).then((value) {
                      // print('??????????????????????????????????$value');
                      setState(() => isLoad = false);
                      if (value != false)
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => VideoPlayer(value),
                          ),
                        );
                      else
                        Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text('$value')),
                        );
                    });
                  },
                  child: const Icon(Icons.play_arrow_rounded),
                ),
                FlatButton(
                  child: Text('Share text and link'),
                  onPressed: share,
                )
              ],
            );
          }
          return Container();
        });
  }
}

enum WebPlatforms {
  Zee5,
  Voot,
  Hungama,
}
// enum MenuOptions {
//   showUserAgent,
//   listCookies,
//   clearCookies,
//   addToCache,
//   listCache,
//   clearCache,
//   navigationDelegate,
// }

// class SampleMenu extends StatelessWidget {
//   SampleMenu(this.controller);
//
//   final Future<WebViewController> controller;
//   final CookieManager cookieManager = CookieManager();
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<WebViewController>(
//       future: controller,
//       builder:
//           (BuildContext context, AsyncSnapshot<WebViewController> controller) {
//         return PopupMenuButton<MenuOptions>(
//           onSelected: (MenuOptions value) {
//             switch (value) {
//               case MenuOptions.showUserAgent:
//                 _onShowUserAgent(controller.data, context);
//                 break;
//               case MenuOptions.listCookies:
//                 _onListCookies(controller.data, context);
//                 break;
//               case MenuOptions.clearCookies:
//                 _onClearCookies(context);
//                 break;
//               case MenuOptions.addToCache:
//                 _onAddToCache(controller.data, context);
//                 break;
//               case MenuOptions.listCache:
//                 _onListCache(controller.data, context);
//                 break;
//               case MenuOptions.clearCache:
//                 _onClearCache(controller.data, context);
//                 break;
//               case MenuOptions.navigationDelegate:
//                 _onNavigationDelegateExample(controller.data, context);
//                 break;
//             }
//           },
//           itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
//             PopupMenuItem<MenuOptions>(
//               value: MenuOptions.showUserAgent,
//               child: const Text('Show user agent'),
//               enabled: controller.hasData,
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.listCookies,
//               child: Text('List cookies'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.clearCookies,
//               child: Text('Clear cookies'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.addToCache,
//               child: Text('Add to cache'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.listCache,
//               child: Text('List cache'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.clearCache,
//               child: Text('Clear cache'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.navigationDelegate,
//               child: Text('Navigation Delegate example'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _onShowUserAgent(
//       WebViewController controller, BuildContext context) async {
//     // Send a message with the user agent string to the Toaster JavaScript channel we registered
//     // with the WebView.
//     await controller.evaluateJavascript(
//         'Toaster.postMessage("User Agent: " + navigator.userAgent);');
//   }
//
//   void _onListCookies(
//       WebViewController controller, BuildContext context) async {
//     final String cookies =
//         await controller.evaluateJavascript('document.cookie');
//     // ignore: deprecated_member_use
//     Scaffold.of(context).showSnackBar(SnackBar(
//       content: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         mainAxisSize: MainAxisSize.min,
//         children: <Widget>[
//           const Text('Cookies:'),
//           _getCookieList(cookies),
//         ],
//       ),
//     ));
//   }
//
//   void _onAddToCache(WebViewController controller, BuildContext context) async {
//     await controller.evaluateJavascript(
//         'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
//     // ignore: deprecated_member_use
//     Scaffold.of(context).showSnackBar(const SnackBar(
//       content: Text('Added a test entry to cache.'),
//     ));
//   }
//
//   void _onListCache(WebViewController controller, BuildContext context) async {
//     await controller.evaluateJavascript('caches.keys()'
//         '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
//         '.then((caches) => Toaster.postMessage(caches))');
//   }
//
//   void _onClearCache(WebViewController controller, BuildContext context) async {
//     await controller.clearCache();
//     // ignore: deprecated_member_use
//     Scaffold.of(context).showSnackBar(const SnackBar(
//       content: Text("Cache cleared."),
//     ));
//   }
//
//   void _onClearCookies(BuildContext context) async {
//     final bool hadCookies = await cookieManager.clearCookies();
//     String message = 'There were cookies. Now, they are gone!';
//     if (!hadCookies) {
//       message = 'There are no cookies.';
//     }
//     // ignore: deprecated_member_use
//     Scaffold.of(context).showSnackBar(SnackBar(
//       content: Text(message),
//     ));
//   }
//
//   void _onNavigationDelegateExample(
//       WebViewController controller, BuildContext context) async {
//     final String contentBase64 =
//         base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
//     await controller.loadUrl('data:text/html;base64,$contentBase64');
//   }
//
//   Widget _getCookieList(String cookies) {
//     if (cookies == null || cookies == '""') {
//       return Container();
//     }
//     final List<String> cookieList = cookies.split(';');
//     final Iterable<Text> cookieWidgets =
//         cookieList.map((String cookie) => Text(cookie));
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       mainAxisSize: MainAxisSize.min,
//       children: cookieWidgets.toList(),
//     );
//   }
// }

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller.canGoBack()) {
                        await controller.goBack();
                      } else {
                        // ignore: deprecated_member_use
                        Scaffold.of(context).showSnackBar(
                          const SnackBar(content: Text("No back history item")),
                        );
                        return;
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller.canGoForward()) {
                        await controller.goForward();
                      } else {
                        // ignore: deprecated_member_use
                        Scaffold.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("No forward history item")),
                        );
                        return;
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: !webViewReady
                  ? null
                  : () {
                      controller.reload();
                    },
            ),
          ],
        );
      },
    );
  }
}
