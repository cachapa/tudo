import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../common/dialogs.dart';
import '../config.dart';
import '../extensions.dart';
import '../registry.dart';

void showServerConfigurationPanel(BuildContext context) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  builder: (context) => const ServerConfigurationPanel(),
);

class ServerConfigurationPanel extends StatefulWidget {
  const ServerConfigurationPanel({super.key});

  @override
  State<ServerConfigurationPanel> createState() =>
      _ServerConfigurationPanelState();
}

class _ServerConfigurationPanelState extends State<ServerConfigurationPanel> {
  final _controller = TextEditingController(
    text: Registry.settingsProvider.serverUri.toString(),
  );

  var _testing = false;

  String get _uri => _controller.text;

  bool get _validUri =>
      (_uri.startsWith('http://') || _uri.startsWith('https://')) &&
      Uri.tryParse(_uri) != null &&
      !_uri.endsWith('/');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.none,
            textCapitalization: TextCapitalization.none,
            // Force state update to check if url is valid
            onChanged: (value) => setState(() {}),
            onSubmitted: (_) => _test(),
            decoration: InputDecoration(
              suffixIcon: _uri == defaultUri.toString()
                  ? null
                  : IconButton(
                      color: context.theme.primaryColor,
                      icon: const Icon(Icons.restart_alt_rounded),
                      tooltip: context.t.reset,
                      onPressed: _reset,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: !_testing && _validUri ? _test : null,
                  child: Text(context.t.test.toUpperCase()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _validUri ? _set : null,
                  child: Text(context.t.set.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _reset() => setState(() => _controller.text = defaultUri.toString());

  Future<void> _test() async {
    try {
      if (_testing) return;
      setState(() => _testing = true);

      final result = await http.head(Uri.parse('$_uri/check_version'));

      if (mounted && result.statusCode ~/ 100 == 2) {
        await showMessageDialog(context, 'OK');
      } else {
        throw '${result.statusCode} ${result.body}';
      }
    } catch (e) {
      if (!mounted) return;
      await showMessageDialog(context, '$e');
    } finally {
      _testing = false;
    }
  }

  void _set() {
    Registry.settingsProvider.setServerUri(_uri);
    context.pop();
  }
}
