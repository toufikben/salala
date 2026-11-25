import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../services/app_lock_service.dart';
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

  /// Seconds left before the gate will answer again, from the count the service
  /// keeps in the keystore. Zero means "ask me now".
  int _retryIn = 0;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    // A launch inside a lockout has to open on the refusal, not on a field that
    // accepts a PIN and then says no: the count is the service's, and this is
    // the same count the submit below extends.
    ref.read(appLockProvider).lockoutRemaining().then((left) {
      if (!mounted || left == null) return;
      _startCountdown(left.inSeconds);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdown?.cancel();
    setState(() {
      _retryIn = seconds;
      _wrong = false;
    });
    if (seconds <= 0) return;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _retryIn = _retryIn > 0 ? _retryIn - 1 : 0);
      if (_retryIn == 0) timer.cancel();
    });
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.isEmpty || _busy || _retryIn > 0) return;
    setState(() => _busy = true);

    // The flag comes back down whatever the keystore answers, an error included:
    // `_busy` doubles as the button's disable switch, so leaving it set by a call
    // that threw would have locked the breeder out behind a spinner with the field
    // still begging for a PIN.
    final PinAttempt answer;
    try {
      answer = await ref.read(appLockProvider).attempt(pin).whenComplete(() {
        if (mounted) setState(() => _busy = false);
      });
    } catch (error) {
      // A keystore that will not answer is not a PIN that was accepted, and the
      // gate must still be able to ask again: the field goes red rather than the
      // screen sitting behind a spinner it will never leave.
      debugPrint('PIN check failed: $error');
      if (!mounted) return;
      setState(() => _wrong = true);
      return;
    }

    if (!mounted) return;
    _controller.clear();
    if (answer.accepted) {
      ref.read(lockGateProvider.notifier).unlock();
      return;
    }
    final wait = answer.retryAfter;
    if (wait == null) {
      setState(() => _wrong = true);
      return;
    }
    _startCountdown(wait.inSeconds);
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
                  enabled: _retryIn == 0,
                  keyboardType: TextInputType.numberWithOptions(decimal: false),
                  maxLength: 12,
                  decoration: InputDecoration(
                    labelText: l10n.lockEnterPin,
                    errorText: _retryIn > 0
                        ? l10n.lockTooManyAttempts(_retryIn)
                        : (_wrong ? l10n.lockWrongPin : null),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy || _retryIn > 0 ? null : _submit,
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
