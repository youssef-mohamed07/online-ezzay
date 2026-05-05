import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'agent_debug_log_stub.dart'
    if (dart.library.io) 'agent_debug_log_io.dart' as agent_debug_io;

/// Session e42902: sends one NDJSON event to Cursor debug ingest (no secrets/PII).
// #region agent log
void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, dynamic>? data,
  String runId = 'pre-fix',
}) {
  final payload = <String, dynamic>{
    'sessionId': 'e42902',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'location': location,
    'message': message,
    'hypothesisId': hypothesisId,
    'runId': runId,
    'data': data ?? const {},
  };
  final line = jsonEncode(payload);
  if (kDebugMode) {
    debugPrint('AGENT_DEBUG_NDJSON:$line');
    // Ensures lines appear in `flutter run` terminal (debugPrint may throttle).
    print('AGENT_DEBUG_NDJSON:$line');
  }
  agent_debug_io.agentDebugAppendWorkspaceNdjson(line);
  unawaited(
    http
        .post(
          Uri.parse(
            'http://127.0.0.1:7532/ingest/646b653b-587b-4c08-acdd-4cb0d975ac17',
          ),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': 'e42902',
          },
          body: line,
        )
        .timeout(const Duration(seconds: 2))
        .catchError((_) => http.Response('', 500)),
  );
}
// #endregion
