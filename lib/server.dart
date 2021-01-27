import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ottium_frontend/home.dart';
import 'package:web_scraper/web_scraper.dart';


Future<List<MovieData>> zee5search(String q) async {
  var tokenresponse = await http.get("https://useraction.zee5.com/tokennd/");
  var token;
  if (tokenresponse.statusCode == 200) {
    token = json.decode(tokenresponse.body)['video_token'];
  }
  var url = "https://gwapi.zee5.com/content/getContent/search?q=${q}&limit=10&version=5";
  var response = await http.get(url, headers: {
    "Accept": "*/*",
  });
  if (response.statusCode == 200) {
    var res= await searchResult(response.body, token);
    return res;
  }
}

Future<List<MovieData>> searchResult(String response,String token) async {
  List<MovieData> movies = [];
  movies.clear();
  json.decode(response)['all'].forEach((ele) async{
    String url =("https://gwapi.zee5.com/content/details/${ele['id']}?translation=en&country=IN&version=2");
    var res = await http.get(url, headers: {
      "x-access-token": token,
      'Content-Type': 'application/json'
    });
    if (res.statusCode == 200) {
      var result = json.decode(res.body);
      String hls = result['hls'][0];
      hls = hls.replaceFirst('drm', 'hls');
      hls = ('https://zee5vodnd.akamaized.net${hls}${token}');
      var temp=MovieData(
          id: ele['id'],
          title: result['title'],
          thumbnail: result['image_url'],
          videoUrl: hls,
          streamingurl: hls,
          description: result['description'],
          plateform: "zee5");
          movies.add(temp);
    }
  });
  await Future.delayed(Duration(seconds: 2));
  return movies;
}

vootSearch(String q) async{
  var searchData=[];
  var url="https://jn1rdqrfn5-dsn.algolia.net/1/indexes/*/queries?x-algolia-application-id=JN1RDQRFN5&x-algolia-api-key=e426ce68fbce6f9262f6b9c3058c4ea9";
  var response=await http.post(url,
    headers:{
    "Accept":"*/*",
    "content-type": "application/x-www-form-urlencoded"
  },
  body: '{"requests":[{"indexName":"prod_voot_v4_elastic","params":"query=${q}&hitsPerPage=5&page=0&filters=availability.available.IN.from%20%3C%201611175173%20AND%20availability.available.IN.to%20%3E%201611175173"}]}'
  );
  if(response.statusCode==200){
    searchData.clear();
    var result=json.decode(response.body)['results'][0]['hits'];
    result.forEach((e){
      searchData.add({
        "id":e['id'],
        'title':e['fullTitle'],
        'thumbnail':"https://v3img.voot.com/${e['imageUri']}",
        'description':e['fullSynopsis'],
        'plateform':'voot'
      });
    });
    searchData.forEach((element) async {
      var surl="https://wapi.voot.com/ws/ott/getMediaInfo.json?platform=Web&pId=2&mediaId=${element['id']}";
      var res= await http.get(surl);
      if (res.statusCode==200){
        var sres=json.decode(res.body);
        element['video_url']=sres['assets']['Files'][3]['URL'];
        element['streamingurl']=sres['assets']['Files'][3]['URL'];
      }
    });
  }
  await Future.delayed(Duration(seconds: 2));
  return movieDataFromJson(json.encode(searchData));
}

hungamaSearch(String q) async{
  var searchData=[];
  searchData.clear();
  var url="https://www.hungama.com/search-movies/${q}/1/?_country=IN";
  var response=await http.get(url,
      headers:{
        "Accept":"*/*",
        "x-requested-with": "XMLHttpRequest"
      },
  );
  if(response.statusCode==200){

    var result=json.decode(response.body)['movie'];
    result.forEach((e) async{
      String thumbnail;
      final webScraper = WebScraper('https://www.hungama.com/');
      if (await webScraper.loadWebPage(e['url'].substring(23))) {
      var element = webScraper.getElement('#moviethumplay > img', ['src']);
      thumbnail=element[0]['attributes']['src'];
      }
      await Future.delayed(Duration(milliseconds: 300));
      searchData.add({
        "id":e['id'],
        'title':e['name'],
        'thumbnail':thumbnail,
        'description':'',
        'plateform':'hungama'
      });
    });
    await Future.delayed(Duration(seconds: 6));
    searchData.forEach((element) async {
      var surl="https://www.hungama.com/index.php?c=common&m=get_video_mdn_url";
      var res= await http.post(surl,
        headers:{
          "accept":"*/*",
          "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
          "x-requested-with": "XMLHttpRequest"
        },
          body: "content_id=${element['id']}&action=movie&cnt_type=movie&movie_rights=TVOD-Premium&lang=english"
      );
      if (res.statusCode==200){
        var sres=json.decode(res.body);
        element['video_url']=sres['stream_url'];
        element['streamingurl']=sres['stream_url'];
      }
    });
  }
  await Future.delayed(Duration(seconds: 6));
  return movieDataFromJson(json.encode(searchData));
}