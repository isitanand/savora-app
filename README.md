# Core Vision

## Overview
Core Vision is a calm, local-first reflection application built with Flutter. It is designed to be a private digital sanctuary, free from engagement algorithms, cloud tracking, and the pressure of "productivity."

The application follows strict "**Calm Tech**" principles: silence is preferred over noise, data belongs to the user, and the interface recedes when not in use.

## Philosophy
- **Local-First**: All data is stored on your device. Nothing leaves your phone.
- **Calm by Default**: No notifications, no streaks, no "overdue" tasks.
- **Pattern, Not Prescription**: The app observes patterns in your reflections but never judges or prescribes fixes.

## Features
- **Daily Stream**: A chronological timeline of your reflections.
- **Reflection Entry**: Quickly capture your mood, context, amount (if applicable), and notes.
- **Pattern View**: Gentle, qualitative observations of your habits (e.g., "Often noted late at night"). No graphs, no scores.
- **Monthly Intent**: A single, focused word or phrase for the month.
- **Context Archive**: A neutral collection of the places and moods you've experienced.
- **Quiet Space**: A minimal screen for unguided contemplation.
- **Data Transparency**: Full access to see every byte of data stored, with one-tap deletion.

## Architecture
Built with Flutter, ensuring cross-platform stability and a high-performance native feel.

- **State Management**: Local `setState` for simplicity and calmness (minimal reactive churn).
- **Data Layer**: Repository Pattern (`RepositoryInterface` -> `LocalFileRepository`).
- **Persistence**: JSON-based local storage in the application's document directory.
- **Theme**: Custom `CoreTheme` system enforcing a specific visual language ("Quiet Backgrounds", "Matte Surfaces").

## Getting Started
1. **Prerequisites**: Flutter SDK installed.
2. **Setup**:
   ```bash
   flutter pub get
   ```
3. **Run**:
   ```bash
   flutter run
   ```

## Privacy Pledge
Core Vision contains no analytics SDKs. It creates no network connections. It has no "cloud backup." Your data exists only where you can see it: on your device, in a clear JSON format.
