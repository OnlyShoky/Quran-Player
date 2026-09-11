import 'dart:js_interop';

@JS('gtag')
external void _gtag(JSAny? command, JSAny? event);

Future<void> initializeAnalytics() async {}

Future<void> trackScreen(String name) async {
  _gtag('event'.toJS, 'page_view'.toJS);
}