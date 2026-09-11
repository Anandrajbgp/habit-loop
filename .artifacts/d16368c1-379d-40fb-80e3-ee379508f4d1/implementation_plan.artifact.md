# Habit Tracker Implementation Plan

Building a cross-platform habit tracker using Flutter, matching the provided UI design.

## User Review Required

> [!IMPORTANT]
> The design shows two types of habits:
> 1. **Binary Habits**: (e.g., "Wake up early") - Checked or Crossed.
> 2. **Quantitative Habits**: (e.g., "Run - 1.2 miles", "Read books - 50 pages") - Shows numeric values.
> I will implement a data model that supports both.

> [!NOTE]
> The top bar has "Habits" title with Add (+), Filter, and Menu icons. I will implement these as standard `IconButton`s in the `AppBar`.

## Proposed Changes

### Data Layer

#### [NEW] [habit_model.dart](file:///C:/Users/hp/habitloop/lib/models/habit.dart)
Defines the `Habit` and `HabitRecord` classes.

#### [NEW] [database_helper.dart](file:///C:/Users/hp/habitloop/lib/data/database_helper.dart)
Handles SQLite operations using `sqflite`.

### UI Layer

#### [NEW] [habit_list_screen.dart](file:///C:/Users/hp/habitloop/lib/screens/habit_list_screen.dart)
The main screen containing the `AppBar` and the list of habits.

#### [NEW] [habit_row.dart](file:///C:/Users/hp/habitloop/lib/widgets/habit_row.dart)
A custom widget for each habit item, including:
- Circular progress indicator.
- Habit name.
- 5-day history grid.

#### [NEW] [status_cell.dart](file:///C:/Users/hp/habitloop/lib/widgets/status_cell.dart)
Widget for individual status icons (checkmark/cross) or values (miles/pages).

### Theme & Styling

#### [MODIFY] [main.dart](file:///C:/Users/hp/habitloop/lib/main.dart)
Setup app theme (Dark mode by default based on the screenshot) and initial routes.

## Verification Plan

### Manual Verification
- Verify the layout on Android/iOS emulators.
- Test adding a new habit.
- Test toggling status for the last 5 days.
- Ensure color coding matches the design.
