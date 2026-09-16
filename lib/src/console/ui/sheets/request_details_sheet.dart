import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/network_entry.dart';
import '../theme/console_theme.dart';
import '../widgets/copy_button.dart';
import '../widgets/copy_toast.dart';
import '../widgets/json_viewer.dart';
import '../widgets/method_badge.dart';
import '../widgets/status_badge.dart';

/// Opens the Request Details bottom sheet for [entry].
void showRequestDetailsSheet(
  BuildContext context,
  NetworkEntry entry,
  ConsoleTheme theme,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99030509),
    builder: (_) => ConsoleThemeScope(
      theme: theme,
      child: ConsoleToastHost(child: _RequestSheet(entry: entry)),
    ),
  );
}

String _pretty(dynamic body) {
  if (body == null) return '';
  try {
    if (body is String) {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    }
    return const JsonEncoder.withIndent('  ').convert(body);
  } catch (_) {
    return body.toString();
  }
}

class _RequestSheet extends StatelessWidget {
  const _RequestSheet({required this.entry});

  final NetworkEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: ConsoleTheme.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: ConsoleTheme.borderStrong)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _GrabHandle(),
          _header(context, t),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _urlSection(t),
                const SizedBox(height: 16),
                _overview(t),
                if (entry.error != null) ...[
                  const SizedBox(height: 16),
                  _errorBanner(t),
                ],
                const SizedBox(height: 16),
                _Section(
                  title: 'Request Headers',
                  child: _headers(t, entry.requestHeaders),
                ),
                if (entry.requestBody != null)
                  _Section(
                    title: 'Request Body',
                    initiallyOpen: true,
                    trailing: CopyLabelButton(
                      text: _pretty(entry.requestBody),
                      accentLink: true,
                    ),
                    child: JsonViewer(entry.requestBody),
                  ),
                _Section(
                  title: 'Response Headers',
                  child: _headers(t, entry.responseHeaders),
                ),
                _Section(
                  title: 'Response Body',
                  initiallyOpen: true,
                  trailing: CopyLabelButton(
                    text: _pretty(entry.responseBody),
                    accentLink: true,
                  ),
                  child: JsonViewer(entry.responseBody),
                ),
                _Section(
                  title: 'Timing',
                  child: _Timing(entry: entry),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, ConsoleTheme t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ConsoleTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          MethodBadge(entry.method),
          const SizedBox(width: 10),
          StatusBadge(entry.statusCode, large: true),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ConsoleTheme.elevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, size: 18, color: ConsoleTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _urlSection(ConsoleTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'REQUEST URL',
              style: t.ui(size: 12, weight: FontWeight.w800, color: ConsoleTheme.muted, letterSpacing: 0.7),
            ),
            const Spacer(),
            CopyLabelButton(text: entry.url),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: ConsoleTheme.codeGround,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ConsoleTheme.borderFaint),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: entry.host,
                  style: t.mono(size: 12.5, color: ConsoleTheme.muted, height: 1.6),
                ),
                TextSpan(
                  text: entry.path,
                  style: t.mono(size: 12.5, color: ConsoleTheme.jsonKey, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _overview(ConsoleTheme t) {
    final statusName = _statusName(entry.statusCode);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 2.6,
      children: [
        _tile(t, 'Status', statusName, t.statusColor(entry.statusCode)),
        _tile(t, 'Duration', entry.durationLabel, t.durationColor(entry.duration)),
        _tile(t, 'Method', entry.method.toUpperCase(), t.methodColor(entry.method)),
        _tile(t, 'Size · Time', '${entry.sizeLabel} · ${entry.formattedTime}', ConsoleTheme.textDim2),
      ],
    );
  }

  Widget _tile(ConsoleTheme t, String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: ConsoleTheme.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: t.ui(size: 11, weight: FontWeight.w700, color: ConsoleTheme.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.mono(size: 15, weight: FontWeight.w800, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(ConsoleTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ConsoleTheme.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ConsoleTheme.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 15, color: ConsoleTheme.red),
              const SizedBox(width: 6),
              Text('Error', style: t.ui(size: 13, weight: FontWeight.w800, color: ConsoleTheme.red)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.error ?? '',
            style: t.mono(size: 12.5, color: const Color(0xFFFCA5A5), height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _headers(ConsoleTheme t, Map<String, dynamic>? headers) {
    if (headers == null || headers.isEmpty) {
      return Text('No headers', style: t.mono(size: 12, color: ConsoleTheme.muted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in headers.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${e.key}: ',
                    style: t.mono(size: 12, weight: FontWeight.w600, color: ConsoleTheme.jsonKey),
                  ),
                  TextSpan(
                    text: '${e.value}',
                    style: t.mono(size: 12, color: ConsoleTheme.textDim3),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _statusName(int? status) {
    return switch (status) {
      null => 'Pending',
      200 => '200 OK',
      201 => '201 Created',
      204 => '204 No Content',
      304 => '304 Not Modified',
      400 => '400 Bad Request',
      401 => '401 Unauthorized',
      403 => '403 Forbidden',
      404 => '404 Not Found',
      500 => '500 Internal Error',
      _ => '$status',
    };
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: ConsoleTheme.handle,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatefulWidget {
  const _Section({
    required this.title,
    required this.child,
    this.initiallyOpen = false,
    this.trailing,
  });

  final String title;
  final Widget child;
  final bool initiallyOpen;
  final Widget? trailing;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: ConsoleTheme.sheet,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: t.ui(size: 13, weight: FontWeight.w700, color: ConsoleTheme.textDim2),
                  ),
                  const Spacer(),
                  if (widget.trailing != null) ...[
                    widget.trailing!,
                    const SizedBox(width: 10),
                  ],
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: t.reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, size: 18, color: ConsoleTheme.muted),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              width: double.infinity,
              color: ConsoleTheme.codeGround,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class _Timing extends StatelessWidget {
  const _Timing({required this.entry});

  final NetworkEntry entry;

  static const _phases = <(String, double, Color)>[
    ('DNS Lookup', 0.06, ConsoleTheme.violet),
    ('Initial Connection', 0.10, ConsoleTheme.cyan),
    ('TLS Handshake', 0.14, ConsoleTheme.amber),
    ('Waiting (TTFB)', 0.50, ConsoleTheme.blue),
    ('Content Download', 0.20, ConsoleTheme.green),
  ];

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final total = entry.duration?.inMilliseconds;
    if (total == null) {
      return Text('Waiting… in-flight', style: t.mono(size: 12, color: ConsoleTheme.cyan));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final phase in _phases) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(phase.$1, style: t.ui(size: 11.5, weight: FontWeight.w600, color: ConsoleTheme.textSecondary)),
                    const Spacer(),
                    Text('${(total * phase.$2).round()}ms', style: t.mono(size: 11, color: ConsoleTheme.muted)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: 6,
                    color: ConsoleTheme.borderFaint,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: phase.$2.clamp(0.04, 1.0)),
                        duration: t.reduceMotion ? Duration.zero : const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => FractionallySizedBox(
                          widthFactor: value,
                          child: Container(color: phase.$3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
