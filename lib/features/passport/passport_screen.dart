import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  Map<String, dynamic>? _passport;
  String? _error;
  bool _loading = true;
  bool _passportUnavailable = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _passportUnavailable = false;
    });
    try {
      final data = await UniSphereApiService.getAcademicPassport();
      if (mounted) setState(() => _passport = data);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _passportUnavailable = error.statusCode == 404;
          _error = error.statusCode == 404 ? null : error.message;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load academic passport.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(28), children: [
            Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Academic Passport', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)), SizedBox(height: 8), Text('Your verified academic identity.', style: TextStyle(color: Color(0xFF64748B)))])), IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))]),
            const SizedBox(height: 28),
            if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_error != null) _errorState()
            else if (_passportUnavailable) _unavailableState()
            else _passportCard(),
          ]),
        )),
      );

  Widget _passportCard() {
    final passport = _passport ?? const {};
    final token = passport['verification_token']?.toString() ?? passport['passport_number']?.toString() ?? '';
    return Card(
      color: const Color(0xFF172554),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(children: [
          const CircleAvatar(radius: 38, child: Icon(Icons.person_outline, size: 40)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(passport['full_name']?.toString() ?? 'Student', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('${passport['programme'] ?? '-'} | Semester ${passport['current_semester'] ?? '-'}', style: const TextStyle(color: Color(0xFFCBD5E1))),
            const SizedBox(height: 8),
            Text('Uni-ID: ${passport['uni_id'] ?? '-'}', style: const TextStyle(color: Color(0xFFCBD5E1))),
            const SizedBox(height: 12),
            Text('Passport: ${passport['passport_number'] ?? '-'}', style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w700)),
          ])),
          if (token.isNotEmpty) QrImageView(data: token, version: QrVersions.auto, size: 110, backgroundColor: Colors.white),
        ]),
      ),
    );
  }

  Widget _errorState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 42), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry'))]));

  Widget _unavailableState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.badge_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Your academic passport has not been generated yet.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Generate passport'),
            ),
          ]),
        ),
      );

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final passport = await UniSphereApiService.generateAcademicPassport();
      if (mounted) {
        setState(() {
          _passport = passport;
          _passportUnavailable = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to generate academic passport.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
