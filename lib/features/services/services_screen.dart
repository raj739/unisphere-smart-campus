import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  Map<String, dynamic>? _fees;
  List<dynamic> _payments = const [];
  List<dynamic> _examinations = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Future.wait<dynamic>([UniSphereApiService.getFeeSummary(), UniSphereApiService.getPayments(), UniSphereApiService.getExaminations()]);
      if (mounted) setState(() { _fees = Map<String, dynamic>.from(data[0] as Map); _payments = List<dynamic>.from(data[1] as List); _examinations = List<dynamic>.from(data[2] as List); });
    } on ApiException catch (error) { if (mounted) setState(() => _error = error.message); }
    catch (_) { if (mounted) setState(() => _error = 'Unable to load student services.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: SafeArea(child: RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(28), children: [
        Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Student Services', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)), SizedBox(height: 8), Text('Fees, payments, and examination information.', style: TextStyle(color: Color(0xFF64748B)))])), IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))]),
        const SizedBox(height: 24),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (_error != null) Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 42), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry'))]))
        else ...[
          Wrap(spacing: 16, runSpacing: 16, children: [_metric('Total fee', '${_fees?['total_amount'] ?? '-'}', Icons.account_balance_wallet_outlined), _metric('Paid', '${_fees?['paid_amount'] ?? '-'}', Icons.check_circle_outline), _metric('Outstanding', '${_fees?['outstanding_amount'] ?? '-'}', Icons.pending_actions_outlined), _metric('Payments', '${_payments.length}', Icons.payments_outlined)]),
          const SizedBox(height: 24), Text('Payment History', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 12),
          if (_payments.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No payments are available.')))
          else ..._payments.map((item) { final payment = Map<String, dynamic>.from(item as Map); return Card(child: ListTile(leading: const Icon(Icons.payments_outlined), title: Text(payment['payment_reference']?.toString() ?? 'Payment'), subtitle: Text(payment['payment_date']?.toString() ?? ''), trailing: Text('${payment['amount'] ?? '-'}'))); }),
          const SizedBox(height: 24), Text('Examinations', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 12),
          if (_examinations.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No examinations are scheduled.')))
          else ..._examinations.map((item) { final exam = Map<String, dynamic>.from(item as Map); return Card(child: ListTile(leading: const Icon(Icons.assignment_outlined), title: Text(exam['examination_name']?.toString() ?? exam['course_name']?.toString() ?? 'Examination'), subtitle: Text('${exam['exam_date'] ?? '-'} | ${exam['start_time'] ?? '-'}'), trailing: Text(exam['venue']?.toString() ?? '-'))); }),
        ],
      ]),
    )),
  );

  Widget _metric(String label, String value, IconData icon) => SizedBox(width: 200, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(icon, color: const Color(0xFF2563EB)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xFF64748B))), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))])]))));
}
