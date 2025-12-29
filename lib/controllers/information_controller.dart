import 'package:cepattanggap/models/news_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:xml/xml.dart' as xml;

class InformationController extends GetxController {
  var newsList = <NewsArticle>[].obs;
  var isLoading = false.obs;

  Future<List<Map<String, String>>> fetchDisasterNews() async {
    final rssUrl =
        'https://news.google.com/rss/search?q=disaster+OR+earthquake+OR+flood&hl=en-US&gl=US&ceid=US:en';

    final response = await http.get(
      Uri.parse(rssUrl),
      headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal load RSS');
    }

    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    return items.map((node) {
      final rawTitle = node.findElements('title').first.text;
      final title = rawTitle.split(' - ')[0];

      final link = node.findElements('link').first.text;
      final pubDate = node.findElements('pubDate').first.text;

      final sourceElement = node.findElements('source').first;
      final sourceName = sourceElement.text;
      final sourceUrl = sourceElement.getAttribute('url') ?? "";

      return {
        'title': title,
        'link': link,
        'pubDate': pubDate,
        'source': sourceName,
        'sourceUrl': sourceUrl,
      };
    }).toList();
  }
}
