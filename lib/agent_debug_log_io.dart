import 'dart:io';

/// Writes one NDJSON line for session e42902 when running on macOS desktop (VM is macOS).
void agentDebugAppendWorkspaceNdjson(String line) {
  try {
    if (!Platform.isMacOS) return;
    const path =
        '/Users/youssef/Developer/online-ezzay/.cursor/debug-e42902.log';
    File(path).writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  } catch (_) {}
}
