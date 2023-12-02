import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdaptiveContextualMenu extends StatelessWidget {
  const AdaptiveContextualMenu({
    super.key,
    required this.child,
    required this.menuChildren,
    this.focusNode,
    this.menuController,
  });

  final Widget child;
  final List<Widget> menuChildren;

  final FocusNode? focusNode;
  final MenuController? menuController;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onSecondaryTapDown: _handleSecondaryTapDown,
        child: MenuAnchor(
          consumeOutsideTap: false,
          controller: menuController,
          menuChildren: menuChildren,
          childFocusNode: focusNode,
          child: child,
        ),
      ),
    );
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    menuController?.open(position: details.localPosition);
  }

  void _handleTapDown(TapDownDetails details) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // Don't open the menu on these platforms with a Ctrl-tap (or a
        // tap).
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // Only open the menu on these platforms if the control button is down
        // when the tap occurs.
        if (HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlRight)) {
          menuController?.open(position: details.localPosition);
        }
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (node.hasFocus) {
      final isCtrl = HardwareKeyboard.instance.logicalKeysPressed
          .contains(LogicalKeyboardKey.controlLeft) || HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.controlRight);
      if (event.logicalKey == LogicalKeyboardKey.enter && isCtrl) {
        menuController?.open();
      }
    }

    return KeyEventResult.ignored;
  }
}
