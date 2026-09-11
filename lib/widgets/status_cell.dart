import 'package:flutter/material.dart';

import 'dart:math' as math;

import '../models/habit.dart';
import '../data/database_helper.dart';
import '../screens/habit_detail_screen.dart';

class StatusCell extends StatefulWidget {
  final Habit habit;
  final HabitRecord record;
  final Color color;
  final VoidCallback? onRefresh;

  const StatusCell({
    super.key,
    required this.habit,
    required this.record,
    required this.color,
    this.onRefresh,
  });

  @override
  State<StatusCell> createState() => _StatusCellState();
}

class _StatusCellState extends State<StatusCell> with TickerProviderStateMixin {
  AnimationController? _localController;

  @override
  void initState() {
    super.initState();
    _localController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  void _handleTap() async {
    double newValue;
    bool triggerFlower = false;

    if (widget.record.value == 1.0) {
      newValue = 0.0;
    } else {
      newValue = 1.0;
      triggerFlower = true;
    }

    if (triggerFlower && _localController != null) {
      _localController!.forward(from: 0.0);
      _showFullScreenFlowers(context, widget.color);
    }

    await DatabaseHelper.instance.insertRecord(
      HabitRecord(
        id: widget.record.id,
        habitId: widget.record.habitId,
        date: widget.record.date,
        value: newValue,
        isSkipped: false,
      ),
    );

    if (widget.onRefresh != null) widget.onRefresh!();
  }

  void _showFullScreenFlowers(BuildContext context, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) =>
          _FlowerShower(color: color, onComplete: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    if (_localController == null) return const SizedBox();

    return GestureDetector(
      onTap: _handleTap,
      // HOLD ON DAY -> OPEN HISTORY
      onLongPress: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitDetailScreen(habit: widget.habit),
          ),
        );
        if (widget.onRefresh != null) widget.onRefresh!();
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 38,
          height: 40,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildContent(),
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _localController!,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ParticlePainter(
                        progress: _localController!.value,
                        color: widget.color,
                      ),
                      size: const Size(40, 40),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.record.value == 1.0) {
      return Icon(Icons.check_rounded, color: widget.color, size: 28);
    } else {
      return const Icon(Icons.close_rounded, color: Colors.redAccent, size: 28);
    }
  }
}

class _FlowerShower extends StatefulWidget {
  final Color color;
  final VoidCallback onComplete;
  const _FlowerShower({required this.color, required this.onComplete});
  @override
  State<_FlowerShower> createState() => _FlowerShowerState();
}

class _FlowerShowerState extends State<_FlowerShower>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_FlowerPart> _parts = List.generate(30, (i) => _FlowerPart());
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => CustomPaint(
          painter: _FlowerPainter(
            progress: _ctrl.value,
            parts: _parts,
            color: widget.color,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _FlowerPart {
  final double angle = math.Random().nextDouble() * 2 * math.pi;
  final double speed = 0.5 + math.Random().nextDouble() * 2.0;
  final double startX = 0.3 + math.Random().nextDouble() * 0.4;
  final double startY = 0.3 + math.Random().nextDouble() * 0.4;
}

class _FlowerPainter extends CustomPainter {
  final double progress;
  final List<_FlowerPart> parts;
  final Color color;
  _FlowerPainter({
    required this.progress,
    required this.parts,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var part in parts) {
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity);
      final x =
          size.width * part.startX +
          (math.cos(part.angle) * progress * 300 * part.speed);
      final y =
          size.height * part.startY +
          (math.sin(part.angle) * progress * 300 * part.speed) +
          (progress * progress * 200);
      canvas.drawCircle(Offset(x, y), 8 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  ParticlePainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final count = 10;
    final radius = (size.width / 1.5) * (1 + progress);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    paint.color = color.withValues(alpha: opacity);
    for (var i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi) / count;
      final offset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(offset, 3.0 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
