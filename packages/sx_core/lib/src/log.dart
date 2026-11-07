/// Logging with a ring buffer and redaction (SX-006).
///
/// Rules (AGENTS.md 5): never log message text, keys or file names. Callers pass
/// a short English event line; [Redactor] removes anything that looks like a
/// secret before it reaches memory. Diagnostics exports [SxLog.export].
library;

import 'constants.dart';

enum LogLevel { debug, info, warn, error }

/// Best-effort scrub of secrets from a log line.
abstract final class Redactor {
  static final RegExp _longHex = RegExp(r'\b[0-9a-fA-F]{32,}\b');
  static final RegExp _secretValue = RegExp(
    r'(key|token|secret|password|passphrase)\s*[=:]\s*\S+',
    caseSensitive: false,
  );
  static final RegExp _base64Blob = RegExp(r'\b[A-Za-z0-9+/]{64,}={0,2}');
  static final RegExp _filePath = RegExp(r'(?:/|[A-Za-z]:\\)(?:[^\s/\\]+[/\\])+[^\s]+');

  /// Returns [line] with keys, tokens and absolute paths replaced.
  static String scrub(String line) => line
      .replaceAllMapped(_secretValue, (Match m) => '${m.group(1)}=<redacted>')
      .replaceAll(_longHex, '<hex>')
      .replaceAll(_base64Blob, '<blob>')
      .replaceAll(_filePath, '<path>');
}

/// One log line. Raw text is never mutated after creation.
class LogRecord {
  const LogRecord(this.at, this.level, this.line);

  final DateTime at;
  final LogLevel level;
  final String line;

  @override
  String toString() =>
      '${at.toUtc().toIso8601String()} ${level.name.toUpperCase().padRight(5)} $line';
}

/// Fixed-size in-memory log. Oldest lines fall out first.
class SxLog {
  SxLog({this.capacity = 5000, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The plan's ring buffer size.
  final int capacity;
  final DateTime Function() _clock;
  final List<LogRecord> _records = <LogRecord>[];

  List<LogRecord> get records => List<LogRecord>.unmodifiable(_records);

  void debug(String line) => _add(LogLevel.debug, line);
  void info(String line) => _add(LogLevel.info, line);
  void warn(String line) => _add(LogLevel.warn, line);
  void error(String line) => _add(LogLevel.error, line);

  void _add(LogLevel level, String line) {
    _records.add(LogRecord(_clock(), level, Redactor.scrub(line)));
    final int overflow = _records.length - capacity;
    if (overflow > 0) _records.removeRange(0, overflow);
  }

  /// Plain-text export for Diagnostics → Share logs.
  String export() {
    final StringBuffer out = StringBuffer()
      ..writeln('ShAre XT diagnostics log')
      ..writeln('protocol ${_protocolLine()}')
      ..writeln('records ${_records.length}')
      ..writeln('---');
    for (final LogRecord record in _records) {
      out.writeln(record);
    }
    return out.toString();
  }

  String _protocolLine() => 'SLP/1 ${Slp1.serviceUuid}';

  void clear() => _records.clear();
}
