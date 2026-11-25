import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taskflow/core/db/hive_service.dart';
import 'package:taskflow/presentation/screens/task_list_screen.dart';

import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await HiveService.init();
    runApp(const ProviderScope(child: TaskFlow()));
  } catch (error, stackTrace) {
    debugPrint('Hive initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(
      MaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: DatabaseErrorScreen(errorMessage: error.toString()),
      ),
    );
  }
}

class TaskFlow extends StatelessWidget {
  const TaskFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const TaskListScreen(),
    );
  }
}

class DatabaseErrorScreen extends StatefulWidget {
  final String errorMessage;

  const DatabaseErrorScreen({super.key, required this.errorMessage});

  @override
  State<DatabaseErrorScreen> createState() => _DatabaseErrorScreenState();
}

class _DatabaseErrorScreenState extends State<DatabaseErrorScreen> {
  bool _isRetrying = false;
  String? _retryError;

  Future<void> _retryInitialization() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      _retryError = null;
    });

    try {
      await HiveService.init();

      if (!mounted) return;

      runApp(const ProviderScope(child: TaskFlow()));
    } catch (error, stackTrace) {
      debugPrint('Hive retry failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _retryError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Database error icon.
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storage_rounded,
                      size: 56,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Unable to Start Task Manager',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'We could not initialize the local '
                    'task database. Please try again.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Error details.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _retryError ?? widget.errorMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isRetrying ? null : _retryInitialization,
                      icon: _isRetrying
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        _isRetrying ? 'Retrying...' : 'Retry Initialization',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
