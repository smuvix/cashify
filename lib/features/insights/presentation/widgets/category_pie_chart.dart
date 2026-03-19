import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/pie_chart_pallete.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/insight_report.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  const CategoryPieChart({
    super.key,
    required this.slices,
    required this.totalExpenses,
    this.size = 200,
  });

  final List<CategorySlice> slices;
  final double totalExpenses;
  final double size;

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CategoryPieChart old) {
    super.didUpdateWidget(old);
    if (old.slices != widget.slices) {
      _tappedIndex = null;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slices.isEmpty) {
      return Center(
        child: Text(
          'No expense data for this period.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final categoriesAsync = ref.watch(categoryProvider);
    final fmt = ref.watch(cashifyFormatterProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) {
        final catMap = {for (final c in categories) c.id: c};

        final colors = List.generate(widget.slices.length, (i) {
          final cat = catMap[widget.slices[i].categoryId];
          return cat?.color ?? palette[i % palette.length];
        });

        return Column(
          children: [
            GestureDetector(
              onTapUp: (details) => _handleTap(details, colors),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (_, _) => SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _PiePainter(
                      slices: widget.slices,
                      colors: colors,
                      progress: _animation.value,
                      tappedIndex: _tappedIndex,
                    ),
                  ),
                ),
              ),
            ),

            if (_tappedIndex != null) ...[
              const SizedBox(height: 8),
              _TappedSliceLabel(
                slice: widget.slices[_tappedIndex!],
                color: colors[_tappedIndex!],
                catName:
                    catMap[widget.slices[_tappedIndex!].categoryId]?.name ??
                    'Category deleted',
                formattedAmount: fmt.amountWithSymbol(
                  widget.slices[_tappedIndex!].amount,
                ),
              ),
            ],

            const SizedBox(height: 20),

            ...List.generate(widget.slices.length, (i) {
              final slice = widget.slices[i];
              final cat = catMap[slice.categoryId];
              final isHighlighted = _tappedIndex == null || _tappedIndex == i;
              return Opacity(
                opacity: isHighlighted ? 1.0 : 0.4,
                child: _LegendRow(
                  color: colors[i],
                  label: cat?.name ?? 'Category deleted',
                  formattedAmount: fmt.amountWithSymbol(slice.amount),
                  percentage: slice.percentage,
                  icon: cat?.icon,
                  onTap: () => setState(
                    () => _tappedIndex = _tappedIndex == i ? null : i,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _handleTap(TapUpDetails details, List<Color> colors) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final tap = details.localPosition;
    final dx = tap.dx - center.dx;
    final dy = tap.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final radius = widget.size / 2;

    if (dist > radius || dist < radius * 0.3) {
      setState(() => _tappedIndex = null);
      return;
    }

    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    double start = 0;
    for (int i = 0; i < widget.slices.length; i++) {
      final sweep = widget.slices[i].percentage * 2 * math.pi;
      if (angle >= start && angle < start + sweep) {
        setState(() => _tappedIndex = _tappedIndex == i ? null : i);
        return;
      }
      start += sweep;
    }
    setState(() => _tappedIndex = null);
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter({
    required this.slices,
    required this.colors,
    required this.progress,
    required this.tappedIndex,
  });

  final List<CategorySlice> slices;
  final List<Color> colors;
  final double progress;
  final int? tappedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.42;
    const explodeOffset = 8.0;

    if (slices.length == 1) {
      final drawCenter = tappedIndex == 0
          ? Offset(center.dx + explodeOffset, center.dy)
          : center;
      final path = Path()
        ..addOval(
          Rect.fromCircle(center: drawCenter, radius: radius * progress),
        )
        ..addOval(Rect.fromCircle(center: drawCenter, radius: innerRadius));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[0]
          ..style = PaintingStyle.fill,
      );
      return;
    }

    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final sweepAngle = slices[i].percentage * 2 * math.pi * progress;
      final isExploded = tappedIndex == i;

      Offset drawCenter = center;
      if (isExploded) {
        final midAngle = startAngle + sweepAngle / 2;
        drawCenter = Offset(
          center.dx + explodeOffset * math.cos(midAngle),
          center.dy + explodeOffset * math.sin(midAngle),
        );
      }

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(
          drawCenter.dx + innerRadius * math.cos(startAngle),
          drawCenter.dy + innerRadius * math.sin(startAngle),
        );

      path.arcTo(
        Rect.fromCircle(center: drawCenter, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.arcTo(
        Rect.fromCircle(center: drawCenter, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, paint);

      final separatorPaint = Paint()
        ..color = Colors.white.withAlpha(128)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, separatorPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.slices != slices ||
      old.progress != progress ||
      old.tappedIndex != tappedIndex;
}

class _TappedSliceLabel extends StatelessWidget {
  const _TappedSliceLabel({
    required this.slice,
    required this.color,
    required this.catName,
    required this.formattedAmount,
  });

  final CategorySlice slice;
  final Color color;
  final String catName;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          catName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(formattedAmount, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 4),
        Text(
          '(${(slice.percentage * 100).toStringAsFixed(1)}%)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.formattedAmount,
    required this.percentage,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final String label;
  final String formattedAmount;
  final double percentage;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon ?? Icons.category_outlined,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formattedAmount,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              child: Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
