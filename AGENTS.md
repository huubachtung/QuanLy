# AGENT.md — Flutter Clean Architecture + BLoC Engineering Rules

> **Purpose:** This file is the project-level engineering contract for Flutter work.
> Follow these rules whenever creating, modifying, refactoring, reviewing, or deleting code.

---

## 0. Non-Negotiable Development Protocol

### Before changing code

Always provide these two sections first:

#### 1. Root Cause & Context Analysis

Explain:

- **Current Behavior** — what the existing code/layout does or what is missing.
- **Root Cause** — why the current behavior or structure is insufficient.
- **Scope** — which layers/files are affected and which are intentionally left unchanged.

Use plain engineering language. Avoid vague statements such as "this is cleaner" without explaining the concrete reason.

#### 2. Implementation Plan & Checklist

Use a trackable checklist:

```text
- [ ] Analyze existing architecture
- [ ] Define/confirm domain contract
- [ ] Update data implementation
- [ ] Update BLoC/Cubit state flow
- [ ] Update presentation widgets
- [ ] Handle loading/empty/error/success states
- [ ] Add/update tests
- [ ] Run formatting, analyzer, and tests
- [ ] Review diff for regressions
```

For every major design choice, state **Why**:

- Why this layer owns the responsibility.
- Why BLoC/Cubit is appropriate.
- Why a widget/component is extracted.
- Why a particular data structure or dependency is used.
- What edge case or performance issue the decision prevents.

### After changing code

Finish with:

- Files changed and why.
- Integration notes.
- Verification performed.
- Remaining risks or follow-up items.

Never silently change architecture or introduce a new dependency without explaining the impact.

---

# 1. Core Architecture

Use **Clean Architecture** with a clear dependency direction:

```text
Presentation
    ↓
Domain
    ↑
Data

Dependency rule:
Outer layers may depend on inner layers.
Inner layers must not depend on outer layers.
```

Recommended feature structure:

```text
lib/
└── features/
    └── <feature_name>/
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        │
        ├── domain/
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        │
        └── presentation/
            ├── bloc/
            ├── pages/
            └── widgets/
```

### Layer responsibilities

#### Domain

The domain layer contains business rules and contracts.

It may contain:

- Entities.
- Repository interfaces.
- Use cases.
- Value objects when needed.
- Business-specific failures/errors.

It must **not** depend on:

- Flutter UI widgets.
- `BuildContext`.
- API clients.
- JSON serialization.
- Database implementations.
- BLoC.
- HTTP/storage framework details.

Domain code should remain testable without Flutter.

#### Data

The data layer implements domain contracts.

It may contain:

- Remote data sources.
- Local data sources.
- DTO/model classes.
- Repository implementations.
- Mappers.
- Serialization code.

Rules:

- API/database details stay here.
- Convert external models into domain entities before returning domain data.
- Do not leak `Dio`, `http`, Firebase, SQLite, JSON maps, or generated API types into the domain layer.

#### Presentation

The presentation layer contains:

- BLoC/Cubit.
- Pages/screens.
- Reusable widgets.
- UI state rendering.
- Navigation/UI-only concerns.

Rules:

- Widgets render state.
- Widgets should not contain business logic.
- BLoC/Cubit coordinates presentation state and use cases.
- Do not call repositories directly from widgets.

---

# 2. Dependency Direction

The dependency flow must remain explicit:

```text
Widget
  ↓
BLoC/Cubit
  ↓
UseCase
  ↓
Repository interface
  ↑
Repository implementation
  ↓
DataSource / API / Database
```

### Forbidden shortcuts

```text
Widget → API client          ❌
Widget → Repository          ❌
Widget → Database            ❌
BLoC → Dio/http directly     ❌
Domain → Flutter             ❌
Domain → Data implementation ❌
```

If a shortcut seems necessary, stop and explain the architectural reason before implementing it.

---

# 3. BLoC / Cubit Rules

## 3.1 Choosing BLoC vs Cubit

Use **Cubit** when the state transition is simple and event semantics add no meaningful value.

Use **BLoC** when:

- There are multiple user/system events.
- Event sequencing matters.
- Different events can trigger the same use case.
- Debouncing/throttling is required.
- Event transformers provide meaningful behavior.

Prefer the simplest tool that expresses the feature clearly.

---

## 3.2 BLoC/Cubit responsibilities

BLoC/Cubit should:

- Receive UI intents/events.
- Call domain use cases.
- Convert use-case results into presentation state.
- Coordinate loading/success/empty/error states.
- Prevent duplicate or invalid UI actions when appropriate.

BLoC/Cubit should **not**:

- Parse widgets.
- Build UI.
- Access `BuildContext` for business logic.
- Contain HTTP/SQL/Firebase code.
- Know concrete API response formats.
- Perform reusable business calculations that belong in domain.

---

## 3.3 State design

Prefer explicit, predictable states.

Example conceptual state:

```dart
enum ViewStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}
```

Use immutable state objects:

```dart
class FeatureState {
  final ViewStatus status;
  final List<Item> items;
  final String? errorMessage;

  const FeatureState({
    required this.status,
    this.items = const [],
    this.errorMessage,
  });

  FeatureState copyWith({
    ViewStatus? status,
    List<Item>? items,
    String? errorMessage,
  }) {
    return FeatureState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
```

### State rules

- State must be immutable.
- Prefer one predictable state model over many partially overlapping booleans.
- Avoid impossible combinations such as `isLoading == true` and `hasError == true` unless the UX explicitly requires concurrent states.
- Keep transient UI-only state in presentation unless it is business-significant.
- Never mutate a list/map inside an emitted state.
- Prefer new instances over in-place mutation.

---

# 4. Use Case Rules

A use case should represent **one meaningful business action**.

Good examples:

```text
GetProfile
UpdateProfile
SubmitOrder
FetchProducts
DeleteAddress
```

Avoid generic classes that mix unrelated behavior:

```text
UserManager
CommonService
AppHelper
DataManager
```

### Use case principles

- One reason to change.
- Small public API.
- Business-oriented naming.
- Independent from Flutter.
- Easy to unit test.
- Calls repository interfaces, never concrete implementations.

A use case should answer:

> "What business action is the application performing?"

Not:

> "Which API endpoint are we calling?"

---

# 5. Repository Rules

## Domain repository

Define interfaces in the domain layer:

```dart
abstract interface class UserRepository {
  Future<User> getUser();
  Future<void> updateUser(User user);
}
```

## Data repository

Implement the interface in the data layer:

```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  const UserRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<User> getUser() {
    return remoteDataSource.getUser();
  }

  @override
  Future<void> updateUser(User user) {
    return remoteDataSource.updateUser(user);
  }
}
```

### Rules

- Domain owns the contract.
- Data owns the implementation.
- Repository methods return domain entities/results to callers in domain/presentation.
- Repository implementations translate infrastructure failures into application-level failures when appropriate.

---

# 6. Data Source Rules

Separate data access from repository orchestration.

Recommended:

```text
Repository
   ↓
RemoteDataSource
   ↓
API client
```

or:

```text
Repository
   ↓
LocalDataSource
   ↓
Database / Cache
```

Data sources should focus on obtaining/storing data.

They should not:

- Manage screen state.
- Emit BLoC states.
- Build widgets.
- Contain business decisions belonging to domain.

---

# 7. Model / Entity Separation

Do not use API/DB models as domain entities by default.

Recommended separation:

```text
API JSON
   ↓
RemoteModel
   ↓ mapper
DomainEntity
   ↓
Presentation
```

Example:

```dart
class UserModel {
  final String id;
  final String displayName;

  const UserModel({
    required this.id,
    required this.displayName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
    );
  }

  User toEntity() {
    return User(
      id: id,
      displayName: displayName,
    );
  }
}
```

### Why

This prevents external API structure from becoming an accidental business contract.

If an API changes:

```text
API change → Data model/mapper changes
           → Domain contract remains stable
           → UI impact is minimized
```

---

# 8. Error Handling

Use an explicit error strategy.

Recommended conceptual flow:

```text
Datasource exception
        ↓
Repository translates
        ↓
Failure / Result
        ↓
UseCase
        ↓
BLoC/Cubit
        ↓
UI error state
```

Do not:

```dart
catch (_) {}
```

Never swallow an error silently.

Avoid exposing raw infrastructure exceptions directly to the UI.

Examples of application-level failures:

```text
NetworkFailure
UnauthorizedFailure
ValidationFailure
NotFoundFailure
ServerFailure
CacheFailure
UnknownFailure
```

Error messages shown to users should be appropriate for users; technical diagnostics belong in logs/debug tooling.

---

# 9. Async / Concurrency Rules

Consider concurrency explicitly for:

- Search.
- Pagination.
- Pull-to-refresh.
- Multiple submit actions.
- Rapid filter changes.
- Authentication requests.

Use BLoC event transformers or equivalent control when appropriate.

Document the intended behavior:

```text
Search:
- Cancel stale requests when a newer query is entered.
- Debounce rapid typing.
- Keep the latest request authoritative.
```

Do not add debounce/throttle/cancellation blindly. Explain why the behavior is needed.

---

# 10. Clean Code Rules

## Naming

Names must describe intent.

Prefer:

```text
fetchOrders()
calculateTotal()
submitCheckout()
OrderRepository
CheckoutBloc
```

Avoid:

```text
doStuff()
handleData()
manager()
service1()
temp()
```

Use consistent naming across:

- Feature.
- BLoC/Cubit.
- Events.
- States.
- Use cases.
- Repositories.
- Widgets.

---

## Single Responsibility

A class should have one primary responsibility.

Avoid widgets that simultaneously:

- Fetch APIs.
- Parse JSON.
- Manage complex business rules.
- Handle navigation.
- Render 300+ lines of UI.

Extract responsibilities into:

```text
Widget
BLoC/Cubit
UseCase
Repository
DataSource
```

---

## Small methods

Prefer small methods with one clear purpose.

Avoid deeply nested control flow.

If a method needs a long explanation to understand, consider extracting a named function/class.

---

## Early returns

Prefer guard clauses over deeply nested branches:

```dart
if (items.isEmpty) {
  return const EmptyState();
}

if (!isAuthorized) {
  return const UnauthorizedState();
}

return ItemList(items: items);
```

---

## Constants

Use named constants for repeated design values and business values.

Avoid magic numbers:

```dart
// ❌
padding: EdgeInsets.all(17)
```

Prefer shared tokens:

```dart
padding: const EdgeInsets.all(AppSpacing.md)
```

---

# 11. Comments — Write Comments That Help Teammates

Comments are required when they preserve **intent**, not when they restate obvious syntax.

## Good comments

Explain:

- Why a decision exists.
- What constraint is being protected.
- Why an unusual workaround is required.
- Why a concurrency strategy is necessary.
- Why an API/model mapping is intentionally different.
- Why a performance optimization exists.

Example:

```dart
// Cancel stale search requests so an older response cannot overwrite
// the results for a newer query.
```

## Bad comments

Do not write:

```dart
// Increment counter.
counter++;
```

The code already explains itself.

## Keep comments current

A stale comment is worse than no comment.

Whenever code behavior changes, update or delete related comments.

---

# 12. Keep Trackability for Teammates

Every non-trivial change should make the intent easy to follow.

Use:

- Small focused commits.
- Small focused classes.
- Clear feature folders.
- Predictable state names.
- Explicit TODOs only when actionable.
- Comments for non-obvious decisions.
- Tests around critical business behavior.

### TODO format

Prefer:

```dart
// TODO(team): Replace fallback with server-driven configuration.
// Reason: backend flag is not available yet.
// Remove after API version X is adopted.
```

Avoid:

```dart
// TODO: fix later
```

---

# 13. Flutter UI/UX Rules

Follow a **mobile-first, animation-enhanced, accessible** design philosophy.

Priority:

1. Reusable widget composition.
2. Responsive design.
3. Purposeful animations.
4. Consistent themes.
5. Performance.

---

## 13.1 Surfaces

Avoid generic floating-card UI.

Rules:

- Avoid `elevation > 1`.
- Prefer flat surface layering.
- Use background/surface contrast.
- Use subtle borders where needed.
- Do not add generic gray drop shadows by default.

Corner radius:

```text
Micro components: 6–8px
Inputs/buttons:    10–12px
Cards/sheets:      16px
```

---

## 13.2 Spacing

Use a strict 4/8-based spacing system:

```text
4, 8, 12, 16, 24, 32, 48
```

Avoid arbitrary spacing such as:

```text
10, 14, 18, 22
```

Screen edge padding should normally be:

```text
16px or 20px
```

Prefer shared tokens:

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
```

---

# 14. Typography

Use a compact mobile type scale.

```text
Large title / hero:      20–22px / w700 / line height 1.2
Section heading:         15–16px / w600 / line height 1.3
List title:              14px    / w500–600 / line height 1.35
Body:                    13–14px / w400 / line height 1.45
Secondary:               12–13px / w400 / 60% opacity
Micro labels:            10–11px / w500 / letter spacing 0.2px
```

For dynamic text:

- Set `maxLines` where appropriate.
- Use `TextOverflow.ellipsis`.
- Do not use `FittedBox` for short titles as a workaround for bad layout sizing.

Establish hierarchy using weight and opacity, not oversized text.

---

# 15. Iconography

Avoid generic filled Material icons.

Prefer:

- `lucide_icons`.
- `phosphor_flutter`.
- Material `_outlined` or `_rounded` variants when Material icons are required.

Maintain a consistent visual weight:

```text
Recommended stroke weight: 1.5px or 2px
```

Sizing:

```text
Micro icon: 16px
Standard icon: 20–24px
Minimum tap target: 48×48px
```

States:

```text
Idle:
  outlined/stroke + secondary color

Active:
  accent color or filled active variant
```

Avoid random colorful icon badges.

Use accent color selectively for primary actions.

---

# 16. Interaction and Animation

Animations must communicate state or hierarchy.

Micro-interactions:

```text
150–200ms
```

Prefer:

```text
Curves.easeOutQuad
Curves.fastOutSlowIn
```

Avoid:

- Excessive bounce.
- Slow feedback.
- Animating expensive layouts unnecessarily.
- Animation that blocks user action.

Use optimized animation patterns such as `AnimatedBuilder` with a stable child when appropriate.

---

# 17. Responsive Layout

Use:

- `LayoutBuilder`.
- `MediaQuery`.
- `Flexible`.
- `Expanded`.
- `AspectRatio`.

Choose layouts intentionally.

Examples:

```text
Column:
  Small, bounded vertical content.

ListView.builder:
  Long dynamic lists.

CustomScrollView + SliverList:
  Multiple coordinated scrollable sections.

LayoutBuilder:
  Component behavior depends on available width.
```

Avoid nested unbounded scroll views.

Explicitly consider:

- Small phones.
- Large phones.
- Tablets.
- Portrait/landscape.
- Keyboard-open state.
- Font scaling.

---

# 18. Reusable Widgets

Prefer small composable widgets:

```text
presentation/
└── widgets/
    ├── feature_header.dart
    ├── feature_item.dart
    ├── feature_empty_state.dart
    └── feature_error_state.dart
```

Prefer reusable widgets over giant build methods.

Use `const` constructors wherever possible.

A widget should expose a small, clear API.

Example:

```dart
class FeatureCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const FeatureCard({
    required this.title,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(title),
      ),
    );
  }
}
```

---

# 19. UI State Rendering

Every async screen should intentionally handle, where relevant:

```text
Initial
Loading
Success
Empty
Failure
Refreshing
Submitting
```

Do not assume success is the only state.

Example conceptual rendering:

```dart
switch (state.status) {
  case ViewStatus.initial:
    return const SizedBox.shrink();

  case ViewStatus.loading:
    return const LoadingView();

  case ViewStatus.success:
    return ItemList(items: state.items);

  case ViewStatus.empty:
    return const EmptyState();

  case ViewStatus.failure:
    return ErrorState(message: state.errorMessage);
}
```

The UI should remain deterministic for each state.

---

# 20. Accessibility — Required

Always consider:

- Screen reader labels.
- Semantic controls.
- Sufficient contrast.
- Dynamic font scaling.
- Keyboard/assistive interaction.
- Touch target sizing.

Examples:

```dart
Semantics(
  label: 'Add item to cart',
  button: true,
  child: IconButton(
    onPressed: onAdd,
    icon: const Icon(Icons.add_outlined),
  ),
)
```

Do not rely only on color to communicate state.

Avoid hardcoded text colors that become unreadable in dark mode.

---

# 21. Performance

Rules:

- Use `const` wherever possible.
- Prefer `ListView.builder` for long lists.
- Avoid unnecessary rebuilds.
- Keep expensive work outside `build()`.
- Use `BlocSelector`/selective rebuilds where beneficial.
- Use `RepaintBoundary` for appropriate complex animated regions.
- Profile with Flutter DevTools for meaningful performance issues.
- Avoid premature optimization without evidence.

For large lists, prefer stable item identity and efficient widget composition.

---

# 22. Testing Rules

At minimum, test important behavior at the appropriate layer.

## Domain tests

Test:

- Use case behavior.
- Business rules.
- Edge cases.
- Failure mapping where applicable.

## Data tests

Test:

- Model parsing.
- Serialization.
- Repository mapping.
- Data source behavior.

## BLoC/Cubit tests

Test:

```text
Event/input
   ↓
State sequence
```

Verify:

- Loading is emitted when expected.
- Success contains correct data.
- Empty is handled correctly.
- Failure is emitted with correct failure semantics.
- Duplicate actions are handled as intended.

## Widget tests

Test:

- State rendering.
- User interaction.
- Accessibility semantics where important.
- Overflow-sensitive layouts.

---

# 23. Verification Checklist

Before considering a feature complete:

```text
- [ ] Formatting passes
- [ ] `flutter analyze` passes
- [ ] Relevant unit tests pass
- [ ] Relevant BLoC/Cubit tests pass
- [ ] Relevant widget tests pass
- [ ] No unexpected debug logs remain
- [ ] No ignored/swallowed exceptions
- [ ] No hardcoded secrets
- [ ] No API/data-source calls from widgets
- [ ] No business logic in widgets
- [ ] Dependency direction is clean
- [ ] Loading/empty/error states are handled
- [ ] Dynamic text cannot create obvious overflow
- [ ] Small-screen layout checked
- [ ] Font scaling checked
- [ ] Light/Dark theme checked
- [ ] Keyboard interaction checked where relevant
- [ ] Accessibility labels/tap targets reviewed
- [ ] Diff reviewed for unrelated changes
```

---

# 24. Mandatory Self-Verification Guide

For every non-trivial UI feature, verify:

### Integration

Document:

- Exact file placement.
- Required imports.
- Required `pubspec.yaml` dependencies.
- DI/registration changes.
- Route/navigation changes.

### Defensive UI

Check:

```text
[ ] 360dp/small phone: no RenderFlex overflow
[ ] Font size around 1.3x: layout remains usable
[ ] Light theme: text/icons remain readable
[ ] Dark theme: no hardcoded-color visibility issues
[ ] Keyboard: inputs remain reachable
[ ] Loading: no duplicate submission
[ ] Empty: clear empty state
[ ] Error: recoverable error path
[ ] Long text: truncates/wraps intentionally
[ ] Slow network: UI remains deterministic
```

---

# 25. Development Workflow

Execute phases sequentially.

## Phase 1 — Analyze Requirements

- Inspect existing feature structure.
- Check current architecture.
- Review design tokens/theme.
- Identify platform constraints.
- Identify performance constraints.
- Identify existing BLoC/Cubit conventions.
- Identify existing error/state conventions.

**Output:** requirements analysis + affected component/layer map.

---

## Phase 2 — Define Domain Contract

Before implementation:

- Identify the business action.
- Define/confirm entities.
- Define repository interfaces.
- Define use cases.
- Define failure/result semantics.

**Output:** domain contract that is independent from Flutter/data implementations.

---

## Phase 3 — Implement Data

- Add/update models.
- Add/update mappers.
- Implement data sources.
- Implement repository interfaces.
- Handle infrastructure failures.

**Output:** stable data implementation behind domain contracts.

---

## Phase 4 — Implement BLoC/Cubit

- Define immutable state.
- Define events when using BLoC.
- Inject use cases.
- Implement async state transitions.
- Handle concurrency.
- Avoid leaking infrastructure details.

**Output:** deterministic presentation state flow.

---

## Phase 5 — Implement UI

- Build small reusable widgets.
- Assemble the screen.
- Connect `BlocBuilder`, `BlocListener`, `BlocSelector`, or appropriate equivalents.
- Handle loading/success/empty/error.
- Apply responsive and accessibility rules.

**Output:** UI that renders from state rather than owning business logic.

---

## Phase 6 — Verify and Refactor

- Format.
- Analyze.
- Run tests.
- Profile when relevant.
- Review architecture boundaries.
- Remove duplication.
- Update comments.
- Review the final diff.

**Output:** complete, reviewable change.

---

# 26. Example Feature Flow

```text
User taps "Load Orders"
        ↓
Page / Widget
        ↓
OrdersBloc.add(OrdersRequested())
        ↓
OrdersBloc
        ↓
GetOrders use case
        ↓
OrderRepository interface
        ↓
OrderRepositoryImpl
        ↓
OrderRemoteDataSource
        ↓
API
        ↓
DTO / Model
        ↓
Mapper
        ↓
Domain Entity
        ↓
UseCase result
        ↓
OrdersBloc emits Loading / Success / Empty / Failure
        ↓
Widget rebuilds from state
```

This flow should remain understandable to a new teammate without reading implementation details first.

---

# 27. Anti-Patterns

Do not introduce these without a documented architectural exception:

```text
❌ God widgets
❌ God BLoCs
❌ Business rules inside build()
❌ API calls inside widgets
❌ Repository calls directly from widgets
❌ Domain importing Flutter
❌ Data models used as domain contracts everywhere
❌ Mutable shared state
❌ Boolean state explosions
❌ Swallowed exceptions
❌ Magic numbers
❌ Generic "Manager"/"Helper" classes with mixed responsibilities
❌ Giant utility files
❌ Comments that restate the code
❌ Dead TODOs
❌ Unnecessary abstractions
❌ Unnecessary dependencies
❌ Premature optimization
```

---

# 28. Practical Code Quality Standard

Before submitting code, ask:

```text
1. Can a teammate understand the responsibility of each class by its name?
2. Can a teammate trace UI → BLoC → UseCase → Repository quickly?
3. Is business logic independent from Flutter and infrastructure?
4. Can the state model represent every real UI state?
5. Are errors explicit and testable?
6. Are comments explaining intent instead of syntax?
7. Can this code be unit/widget tested without fragile setup?
8. Is there any unrelated change in the diff?
9. Does the UI remain safe on small screens and larger text?
10. Would removing an abstraction make the code clearer?
```

When the answer is unclear, simplify or document the decision.

---

# 29. Final Rule

> **Optimize for maintainability, traceability, correctness, and teammate comprehension before cleverness.**

The codebase should make the following story obvious:

```text
What does the feature do?
        ↓
Which use case represents that behavior?
        ↓
Which repository contract does it need?
        ↓
Where does the data come from?
        ↓
How does BLoC/Cubit represent the result?
        ↓
How does the UI render each state?
```

Every implementation should preserve that trace.
