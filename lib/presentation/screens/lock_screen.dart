import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../providers/app_providers.dart';

/// Unlock screen. It only appears when a PIN digest exists on the device;
/// arming and disarming the lock happens in Settings.
class PinGateScreen extends ConsumerStatefulWidget {
  const PinGateScreen({super.key});

  @override
  ConsumerState<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends ConsumerState<PinGateScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.isEmpty || _busy) return;
    setState(() => _busy = true);

    final ok = await ref.read(appLockProvider).verify(pin);

    if (!mounted) return;
    _controller.clear();
    setState(() {
      _busy = false;
      _wrong = !ok;
    });
    if (ok) ref.read(lockGateProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.lockTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.numberWithOptions(decimal: false),
                  maxLength: 12,
                  decoration: InputDecoration(
                    labelText: l10n.lockEnterPin,
                    errorText: _wrong ? l10n.lockWrongPin : null,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.lockUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
