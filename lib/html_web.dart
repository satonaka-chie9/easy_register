// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class HtmlHelper {
  static html.Blob createBlob(List<int> bytes) => html.Blob([bytes]);
  static String createObjectUrlFromBlob(html.Blob blob) => html.Url.createObjectUrlFromBlob(blob);
  static html.AnchorElement createAnchor(String url) => html.AnchorElement(href: url);
  static void revokeObjectUrl(String url) => html.Url.revokeObjectUrl(url);
} 