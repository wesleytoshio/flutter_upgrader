import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'widgets/update_screen.dart';

class UpgradeDialog extends StatefulWidget {
  UpgradeDialog({
    super.key,
    Upgrader? upgrader,
    this.barrierDismissible = false, // legado
    this.isDismissible, // NOVO (sobrescreve o legado se informado)
    this.isScrollControlled = false, // NOVO
    this.dialogStyle = UpgradeDialogStyle.material,
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.shouldPopScope,
    this.showIgnore = true,
    this.showLater = true,
    this.showReleaseNotes = true,
    this.cupertinoButtonTextStyle,
    this.dialogKey,
    this.navigatorKey,
    this.child,
    required this.configs,
  }) : upgrader = upgrader ?? Upgrader.sharedInstance;

  final Upgrader upgrader;

  /// legado (continua funcionando)
  final bool barrierDismissible;

  /// preferível: controla se o toque fora fecha o dialog
  final bool? isDismissible;

  /// quando true, remove `insetPadding` para permitir “full height”
  final bool isScrollControlled;

  final UpgradeDialogStyle dialogStyle;
  final BoolCallback? onIgnore;
  final BoolCallback? onLater;
  final BoolCallback? onUpdate;
  final BoolCallback? shouldPopScope;
  final bool showIgnore;
  final bool showLater;
  final bool showReleaseNotes;
  final TextStyle? cupertinoButtonTextStyle;
  final GlobalKey? dialogKey;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? child;
  final UpgraderConfig configs;

  @override
  UpgradeDialogState createState() => UpgradeDialogState();
}

class UpgradeDialogState extends State<UpgradeDialog> {
  bool displayed = false;

  @override
  void initState() {
    super.initState();
    widget.upgrader.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: widget.upgrader.state,
      stream: widget.upgrader.stateStream,
      builder: (context, snapshot) {
        if ((snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) &&
            snapshot.data != null) {
          if (snapshot.data!.versionInfo != null && !displayed) {
            final checkContext = widget.navigatorKey?.currentContext ?? context;
            checkVersion(context: checkContext);
          }
        }
        return widget.child ?? const SizedBox.shrink();
      },
    );
  }

  void checkVersion({required BuildContext context}) {
    if (!widget.upgrader.shouldDisplayUpgrade()) return;

    displayed = true;
    final appMessages = widget.upgrader.determineMessages(context);

    Future.microtask(() {
      showTheDialog(
        key: widget.dialogKey ?? const Key('upgrader_modal_dialog'),
        context: context,
        configs: widget.configs,
        title: appMessages.message(UpgraderMessage.title),
        message: widget.upgrader.body(appMessages),
        releaseNotes:
            shouldDisplayReleaseNotes ? widget.upgrader.releaseNotes : null,
        isDismissible: widget.isDismissible ?? widget.barrierDismissible,
        messages: appMessages,
      );
    });
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    if (widget.onIgnore?.call() ?? true) widget.upgrader.saveIgnored();
    if (shouldPop) popNavigator(context);
  }

  void onUserLater(BuildContext context, bool shouldPop) {
    widget.onLater?.call();
    if (shouldPop) popNavigator(context);
  }

  void onUserUpdated(BuildContext context, bool shouldPop) {
    final doProcess = widget.onUpdate?.call() ?? true;
    if (doProcess) widget.upgrader.sendUserToAppStore();
    if (shouldPop) popNavigator(context);
  }

  void popNavigator(BuildContext context) {
    Navigator.of(context).pop();
    displayed = false;
  }

  bool get shouldDisplayReleaseNotes =>
      widget.showReleaseNotes &&
      (widget.upgrader.releaseNotes?.isNotEmpty ?? false);

  bool onCanPop() => widget.shouldPopScope?.call() ?? false;

  // ========= showDialog com isDismissible & isScrollControlled =========
  void showTheDialog(
      {Key? key,
      required BuildContext context,
      required String? title,
      required String message,
      required String? releaseNotes,
      required bool isDismissible,
      required UpgraderMessages messages,
      required UpgraderConfig configs}) {
    if (!context.mounted) return;

    widget.upgrader.saveLastAlerted();

    final isCupertinoApp =
        context.findAncestorWidgetOfExactType<CupertinoApp>() != null;

    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      useSafeArea: false,
      builder: (ctx) {
        final cupertino = isCupertinoApp ||
            widget.dialogStyle == UpgradeDialogStyle.cupertino;

        return UpgraderScope(
          configs: configs,
          child: PopScope(
            canPop: onCanPop(),
            child: _UpgradeModalCard(
              cupertino: cupertino,
              title: title ?? '',
              message: message,
              releaseNotes: releaseNotes,
              showIgnore: widget.upgrader.blocked() ? false : widget.showIgnore,
              showLater: widget.upgrader.blocked() ? false : widget.showLater,
              messages: messages,
              onClose: () => onUserLater(ctx, true),
              onIgnore: () => onUserIgnored(ctx, true),
              onLater: () => onUserLater(ctx, true),
              onUpdate: () => onUserUpdated(ctx, !widget.upgrader.blocked()),
              cupertinoButtonTextStyle: widget.cupertinoButtonTextStyle,
            ),
          ),
        );
      },
    ).whenComplete(() => displayed = false);
  }
}

// ====== UI (idêntico ao modal anterior, reaproveitado no Dialog) ======
class _UpgradeModalCard extends StatelessWidget {
  const _UpgradeModalCard({
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: cupertino
          ? CupertinoTheme.of(context).scaffoldBackgroundColor
          : theme.colorScheme.surface,
      child: UpdateScreen(
        messages: messages,
        cupertino: cupertino,
        title: title,
        message: message,
        releaseNotes: releaseNotes,
        showIgnore: showIgnore,
        showLater: showLater,
        onClose: onClose,
        onIgnore: onIgnore,
        onLater: onLater,
        onUpdate: onUpdate,
      ),
    );
    return Material(
      color: cupertino
          ? CupertinoTheme.of(context).scaffoldBackgroundColor
          : theme.colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                tooltip: 'Fechar',
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: (cupertino
                        ? CupertinoTheme.of(context).primaryColor
                        : theme.colorScheme.primary)
                    .withOpacity(0.12),
              ),
              child: Icon(
                Icons.system_update_alt_rounded,
                size: 34,
                color: cupertino
                    ? CupertinoTheme.of(context).primaryColor
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title.isEmpty
                  ? (messages.message(UpgraderMessage.title) ??
                      'Update Available')
                  : title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              messages.message(UpgraderMessage.prompt) ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (releaseNotes != null) ...[
              const SizedBox(height: 16),
              _ReleaseNotes(
                releaseNotes: releaseNotes!,
                cupertino: cupertino,
                title: messages.message(UpgraderMessage.releaseNotes) ??
                    'Release notes',
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: cupertino
                  ? CupertinoButton.filled(
                      onPressed: onUpdate,
                      borderRadius: BorderRadius.circular(14),
                      child: Text(
                        messages.message(UpgraderMessage.buttonTitleUpdate) ??
                            'Update now',
                        style: cupertinoButtonTextStyle,
                      ),
                    )
                  : FilledButton(
                      onPressed: onUpdate,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                          messages.message(UpgraderMessage.buttonTitleUpdate) ??
                              'Update now'),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showLater)
                  _TextLink(
                    cupertino: cupertino,
                    onTap: onLater,
                    text: messages.message(UpgraderMessage.buttonTitleLater) ??
                        'Later',
                    textStyle: cupertinoButtonTextStyle,
                  ),
                if (showLater && showIgnore) const SizedBox(width: 16),
                if (showIgnore)
                  _TextLink(
                    cupertino: cupertino,
                    onTap: onIgnore,
                    text: messages.message(UpgraderMessage.buttonTitleIgnore) ??
                        'Ignore',
                    textStyle: cupertinoButtonTextStyle,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes(
      {required this.releaseNotes,
      required this.cupertino,
      required this.title});
  final String releaseNotes;
  final bool cupertino;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(releaseNotes, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink(
      {required this.cupertino,
      required this.onTap,
      required this.text,
      this.textStyle});
  final bool cupertino;
  final VoidCallback onTap;
  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return cupertino
        ? CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: onTap,
            child: Text(text, style: textStyle))
        : TextButton(onPressed: onTap, child: Text(text));
  }
}
