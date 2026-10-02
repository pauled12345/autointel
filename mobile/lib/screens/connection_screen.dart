import 'package:flutter/material.dart';

import '../services/obd_service.dart';
import '../services/obd/obd_transport.dart';

/// Phase 1 screen: discover an ELM327 adapter, connect, and run the AT init
/// sequence, showing every command and response in a live log.
///
/// Flip the "Use mock adapter" switch to exercise the whole flow with no car.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final ObdService _obd = ObdService();
  final List<String> _log = [];
  final ScrollController _logScroll = ScrollController();

  List<ObdDevice> _devices = [];
  ObdDevice? _selected;
  bool _useMock = true;
  bool _busy = false;
  bool _initialized = false;
  String _status = 'Not connected';

  @override
  void dispose() {
    _obd.disconnect();
    _logScroll.dispose();
    super.dispose();
  }

  void _append(String line) {
    if (!mounted) return;
    setState(() => _log.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(
          _logScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setStatus(String value) {
    if (mounted) setState(() => _status = value);
  }

  Future<void> _scan() async {
    setState(() {
      _busy = true;
      _log.clear();
      _initialized = false;
      _status = 'Scanning…';
    });
    try {
      final devices = await _obd.scanForAdapters(useMock: _useMock);
      setState(() {
        _devices = devices;
        _selected = devices.isEmpty ? null : devices.first;
      });
      _append('Scan: ${devices.length} adapter(s) found');
      _setStatus(devices.isEmpty ? 'No adapters found' : 'Ready to connect');
    } catch (error) {
      _append('Scan error: $error');
      _setStatus('Scan failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connectAndInitialize() async {
    final device = _selected;
    if (device == null) return;
    setState(() {
      _busy = true;
      _log.clear();
      _initialized = false;
      _status = 'Connecting to ${device.name}…';
    });
    try {
      await _obd.connect(device, useMock: _useMock, onLog: _append);
      _append('Connected to ${device.name}');
      _setStatus('Running init sequence (ATZ, ATE0, ATSP0)…');
      final result = await _obd.initialize();
      _append('Init complete → $result');
      _setStatus('Initialized');
      setState(() => _initialized = true);
    } catch (error) {
      _append('Error: $error');
      _setStatus('Connection failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    await _obd.disconnect();
    _append('Disconnected');
    setState(() {
      _initialized = false;
      _status = 'Not connected';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('OBD-II Connection')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              value: _useMock,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                        _useMock = value;
                        _devices = [];
                        _selected = null;
                        _log.clear();
                        _initialized = false;
                        _status = 'Not connected';
                      }),
              title: const Text('Use mock adapter'),
              subtitle: const Text('Simulate an ELM327 — no car or hardware needed'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _scan,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_busy || _selected == null)
                        ? null
                        : _connectAndInitialize,
                    icon: const Icon(Icons.link),
                    label: const Text('Connect & Init'),
                  ),
                ),
              ],
            ),
            if (_devices.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<ObdDevice>(
                value: _selected,
                decoration: const InputDecoration(
                  labelText: 'Adapter',
                  border: OutlineInputBorder(),
                ),
                items: _devices
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
                    .toList(),
                onChanged: _busy ? null : (d) => setState(() => _selected = d),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  _initialized ? Icons.check_circle : Icons.info_outline,
                  color: _initialized ? Colors.green : theme.colorScheme.primary,
                ),
                title: Text(_status),
                trailing: _obd.isConnected
                    ? TextButton(onPressed: _busy ? null : _disconnect, child: const Text('Disconnect'))
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('AT log', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (_log.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_log.clear),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _log.isEmpty
                    ? const Center(child: Text('Log will appear here…'))
                    : ListView.builder(
                        controller: _logScroll,
                        itemCount: _log.length,
                        itemBuilder: (context, index) {
                          final line = _log[index];
                          final isIncoming = line.startsWith('<');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: isIncoming
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
