import 'package:material_ui/material_ui.dart';
import 'package:taskflow/domain/models/task_priority.dart';

import '../../../../core/theme/app_theme.dart';

class PrioritySelector extends FormField<TaskPriority> {
  PrioritySelector({
    super.key,
    TaskPriority? initialValue,
    ValueChanged<TaskPriority?>? onChanged,
    FormFieldValidator<TaskPriority>? validator,
    bool enabled = true,
    String label = 'Priority',
    bool isRequired = true,
  }) : super(
    initialValue: initialValue,
    enabled: enabled,

    validator: validator ??
            (value) {
          if (isRequired && value == null) {
            return 'Please select a task priority';
          }
          return null;
        },

    builder: (FormFieldState<TaskPriority> field) {
      final theme = Theme.of(field.context);
      final colorScheme = theme.colorScheme;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),


          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TaskPriority.values.map(
                  (priority) {
                final isSelected =
                    field.value == priority;

                final priorityColor =
                AppTheme.getPriorityColor(
                  priority.name,
                );

                return ChoiceChip(
                  label: Text(
                    _priorityLabel(priority),
                  ),

                  avatar: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.flag_outlined,
                    size: 18,
                    color: priorityColor,
                  ),

                  selected: isSelected,
                  showCheckmark: false,

                  // Single selection.
                  onSelected: enabled
                      ? (selected) {
                    final newValue = selected
                        ? priority
                        : null;

                    field.didChange(newValue);
                    onChanged?.call(newValue);
                  }
                      : null,

                  backgroundColor:
                  colorScheme.surface,

                  selectedColor:
                  priorityColor.withValues(
                    alpha: theme.brightness ==
                        Brightness.dark
                        ? 0.22
                        : 0.12,
                  ),

                  side: BorderSide(
                    color: isSelected
                        ? priorityColor
                        : colorScheme.outlineVariant,
                    width: isSelected ? 1.7 : 1,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),

                  labelStyle: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? priorityColor
                        : colorScheme.onSurface,
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                );
              },
            ).toList(),
          ),

          if (field.hasError) ...[
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: colorScheme.error,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    field.errorText ?? '',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    },
  );

  static String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}
