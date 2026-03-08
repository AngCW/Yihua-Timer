---
description: how to add a new column or table to tables.drift and migrate the SQLite database
---

# Schema Change Workflow

Follow these steps every time you modify `lib/database/tables.drift`.

## Steps

### 1. Edit tables.drift

Make your changes to `lib/database/tables.drift` — add columns, new tables, etc.

### 2. Bump schemaVersion

In `lib/database/app_database.dart`, increment `schemaVersion` by 1:

```dart
@override
int get schemaVersion => 8;  // was 7, now 8
```

### 3. Add migration steps

In the `onUpgrade` block, add a new `if (from < N)` block right before the comment marker:

```dart
if (from < 8) {
  await m.addColumn(myTable, myTable.myNewColumn);
  // or: await m.createTable(myNewTable);
}
// ── add new `if (from < N)` blocks above this line ───────────────
```

Migrator helper methods:
- `m.addColumn(table, table.column)` — add a single column
- `m.createTable(table)` — create a new table
- `m.deleteTable('old_name')` — drop a table

### 4. Regenerate Dart code

// turbo
Run the build_runner to regenerate `app_database.g.dart`:

```
flutter pub run build_runner build --delete-conflicting-outputs
```

This compiles both the Drift query DSL and the companion classes from the updated schema.

### 5. Run in debug mode (automatic repair)

In **debug** mode the app calls `_validateOrRepairSchema()` on every open.
This automatically:
- Creates any missing tables (using `IF NOT EXISTS`)
- Adds any missing columns (using `ALTER TABLE … ADD COLUMN`)

This lets you iterate without bumping the version during active development.

### 6. Test in release mode

```
flutter build windows
```

The release build only uses the explicit `onUpgrade` steps.
If the migration is missing, the app will stay on the old schema.

---

> [!IMPORTANT]
> Always add explicit `onUpgrade` steps before shipping a release build.
> The debug auto-repair is a development convenience only.
