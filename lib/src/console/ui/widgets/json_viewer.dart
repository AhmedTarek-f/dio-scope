import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/console_theme.dart';

/// A compact, collapsible, syntax-highlighted JSON tree (Postman-style).
///
/// Accepts a decoded value (`Map`/`List`/scalar) or a JSON `String` (decoded
/// automatically; shown as raw text if it isn't valid JSON). Nodes auto-collapse
/// at depth >= 3 and cap very large collections.
class JsonViewer extends StatelessWidget {
  /// The value (or JSON string) to render.
  final dynamic data;

  /// Creates a JSON viewer.
  const JsonViewer(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final parsed = _coerce(data);
    if (parsed is! Map && parsed is! List) {
      // Scalar / non-JSON string — render as a single leaf line.
      return Text.rich(
        _leafSpan(t, null, parsed),
        style: t.mono(size: 12, height: 1.7),
      );
    }
    return _JsonNode(value: parsed, depth: 0);
  }

  static dynamic _coerce(dynamic d) {
    if (d is String) {
      try {
        return jsonDecode(d);
      } catch (_) {
        return d;
      }
    }
    return d;
  }
}

const int _kChildCap = 200;

class _JsonNode extends StatefulWidget {
  const _JsonNode({required this.value, required this.depth, this.propertyKey});

  final dynamic value;
  final int depth;
  final String? propertyKey;

  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
  late bool _expanded = widget.depth < 3;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final value = widget.value;
    final isMap = value is Map;
    final isList = value is List;
    if (!isMap && !isList) {
      return Padding(
        padding: EdgeInsets.only(left: widget.depth * 14.0),
        child: Text.rich(
          _leafSpan(t, widget.propertyKey, value),
          style: t.mono(size: 12, height: 1.7),
        ),
      );
    }

    final items = isMap
        ? (value).entries
              .map((e) => MapEntry<String?, dynamic>(e.key.toString(), e.value))
              .toList()
        : [for (final v in value as List) MapEntry<String?, dynamic>(null, v)];
    final open = isMap ? '{' : '[';
    final close = isMap ? '}' : ']';
    final count = items.length;

    final header = GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(left: widget.depth * 14.0, top: 1, bottom: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedRotation(
              turns: _expanded ? 0.25 : 0,
              duration: t.reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: const Icon(
                Icons.chevron_right,
                size: 14,
                color: ConsoleTheme.muted,
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (widget.propertyKey != null) ...[
                      TextSpan(
                        text: '"${widget.propertyKey}"',
                        style: t.mono(size: 12, color: ConsoleTheme.jsonKey),
                      ),
                      TextSpan(
                        text: ': ',
                        style: t.mono(size: 12, color: ConsoleTheme.jsonPunct),
                      ),
                    ],
                    TextSpan(
                      text: open,
                      style: t.mono(size: 12, color: ConsoleTheme.jsonPunct),
                    ),
                    if (!_expanded)
                      TextSpan(
                        text: ' … $close',
                        style: t.mono(size: 12, color: ConsoleTheme.jsonPunct),
                      ),
                    TextSpan(
                      text: '  $count',
                      style: t.mono(size: 11, color: ConsoleTheme.mutedDim),
                    ),
                  ],
                ),
                style: t.mono(size: 12, height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );

    if (!_expanded) return header;

    final shown = items.take(_kChildCap).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        for (final entry in shown)
          _JsonNode(
            value: entry.value,
            depth: widget.depth + 1,
            propertyKey: entry.key,
          ),
        if (count > _kChildCap)
          Padding(
            padding: EdgeInsets.only(left: (widget.depth + 1) * 14.0),
            child: Text(
              '… ${count - _kChildCap} more',
              style: t.mono(size: 11, color: ConsoleTheme.mutedDim),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(left: widget.depth * 14.0),
          child: Text(
            close,
            style: t.mono(size: 12, color: ConsoleTheme.jsonPunct),
          ),
        ),
      ],
    );
  }
}

TextSpan _leafSpan(ConsoleTheme t, String? key, dynamic value) {
  final (text, color) = switch (value) {
    String v => ('"$v"', ConsoleTheme.jsonString),
    bool v => ('$v', ConsoleTheme.jsonBool),
    num v => ('$v', ConsoleTheme.jsonNumber),
    null => ('null', ConsoleTheme.jsonNull),
    _ => ('$value', ConsoleTheme.textDim3),
  };
  return TextSpan(
    children: [
      if (key != null) ...[
        TextSpan(text: '"$key"', style: t.mono(size: 12, color: ConsoleTheme.jsonKey)),
        TextSpan(text: ': ', style: t.mono(size: 12, color: ConsoleTheme.jsonPunct)),
      ],
      TextSpan(text: text, style: t.mono(size: 12, color: color)),
    ],
  );
}
