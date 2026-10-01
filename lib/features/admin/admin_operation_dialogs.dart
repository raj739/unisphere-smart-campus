import 'package:flutter/material.dart';

Future<String?> chooseAdminOperation(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<(String, String, IconData)> options,
}) => showDialog<String>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map(
                  (option) => SizedBox(
                    width: 158,
                    height: 82,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, option.$1),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(option.$3, size: 22),
                          const SizedBox(height: 7),
                          Text(
                            option.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Cancel'),
      ),
    ],
  ),
);

Future<Map<String, dynamic>?> pickAdminRecord(
  BuildContext context, {
  required String title,
  required List<Map<String, dynamic>> items,
  required String Function(Map<String, dynamic>) label,
  required String Function(Map<String, dynamic>) subtitle,
}) async {
  if (items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No available records. Create the required record first.',
        ),
      ),
    );
    return null;
  }
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        height: items.length > 5 ? 430 : null,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final item = items[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
              leading: CircleAvatar(child: Text(item['id']?.toString() ?? '?')),
              title: Text(
                label(item),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(subtitle(item)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(dialogContext, item),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

Future<List<String>?> showAdminForm(
  BuildContext context, {
  required String title,
  required List<String> labels,
  int maximumCapacity = 200,
}) => showDialog<List<String>>(
  context: context,
  builder: (_) => _AdminFormDialog(
    title: title,
    labels: labels,
    maximumCapacity: maximumCapacity,
  ),
);

class _AdminFormDialog extends StatefulWidget {
  const _AdminFormDialog({
    required this.title,
    required this.labels,
    required this.maximumCapacity,
  });

  final String title;
  final List<String> labels;
  final int maximumCapacity;

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.labels.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(String label, String? value) {
    final text = value?.trim() ?? '';
    final normalized = label.toLowerCase();
    if (text.isEmpty) {
      return normalized.contains('optional') ? null : 'Required';
    }
    final numeric =
        normalized.contains('floors') ||
        normalized == 'floor' ||
        normalized.contains('capacity') ||
        normalized.contains('sequence number');
    if (numeric) {
      final number = int.tryParse(text);
      if (number == null) return 'Enter a whole number';
      if (normalized == 'floor' && number < 0) {
        return 'Floor cannot be negative';
      }
      if (normalized != 'floor' && number < 1) {
        return 'Enter a number greater than zero';
      }
      if (normalized.contains('capacity') && number > widget.maximumCapacity) {
        return 'Capacity cannot exceed ${widget.maximumCapacity}';
      }
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _controllers.map((controller) => controller.text.trim()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < widget.labels.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _controllers[index],
                    decoration: InputDecoration(
                      labelText: widget.labels[index],
                      prefixIcon: const Icon(Icons.edit_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _validate(widget.labels[index], value),
                    onFieldSubmitted: (_) {
                      if (index == widget.labels.length - 1) {
                        _submit();
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save'),
      ),
    ],
  );
}
