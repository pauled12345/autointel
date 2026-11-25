import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dtc.dart';
import '../services/ai_service.dart';
import '../services/data_repository.dart';
import '../services/diagnostics_service.dart';
import '../services/obd_service.dart';
import '../services/obd/pid_parser.dart';
import '../utils/bluetooth_permissions.dart';
import '../utils/severity.dart';
import 'chat_screen.dart';

/// Main diagnostics workflow: connect to a paired ELM327 adapter over
/// Bluetooth Classic, read/clear DTCs, watch live PIDs, and get an AI
/// explanation for each code.
class DiagnosticsScreen extends StatefulWidget {
  final String vehicleId;

  /// When true, runs the full flow (connect → read codes → live data) on first
  /// build.
  final bool autoRun;

  /// Injectable data layer (for tests). Defaults to a real [DataRepository].
  final DataRepository? repository;

  const DiagnosticsScreen({
    super.key,
    required this.vehicleId,
    this.autoRun = false,
    this.repository,
  });

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final ObdService _obd = ObdService();
  final AiService _ai = const AiService();
  late final DataRepository _repo = widget.repository ?? DataRepository();
  final List<String> _log = [];

  DiagnosticsService? _diagnostics;
  String? _sessionId;
  List<Dtc> _codes = [];
  List<PidReading> _live = [];
  Timer? _pollTimer;

  bool _busy = false;
  bool _initialized = false;
  bool _polling = false;
  String _status = 'Not connected';

  @override
  void initState() {
    super.initState();
    if (widget.autoRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runFullDiagnostic());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _obd.disconnect();
    super.dispose();
  }

  // ---------------------------------------------------------------- connection

  Future<void> _connectAndInit() async {
    setState(() {
      _busy = true;
      _log.clear();
      _codes = [];
      _live = [];
      _initialized = false;
      _status = 'Connecting…';
    });
    try {
      final granted = await ensureBluetoothPermissions();
      if (!granted) {
        _append('Bluetooth permission denied');
        setState(() => _status = 'Permission denied');
        return;
      }
      final devices = await _obd.scanForAdapters();
      if (devices.isEmpty) {
        _append('No paired ELM327 adapter found. Pair it in Android Bluetooth settings.');
        setState(() => _status = 'No adapter found');
        return;
      }
      await _obd.connect(devices.first, onLog: _append);
      _append('Connected');
      setState(() => _status = 'Running init sequence (ATZ, ATE0, ATSP0)…');
      final result = await _obd.initialize();
      _append('Init complete → $result');
      _diagnostics = DiagnosticsService(_obd.client!);
      setState(() {
        _initialized = true;
        _status = 'Initialized';
      });
    } catch (error) {
      _append('Error: $error');
      setState(() => _status = 'Connection failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    _stopPolling();
    _endSession();
    await _obd.disconnect();
    setState(() {
      _diagnostics = null;
      _initialized = false;
      _status = 'Not connected';
      _codes = [];
      _live = [];
    });
  }

  Future<void> _endSession() async {
    final sessionId = _sessionId;
    _sessionId = null;
    if (sessionId == null) return;
    try {
      await _repo.endDiagnosticsSession(sessionId);
    } catch (_) {
      // best-effort — ignore end-session failures
    }
  }

  // ---------------------------------------------------------------- operations

  /// The one-tap flow: connect + init, read codes with AI explanations, then
  /// start streaming live data.
  Future<void> _runFullDiagnostic() async {
    await _connectAndInit();
    if (!_initialized) return;
    await _readCodes();
    if (mounted) _togglePolling(true);
  }

  Future<void> _readCodes() async {
    final service = _diagnostics;
    if (service == null) return;
    setState(() => _busy = true);
    try {
      final codes = await service.readFaultCodes();
      final enriched = await _explainCodes(codes);
      setState(() => _codes = enriched);
      _append('Read ${enriched.length} fault code(s): ${codes.join(', ')}');
    } catch (error) {
      _append('Read failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Explains codes via the backend (which caches the AI result), falling back
  /// to the offline knowledge base when the backend is unreachable.
  Future<List<Dtc>> _explainCodes(List<String> codes) async {
    try {
      final sessionId = await _repo.startDiagnosticsSession(widget.vehicleId);
      _sessionId = sessionId;
      final enriched = <Dtc>[];
      for (final code in codes) {
        final fault = await _repo.reportFaultCode(sessionId, code);
        enriched.add(Dtc(
          code: code,
          severity: fault.severity ?? 'medium',
          diagnosis: fault.diagnosis,
        ));
      }
      return enriched;
    } catch (_) {
      // backend unreachable — use the local AI knowledge base
      final enriched = <Dtc>[];
      for (final code in codes) {
        final ai = await _ai.explain(code);
        enriched.add(Dtc(
          code: code,
          severity: ai.severity,
          diagnosis: ai,
        ));
      }
      return enriched;
    }
  }

  Future<void> _clearCodes() async {
    final service = _diagnostics;
    if (service == null) return;
    setState(() => _busy = true);
    try {
      final ok = await service.clearFaultCodes();
      setState(() => _codes = []);
      _append(ok ? 'Fault codes cleared (Mode 04)' : 'Clear codes not confirmed');
    } catch (error) {
      _append('Clear failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshLive() async {
    final service = _diagnostics;
    if (service == null) return;
    try {
      final readings = await service.readLiveData();
      if (mounted) setState(() => _live = readings);
      _reportSensorReadings(readings);
    } catch (error) {
      _append('Live data failed: $error');
      _stopPolling();
    }
  }

  void _reportSensorReadings(List<PidReading> readings) {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    for (final r in readings) {
      _sendSensorReading(sessionId, r);
    }
  }

  Future<void> _sendSensorReading(String sessionId, PidReading reading) async {
    try {
      await _repo.reportSensorReading(
        sessionId,
        reading.spec.name,
        reading.value,
        reading.spec.unit,
      );
    } catch (_) {
      // best-effort — ignore reporting failures
    }
  }

  void _togglePolling(bool value) {
    setState(() => _polling = value);
    if (value) {
      _refreshLive();
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshLive());
    } else {
      _stopPolling();
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (mounted && _polling) setState(() => _polling = false);
  }

  void _append(String line) {
    if (!mounted) return;
    setState(() => _log.add(line));
  }

  // ----------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdapterCard(),
          const SizedBox(height: 12),
          _buildActionsCard(),
          const SizedBox(height: 12),
          _buildFaultCodesCard(),
          const SizedBox(height: 12),
          _buildLiveDataCard(),
          const SizedBox(height: 12),
          _buildLogCard(),
        ],
      ),
    );
  }

  Widget _buildAdapterCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Icon(
            _initialized ? Icons.check_circle : Icons.bluetooth,
            color: _initialized ? Colors.green : theme.colorScheme.primary,
          ),
          title: Text(_status),
          subtitle: const Text('Paired Bluetooth Classic (SPP) ELM327 adapter'),
          trailing: _initialized
              ? TextButton(
                  onPressed: _busy ? null : _disconnect,
                  child: const Text('Disconnect'),
                )
              : FilledButton(
                  onPressed: _busy ? null : _connectAndInit,
                  child: const Text('Connect & Init'),
                ),
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    final enabled = _initialized && !_busy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _runFullDiagnostic,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Full Diagnostic'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: enabled ? _readCodes : null,
                    icon: const Icon(Icons.search),
                    label: const Text('Read Codes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: enabled && _codes.isNotEmpty ? _clearCodes : null,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear Codes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaultCodesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber),
                const SizedBox(width: 8),
                Text(
                  'Fault Codes (${_codes.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_codes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No codes loaded. Tap "Read Codes".'),
              )
            else
              ..._codes.map(_buildCodeTile),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeTile(Dtc dtc) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _severityColor(dtc.severity),
        child: Text(
          dtc.code.substring(0, 1),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(dtc.code, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        dtc.explanation ?? dtc.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Chip(
        label: Text(dtc.severity),
        backgroundColor: _severityColor(dtc.severity).withOpacity(0.2),
      ),
      onTap: () => _showExplanation(dtc),
    );
  }

  void _showExplanation(Dtc dtc) {
    final diagnosis = dtc.diagnosis;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome),
            const SizedBox(width: 8),
            Expanded(child: Text('AI · ${dtc.code}')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _severityBadge(dtc.severity),
              const SizedBox(height: 16),
              _sectionTitle(context, 'What it means'),
              Text(
                diagnosis?.plainExplanation.isNotEmpty == true
                    ? diagnosis!.plainExplanation
                    : (dtc.description.isNotEmpty ? dtc.description : 'No explanation available.'),
              ),
              if (diagnosis != null && diagnosis.symptoms.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Symptoms'),
                ...diagnosis.symptoms.map(_bullet),
              ],
              if (diagnosis != null && diagnosis.likelyCauses.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Likely causes'),
                ...diagnosis.likelyCauses.map(_bullet),
              ],
              if (diagnosis != null && diagnosis.recommendedAction.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'What to do'),
                Text(diagnosis.recommendedAction),
              ],
              if (diagnosis != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Difficulty: ${_capitalize(diagnosis.repairDifficulty)}')),
                    if (diagnosis.estimatedCost.isNotEmpty)
                      Chip(label: Text('Est. cost: ${diagnosis.estimatedCost}')),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _disclaimerNote(context),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                this.context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    initialPrompt:
                        'I just got fault code ${dtc.code}. Can you tell me more about it and what I should do?',
                  ),
                ),
              );
            },
            child: const Text('Discuss with AI'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _severityBadge(String severity) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Severity: ${severity.toUpperCase()}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _disclaimerNote(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline,
            size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'AI-generated guidance — not a substitute for a professional '
            'mechanic. Verify before acting.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildLiveDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed),
                const SizedBox(width: 8),
                Text('Live Data', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Switch(
                  value: _polling,
                  onChanged: _initialized ? _togglePolling : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_live.isEmpty)
              const Text('No live data. Enable polling or refresh.')
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: _live.map(_buildStatTile).toList(),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: (_initialized && !_busy) ? _refreshLive : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AT log', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: _log.isEmpty
                  ? const Center(child: Text('Log will appear here…'))
                  : ListView.builder(
                      itemCount: _log.length,
                      itemBuilder: (context, index) => Text(
                        _log[index],
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(PidReading reading) {
    final theme = Theme.of(context);
    final spec = reading.spec;
    final max = _maxFor(spec.pid);
    final fraction = max == 0 ? 0.0 : (reading.value / max).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(spec.name, style: theme.textTheme.bodySmall),
          Text(
            '${reading.value.toStringAsFixed(spec.pid == '010C' ? 0 : 1)} ${spec.unit}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }

  double _maxFor(String pid) {
    switch (pid) {
      case '010C':
        return 8000; // RPM
      case '010D':
        return 220; // km/h
      case '0105':
        return 120; // °C
      case '0104':
        return 100; // %
      case '012F':
        return 100; // %
      case '015E':
        return 40; // L/h
      case 'DERIVED_KM_L':
        return 30; // km/l
      default:
        return 0;
    }
  }

  Color _severityColor(String severity) => severityColor(severity);
}
