import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../providers/app_providers.dart';

/// Two-step PIN entry. Returns the PIN, or null if the user backed out.
Future<String?> showPinSetupDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => const _PinSetupDialog(),
  );
}

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final pin = _pin.text.trim();
    final confirm = _confirm.text.trim();

    if (pin.length < 4) {
      setState(() => _error = l10n.lockPinTooShort);
      return;
    }
    if (pin != confirm) {
      setState(() => _error = l10n.lockPinMismatch);
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final digitFilter = FilteringTextInputFormatter.digitsOnly;

    return AlertDialog(
      title: Text(l10n.lockSetPinTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.lockSetPinBody),
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[digitFilter],
            maxLength: 12,
            decoration: InputDecoration(
              labelText: l10n.lockEnterPin,
              errorText: _error,
            ),
          ),
          TextField(
            controller: _confirm,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[digitFilter],
            maxLength: 12,
            decoration: InputDecoration(labelText: l10n.lockConfirmPin),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }
}

/// Asks for the current PIN and verifies it against the stored digest.
Future<bool> askCurrentPin(BuildContext context, WidgetRef ref) async {
  final entered = await showDialog<String>(
    context: context,
    builder: (dialogContext) => const _PinPromptDialog(),
  );
  if (entered == null || entered.trim().isEmpty) return false;

  final ok = await ref.read(appLockProvider).verify(entered.trim());
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lockWrongPin)),
    );
  }
  return ok;
}

class _PinPromptDialog extends StatefulWidget {
  const _PinPromptDialog();

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.lockEnterPin),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        maxLength: 12,
        decoration: InputDecoration(labelText: l10n.lockCurrentPin),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.lockUnlock),
        ),
      ],
    );
  }
}
