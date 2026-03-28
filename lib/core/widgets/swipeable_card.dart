import 'package:flutter/material.dart';

import 'delete_dialog.dart';

class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    required this.deleteTitle,
    this.deleteItemName = '',
    this.customDeleteMessage,
    this.skipConfirmDialog = false,
    this.onAction,
    this.actionIcon,
    this.actionLabel,
    this.actionColor,
    this.actionIconColor,
  }) : assert(
         onAction == null ||
             (actionIcon != null &&
                 actionLabel != null &&
                 actionColor != null &&
                 actionIconColor != null),
         'Provide actionIcon, actionLabel, actionColor and actionIconColor '
         'when onAction is set.',
       );

  final Widget child;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;
  final String deleteTitle;
  final String deleteItemName;
  final String? customDeleteMessage;
  final bool skipConfirmDialog;

  final Future<void> Function()? onAction;
  final IconData? actionIcon;
  final String? actionLabel;
  final Color? actionColor;
  final Color? actionIconColor;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  bool get _hasAction => widget.onAction != null;

  double get _actionBarWidth => _hasAction ? 195.0 : 130.0;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-_actionBarWidth, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _isOpen = true);
    _controller.forward();
  }

  void _close() {
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  Future<void> _handleDelete() async {
    _close();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    if (!widget.skipConfirmDialog) {
      final confirmed = await showDeleteDialog(
        context,
        title: widget.deleteTitle,
        itemName: widget.deleteItemName,
        customMessage: widget.customDeleteMessage,
      );
      if (!confirmed) return;
    }

    final removed = await widget.onDelete();

    if (!mounted) return;
    if (!removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete item. Please try again.'),
        ),
      );
      _open();
    }
  }

  Future<void> _handleAction() async {
    _close();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await widget.onAction!();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _isOpen ? _close : null,
      onLongPress: !_isOpen ? _open : null,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) {
          _open();
        } else if (velocity > 300) {
          _close();
        } else {
          _controller.value > 0.4 ? _open() : _close();
        }
      },
      onHorizontalDragUpdate: (details) {
        final delta = -details.primaryDelta! / _actionBarWidth;
        _controller.value = (_controller.value + delta).clamp(0.0, 1.0);
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: 16,
            top: 5,
            bottom: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: _actionBarWidth,
                child: Row(
                  children: [
                    if (_hasAction) ...[
                      Expanded(
                        child: _ActionButton(
                          color: widget.actionColor!,
                          icon: widget.actionIcon!,
                          label: widget.actionLabel!,
                          iconColor: widget.actionIconColor!,
                          onTap: _handleAction,
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                    Expanded(
                      child: _ActionButton(
                        color: colorScheme.primaryContainer,
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        iconColor: colorScheme.onPrimaryContainer,
                        onTap: () {
                          _close();
                          Future.delayed(
                            const Duration(milliseconds: 180),
                            widget.onEdit,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _ActionButton(
                        color: colorScheme.errorContainer,
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        iconColor: colorScheme.onErrorContainer,
                        onTap: _handleDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) => Transform.translate(
              offset: _slideAnimation.value,
              child: child,
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
