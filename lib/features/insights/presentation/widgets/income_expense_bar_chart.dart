import 'package:flutter/material.dart';

import '../../domain/entities/insight_report.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  const IncomeExpenseBarChart({
    super.key,
    required this.bars,
    this.height = 220,
  });

  final List<MonthlyBar> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: Colors.green.shade400, label: 'Income'),
            const SizedBox(width: 16),
            _LegendDot(color: colorScheme.error, label: 'Expenses'),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _BarChartPainter(
              bars: bars,
              incomeColor: Colors.green.shade400,
              expenseColor: colorScheme.error,
              gridColor: colorScheme.outlineVariant.withAlpha(77),
              labelStyle: theme.textTheme.labelSmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.bars,
    required this.incomeColor,
    required this.expenseColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<MonthlyBar> bars;
  final Color incomeColor;
  final Color expenseColor;
  final Color gridColor;
  final TextStyle labelStyle;

  static const _labelAreaHeight = 28.0;
  static const _yAxisWidth = 48.0;
  static const _barGap = 3.0;
  static const _groupGap = 10.0;
  static const _gridLines = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - _labelAreaHeight;
    final chartW = size.width - _yAxisWidth;

    final maxVal = bars.fold(
      0.0,
      (m, b) => [m, b.income, b.expenses].reduce((a, b) => a > b ? a : b),
    );
    if (maxVal == 0) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final valuePaint = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= _gridLines; i++) {
      final y = chartH - (chartH * i / _gridLines);
      canvas.drawLine(Offset(_yAxisWidth, y), Offset(size.width, y), gridPaint);

      final val = (maxVal * i / _gridLines);
      valuePaint.text = TextSpan(text: _formatAmount(val), style: labelStyle);
      valuePaint.layout();
      valuePaint.paint(
        canvas,
        Offset(_yAxisWidth - valuePaint.width - 4, y - valuePaint.height / 2),
      );
    }

    final groupW = (chartW - _groupGap * (bars.length - 1)) / bars.length;
    final barW = (groupW - _barGap) / 2;

    final incomePaint = Paint()..color = incomeColor;
    final expensePaint = Paint()..color = expenseColor;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final groupX = _yAxisWidth + i * (groupW + _groupGap);

      final incomeH = (bar.income / maxVal) * chartH;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(groupX, chartH - incomeH, barW, incomeH),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        incomePaint,
      );

      final expenseH = (bar.expenses / maxVal) * chartH;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            groupX + barW + _barGap,
            chartH - expenseH,
            barW,
            expenseH,
          ),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        expensePaint,
      );

      labelPainter.text = TextSpan(text: bar.shortLabel, style: labelStyle);
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(groupX + groupW / 2 - labelPainter.width / 2, chartH + 6),
      );
    }
  }

  String _formatAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.bars != bars ||
      old.incomeColor != incomeColor ||
      old.expenseColor != expenseColor;
}
