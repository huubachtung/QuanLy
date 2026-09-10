# Flutter Animation Patterns

This guide outlines performance-optimized animation practices adhering to 60fps targets, 150–200ms micro-interactions, and avoiding rebuild overhead.

---

## 1. Timing and Curves Guidelines

| Animation Type | Duration | Recommended Curve | Purpose |
|----------------|----------|-------------------|---------|
| Micro-interaction (Tap/Press) | 150ms | `Curves.easeOutQuad` | Instant, tactile feedback |
| Sheet / Modal reveal | 200–250ms | `Curves.fastOutSlowIn` | Smooth structural entry |
| Fade Transition | 150–200ms | `Curves.easeIn` / `Curves.easeOut` | Content state change |
| Loading / Progress Loop | 1000–1500ms | `Curves.linear` | Background indication |

*Avoid slow, bouncy, or spring animations on essential navigation or action flows.*

---

## 2. High-Performance AnimatedBuilder Pattern

Always pass static widget trees via the `child` argument to avoid rebuilding heavy widgets on every animation tick (60 times per second):

```dart
class RotatingSyncIcon extends StatefulWidget {
  final bool isSyncing;

  const RotatingSyncIcon({required this.isSyncing, super.key});

  @override
  State<RotatingSyncIcon> createState() => _RotatingSyncIconState();
}

class _RotatingSyncIconState extends State<RotatingSyncIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isSyncing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RotatingSyncIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing != oldWidget.isSyncing) {
      if (widget.isSyncing) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      // Stable child: Icon is NOT reconstructed each frame!
      child: const Icon(
        Icons.sync_outlined,
        size: 20,
      ),
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.141592653589793,
          child: child,
        );
      },
    );
  }
}
```

---

## 3. Scale on Press (Tactile Micro-Interaction)

> **Why `AnimationController` instead of `setState`?**
> `setState(() => _isPressed = true)` triggers a full `build()` call on the parent widget tree.
> Using an `AnimationController` drives only `AnimatedBuilder`, which surgically rebuilds only the `Transform.scale` subtree — zero extra build cost on the parent.

```dart
class ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ScaleOnPress({
    required this.child,
    this.onTap,
    super.key,
  });

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        // Stable child prevents rebuilding widget.child on each animation tick.
        child: widget.child,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
      ),
    );
  }
}
```

---

## 4. RepaintBoundary for Heavy Animations

When animating elements in a complex or scrolled screen, wrap the animated portion in `RepaintBoundary` to isolate repaint operations:

```dart
RepaintBoundary(
  child: AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      return Opacity(
        opacity: _animation.value,
        child: child,
      );
    },
    child: const ComplexDataView(),
  ),
)
```
