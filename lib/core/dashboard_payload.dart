/// Normalizes GET /ezzy/v1/dashboard JSON (handles `data` wrappers & nested maps).
abstract final class DashboardPayload {
  static Map<String, dynamic> unwrap(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    final root = Map<String, dynamic>.from(
      raw.map((k, v) => MapEntry(k.toString(), v)),
    );
    if (_isWpAuthShape(root)) return {};

    final merged = Map<String, dynamic>.from(root);
    merged.remove('data');
    final data = root['data'];
    if (data is Map) {
      final inner = Map<String, dynamic>.from(
        data.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (!_isWpAuthShape(inner)) {
        inner.forEach((k, v) => merged[k] = v);
      }
    }

    return _flattenKnownNested(merged);
  }

  static bool _isWpAuthShape(Map<String, dynamic> m) {
    final code = m['code']?.toString();
    if (code == null || code.isEmpty) return false;
    final data = m['data'];
    if (data is Map && data['status'] == 401) return true;
    return code == 'invalid_username' ||
        code == 'rest_forbidden' ||
        code == 'woocommerce_rest_authentication_error';
  }

  static Map<String, dynamic> _flattenKnownNested(Map<String, dynamic> m) {
    final out = Map<String, dynamic>.from(m);
    const nestedKeys = [
      'shipments',
      'warehouse',
      'stats',
      'counts',
      'summary',
      'metrics',
    ];
    for (final nk in nestedKeys) {
      final v = out[nk];
      if (v is Map) {
        final vm = Map<String, dynamic>.from(
          v.map((k, val) => MapEntry(k.toString(), val)),
        );
        vm.forEach((k, val) {
          out.putIfAbsent('$nk.$k', () => val);
        });
      }
    }
    return out;
  }

  static dynamic _valueByPath(Map<String, dynamic> source, String path) {
    dynamic current = source;
    for (final segment in path.split('.')) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Shipments embedded in dashboard payload (if backend sends them).
  static List<Map<String, dynamic>> recentShipments(Map<String, dynamic> m) {
    const keys = [
      'recent_shipments',
      'latest_shipments',
      'shipments_recent',
      'recent',
      'last_shipments',
      'shipments.latest',
    ];
    for (final key in keys) {
      final v =
          key.contains('.') ? _valueByPath(m, key) : m[key];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(
                  e.map((k, val) => MapEntry(k.toString(), val)),
                ))
            .toList();
      }
    }
    return [];
  }

  /// Paths already surfaced as primary metrics / chart (skip duplicates).
  static const Set<String> primaryMetricPaths = {
    'total_shipments',
    'shipments_count',
    'shipments.total',
    'delivered_shipments',
    'delivered_count',
    'shipments.delivered',
    'completed_shipments',
    'active_shipments',
    'active_count',
    'shipments.active',
    'warehouse_parcels_count',
    'warehouse_count',
    'warehouse.parcels_count',
    'parcels_in_warehouse',
    'pending_shipments',
    'cancelled_shipments',
  };

  /// Extra numeric fields → dashboard metric tiles.
  static Map<String, int> numericExtras(
    Map<String, dynamic> resolved, {
    Set<String>? skipPaths,
  }) {
    final skip = {...primaryMetricPaths, ...(skipPaths ?? {})};
    final out = <String, int>{};

    void tryAdd(String path, dynamic v) {
      if (skip.contains(path)) return;
      int? n;
      if (v is int) {
        n = v;
      } else if (v is double) {
        n = v.toInt();
      } else {
        n = int.tryParse(v?.toString().trim() ?? '');
      }
      if (n != null) out[path] = n;
    }

    resolved.forEach((k, v) {
      if (v is Map) {
        Map<String, dynamic>.from(
          v.map((ik, iv) => MapEntry(ik.toString(), iv)),
        ).forEach((ik, iv) => tryAdd('$k.$ik', iv));
      } else {
        tryAdd(k, v);
      }
    });
    return out;
  }

  /// Strings / bool / small lists / nested maps — avoids duplicating numeric tiles.
  static List<MapEntry<String, String>> scalarDetailRows(
    Map<String, dynamic> resolved, {
    required Set<String> skipLeafPaths,
    Set<String>? skipSubtreePrefixes,
  }) {
    final prefixes = skipSubtreePrefixes ?? {};
    final out = <MapEntry<String, String>>[];

    bool skipBranch(String path) {
      for (final p in prefixes) {
        if (path == p || path.startsWith('$p.')) return true;
      }
      return false;
    }

    void visit(Map<String, dynamic> node, String prefix) {
      node.forEach((k, v) {
        final path = prefix.isEmpty ? k : '$prefix.$k';
        if (skipLeafPaths.contains(path) || skipBranch(path)) return;
        if (v == null) return;

        if (v is num) return;

        if (v is bool) {
          out.add(MapEntry(path, v ? 'نعم' : 'لا'));
        } else if (v is String) {
          final s = v.trim();
          if (s.isEmpty) return;
          if (s.startsWith('http://') || s.startsWith('https://')) return;
          out.add(
            MapEntry(
              path,
              s.length > 220 ? '${s.substring(0, 217)}…' : s,
            ),
          );
        } else if (v is Map) {
          visit(
            Map<String, dynamic>.from(
              v.map((ik, iv) => MapEntry(ik.toString(), iv)),
            ),
            path,
          );
        } else if (v is List) {
          if (v.length > 24) return;
          final parts = v.map((e) => e.toString()).where((e) => e.isNotEmpty);
          if (parts.isEmpty) return;
          out.add(MapEntry(path, parts.join(', ')));
        }
      });
    }

    visit(resolved, '');
    out.sort((a, b) => a.key.compareTo(b.key));
    return out;
  }
}
