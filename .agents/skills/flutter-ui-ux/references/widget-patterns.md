# Reusable Widget Patterns for Flutter

This reference guide provides production-ready Flutter widget composition patterns adhering to the project's **Clean Architecture + BLoC** standards and **Defensive UI** guidelines.

---

## 1. Stateless Composition vs Helper Methods

### ❌ Anti-Pattern: Helper Methods (`_buildItem()`)
```dart
// Bad: Helper methods do not have their own BuildContext or Element lifecycle.
// When the parent rebuilds, all helper methods are re-evaluated entirely.
Widget _buildCard(String title) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Text(title),
  );
}
```

### ✅ Clean Pattern: Extracted StatelessWidget
```dart
// Good: Has a stable identity, can be marked const, and prevents cascading rebuilds.
class ProfileCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const ProfileCard({
    required this.title,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.08),
          ),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
```

---

## 2. Flat Surface Card (Zero Generic Elevation)

```dart
class FlatSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const FlatSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.08),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
```

---

## 3. Responsive Layout Patterns

### LayoutBuilder for Adaptive Component Layouts
```dart
class AdaptiveCardContainer extends StatelessWidget {
  final Widget leading;
  final Widget details;
  final Widget action;

  const AdaptiveCardContainer({
    required this.leading,
    required this.details,
    required this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          // Compact layout for narrow screens (e.g. 320-360dp)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(child: details),
                ],
              ),
              const SizedBox(height: 12),
              action,
            ],
          );
        }

        // Standard wide row layout
        return Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(child: details),
            const SizedBox(width: 16),
            action,
          ],
        );
      },
    );
  }
}
```

---

## 4. Defensive UI: Handling Long Text & Font Scaling

Always guard dynamic text against RenderFlex overflow:
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      item.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      item.description,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    ),
  ],
)
```

---

## 5. UI State Pattern: Empty, Loading, and Error States

```dart
class StateViewWrapper extends StatelessWidget {
  final ViewStatus status;
  final Widget content;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const StateViewWrapper({
    required this.status,
    required this.content,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const Center(
          child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
        );
      case ViewStatus.empty:
        return Center(
          child: Text(
            'Không có dữ liệu',
            // Use theme-aware color: Colors.grey breaks on dark backgrounds.
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        );
      case ViewStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage ?? 'Đã có lỗi xảy ra'),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        );
      case ViewStatus.success:
        return content;
    }
  }
}
```
