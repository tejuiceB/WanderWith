import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

class UrlMetadata {
  final String? title;
  final String? description;
  final String? image;
  final String? siteName;

  UrlMetadata({this.title, this.description, this.image, this.siteName});
}

class UrlMetadataService {
  static Future<UrlMetadata> fetchMetadata(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return UrlMetadata();

      final document = parser.parse(response.body);
      
      String? getTag(String property) {
        return document
            .querySelector('meta[property="$property"]')
            ?.attributes['content'] ??
            document
            .querySelector('meta[name="$property"]')
            ?.attributes['content'];
      }

      final title = getTag('og:title') ?? document.querySelector('title')?.text;
      final description = getTag('og:description') ?? getTag('description');
      final image = getTag('og:image');
      final siteName = getTag('og:site_name');

      return UrlMetadata(
        title: title?.trim(),
        description: description?.trim(),
        image: image?.trim(),
        siteName: siteName?.trim(),
      );
    } catch (e) {
      print("Error fetching metadata: $e");
      return UrlMetadata();
    }
  }

  static String detectCategory(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('booking.com') || lowerUrl.contains('airbnb.com') || lowerUrl.contains('hotels.com') || lowerUrl.contains('expedia.com')) {
      return 'Stay';
    }
    if (lowerUrl.contains('skyscanner') || lowerUrl.contains('airline') || lowerUrl.contains('flight')) {
      return 'Flights';
    }
    if (lowerUrl.contains('google.com/maps') || lowerUrl.contains('maps.app.goo.gl')) {
      return 'Places';
    }
    if (lowerUrl.contains('tripadvisor') || lowerUrl.contains('yelp') || lowerUrl.contains('restaurant')) {
      return 'Restaurants';
    }
    if (lowerUrl.contains('uber.com') || lowerUrl.contains('grab.com') || lowerUrl.contains('transport')) {
      return 'Transport';
    }
    if (lowerUrl.contains('.pdf') || lowerUrl.contains('drive.google.com') || lowerUrl.contains('dropbox')) {
      return 'Documents';
    }
    if (lowerUrl.contains('ticketmaster') || lowerUrl.contains('eventbrite') || lowerUrl.contains('klook')) {
      return 'Tickets';
    }
    return 'Other';
  }
}
