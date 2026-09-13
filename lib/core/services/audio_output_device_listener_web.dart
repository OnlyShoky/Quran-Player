import 'dart:js_interop';

import 'package:web/web.dart' as web;

class AudioOutputDeviceListener {
  AudioOutputDeviceListener(this._onDeviceChanged) {
    _mediaDevices = web.window.navigator.mediaDevices;
    _mediaDevices?.addEventListener('devicechange', _deviceChangeListener);
  }

  final void Function() _onDeviceChanged;
  late final JSFunction _deviceChangeListener = _handleDeviceChange.toJS;
  web.MediaDevices? _mediaDevices;

  void _handleDeviceChange(web.Event event) {
    _onDeviceChanged();
  }

  void dispose() {
    _mediaDevices?.removeEventListener('devicechange', _deviceChangeListener);
    _mediaDevices = null;
  }
}