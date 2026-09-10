# Flutter Performance & Accessibility Optimization

This guide covers 60fps rendering, memory efficiency, and accessibility standards for Flutter mobile applications.

---

## 1. Widget Rebuild Optimization

### Rule 1: Use `const` Constructors Everywhere Possible
Using `const` allows Flutter to short-circuit rebuild passes, as `const` instances are compiled once into the canonical memory table.

```dart
// ✅ Always mark immutable widgets const
const SizedBox(height: 16);
const Icon(Icons.arrow_forward_ios_outlined, size: 14);
```

### Rule 2: Selective Rebuild with `BlocSelector`
Avoid rebuilding entire screens when only one property changes.

```dart
// Rebuilds ONLY when unreadCount changes:
BlocSelector<NotificationBloc, NotificationState, int>(
  selector: (state) => state.unreadCount,
  builder: (context, count) {
    return Badge.count(count: count);
  },
)
```

---

## 2. Scrollable View Discipline

### Never Use Unbounded `SingleChildScrollView` + `ListView`
```dart
// ❌ CRITICAL BUG: Causes RenderBox was not laid out / unbounded height exception
SingleChildScrollView(
  child: Column(
    children: [
      Header(),
      ListView(shrinkWrap: true, ...), // Very expensive layout pass
    ],
  ),
)

// ✅ Clean Pattern: CustomScrollView + Slivers
CustomScrollView(
  slivers: [
    const SliverToBoxAdapter(child: HeaderWidget()),
    SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => ItemTile(item: items[index]),
    ),
  ],
)
```

---

## 3. DevTools Profiling & Repaint Boundaries

- Set `debugProfileBuildsEnabled = true` in `main()` (debug mode only) to surface slow build frames in Flutter DevTools.
- Enable **Performance Overlay** via `MaterialApp(showPerformanceOverlay: true)` to quickly spot janky frames.
- Wrap animated subtrees in `RepaintBoundary` to keep rasterizer costs local to that widget:

```dart
// ✅ Isolate expensive animated region from the rest of the screen
RepaintBoundary(
  child: AnimatedBuilder(
    animation: _shimmerController,
    builder: (context, child) {
      return ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.grey.shade300, Colors.white, Colors.grey.shade300],
          stops: const [0.0, 0.5, 1.0],
          begin: const Alignment(-1.0, 0),
          end: Alignment(
            _shimmerController.value * 3 - 1,
            0,
          ),
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: child,
      );
    },
    child: const ShimmerPlaceholderCard(),
  ),
)
```

> ⚠️ **When NOT to add RepaintBoundary**: Simple fade/scale/translate transforms that operate via the compositing layer (Transform widget, Opacity widget) already avoid main-thread repaint. Only add `RepaintBoundary` when the widget tree inside actually issues `paint()` calls (e.g., custom painters, ShaderMask, ClipPath, BackdropFilter).

---

## 4. Accessibility Checklist (Mandatory)

1. **Semantic Labels**: Every interactive icon or action button must have a meaningful label:
   ```dart
   Semantics(
     label: 'Quay lại màn hình trước',
     button: true,
     child: IconButton(
       icon: const Icon(Icons.arrow_back_outlined),
       onPressed: () => Navigator.of(context).pop(),
     ),
   )
   ```
2. **Accessible Touch Targets**: Every button or clickable item must measure at least `48x48dp` of hit area.
3. **Contrast Ratio**: Ensure a contrast ratio of at least 4.5:1 for standard body text against background colors.
4. **Font Scaling**: Test layouts with font scale 1.3x. Dynamic text must truncate gracefully with `ellipsis` rather than throwing `RenderFlex` overflow errors.
