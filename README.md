1. How to Run Locally
   Technology stack: Flutter (Dart), Material 3, flutter_riverpod for state management, and hive / hive_flutter for local persistence. The app follows a feature-first Clean Architecture structure with domain models and repository contracts, a Hive-backed data implementation, and Riverpod-driven presentation.

Prerequisites: Flutter SDK and a supported Android/iOS emulator or physical device; Xcode is required for iOS builds. Check the installed environment with flutter doctor.
flutter pub get
flutter analyze
flutter run
To select a device, run flutter devices, followed by flutter run -d <device-id>.

Environment variables: None. The app runs entirely on-device with Hive; no API base URL, server, credentials, or .env file is required.

Local storage: On startup, HiveService.init() initializes Hive and opens the tasks box. Tasks remain stored on the device across app restarts unless the app's data is cleared.

Implementation scope: This is a frontend-only solution. Task creation, retrieval, updates, deletion, and completion toggling use the local repository rather than HTTP endpoints. Therefore, backend endpoints and server-side validation are not demonstrated. Run and validate the app on your target device before submission.
2. Screen Structure
   Task List → Task Detail → Back to Task List  |  Task List → Add Task → Save/Cancel → Task List
3. Decision 1 — Optimistic vs. Pessimistic
   Pessimistic update: The UI waits for the Hive write and Riverpod refresh to finish before displaying the new completion state, so failed writes do not appear successful.
4. Decision 2 — Filter Persistence
   Preserve filters: Assignee and status selections live in a shared, non-`autoDispose` Riverpod provider, so returning from Task Detail or Add Task retains the previously selected filters while the application remains open.
5. Bug Hunt
   Bug 1 — Data insertion problem later identified the real problem causing in model class and fixed it


These two entries must be completed from the assignment's debugging question; the bug descriptions were not included in the requirements shared here. Do not submit the placeholders as final answers.
6. AI Usage
   I used ChatGPT to generate the README file and get help building the task filtering section (assignee and status filters).

Manual verification: [Add the specific checks or changes you personally performed before submission.]