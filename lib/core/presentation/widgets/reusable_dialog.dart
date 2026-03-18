import 'package:flutter/material.dart';

class ReusableDialog<T> extends StatefulWidget {
  final String title;
  final T initialValue;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;
  final Color? cancelColor;

  final Widget Function(
    BuildContext context,
    T value,
    void Function(T newValue) onChanged,
  )
  builder;

  final Future<bool> Function(T value)? onConfirm;

  const ReusableDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.builder,
    this.onConfirm,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.cancelColor,
  });

  @override
  State<ReusableDialog<T>> createState() => _ReusableDialogState<T>();
}

class _ReusableDialogState<T> extends State<ReusableDialog<T>> {
  late T _value;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _updateValue(T newValue) {
    setState(() {
      _value = newValue;
    });
  }

  Future<void> _handleConfirm() async {
    if (widget.onConfirm == null) {
      Navigator.pop(context, _value);
      return;
    }

    setState(() => _isLoading = true);

    final shouldClose = await widget.onConfirm!(_value);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (shouldClose) {
      Navigator.pop(context, _value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    double dialogWidth;
    if (screenWidth < 600) {
      dialogWidth = screenWidth * 0.9;
    } else if (screenWidth < 1024) {
      dialogWidth = screenWidth * 0.6;
    } else {
      dialogWidth = screenWidth * 0.4;
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: screenHeight * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),

              Flexible(
                child: SingleChildScrollView(
                  child: widget.builder(context, _value, _updateValue),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      widget.cancelText ?? 'Cancel',
                      style: TextStyle(
                        color: widget.cancelColor ?? theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _handleConfirm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.confirmText ?? 'Confirm',
                            style: TextStyle(
                              color:
                                  widget.confirmColor ??
                                  theme.colorScheme.primary,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
