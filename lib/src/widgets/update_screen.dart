import 'dart:io';

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

class UpgraderScope extends InheritedWidget {
  final UpgraderConfig configs;

  const UpgraderScope({
    super.key,
    required this.configs,
    required super.child,
  });

  static UpgraderConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UpgraderScope>();
    assert(scope != null, 'XConfigScope não encontrado no contexto.');
    return scope!.configs;
  }

  @override
  bool updateShouldNotify(covariant UpgraderScope old) =>
      configs != old.configs;
}

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({
    super.key,
    required this.cupertino,
    required this.title,
    required this.message,
    required this.releaseNotes,
    required this.showIgnore,
    required this.showLater,
    required this.messages,
    required this.onClose,
    required this.onIgnore,
    required this.onLater,
    required this.onUpdate,
    this.cupertinoButtonTextStyle,
  });

  final bool cupertino;
  final String title;
  final String message;
  final String? releaseNotes;
  final bool showIgnore;
  final bool showLater;
  final UpgraderMessages messages;
  final VoidCallback onClose;
  final VoidCallback onIgnore;
  final VoidCallback onLater;
  final VoidCallback onUpdate;
  final TextStyle? cupertinoButtonTextStyle;

  // TODO: ajuste os links da loja para o seu app
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.app';
  static const String iosStoreUrl = 'https://apps.apple.com/app/id0000000000';

  Future<void> _openStore() async {
    final uri = Uri.parse(Platform.isIOS ? iosStoreUrl : androidStoreUrl);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = UpgraderScope.of(context);
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const _AppBadge(),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w400),
                ),
                const Spacer(),
                // botão principal
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scope.primary,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    fixedSize: Size.fromHeight(48),
                    shadowColor: scope.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: onUpdate,
                  child: Text(
                    messages.message(UpgraderMessage.buttonTitleUpdate)!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: scope.primary,
                    fixedSize: Size.fromHeight(48),
                  ),
                  onPressed: onLater,
                  child: Text(
                    messages.message(UpgraderMessage.buttonTitleLater)!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AppBadge extends StatelessWidget {
  const _AppBadge();

  @override
  Widget build(BuildContext context) {
    final scope = UpgraderScope.of(context);
    return ClipOval(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: scope.primary.withOpacity(.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            './assets/chatskills.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
