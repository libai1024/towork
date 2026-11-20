part of 'row_filter_sheet.dart';

/// 日期值选择（沿用 field_editors 的快捷 chip + 滚轮模式）。
Future<String?> _showDatePickerSheet(
  BuildContext context, {
  required bool withTime,
  String? current,
}) {
  return AppSheet.show<String>(
    context,
    title: withTime
        ? context.strings.chooseDateAndTime
        : context.strings.chooseDate,
    child: _DatePickerValueSheet(withTime: withTime, current: current),
  );
}

class _DatePickerValueSheet extends StatefulWidget {
  const _DatePickerValueSheet({required this.withTime, this.current});

  final bool withTime;
  final String? current;

  @override
  State<_DatePickerValueSheet> createState() => _DatePickerValueSheetState();
}

class _DatePickerValueSheetState extends State<_DatePickerValueSheet> {
  late DateTime _selected = _parse(widget.current) ?? DateTime.now();

  static DateTime? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceAll(' ', 'T'))?.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var toMonday = (DateTime.monday + 7 - today.weekday) % 7;
    if (toMonday == 0) toMonday = 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (label, day) in [
                  (context.strings.today, today),
                  (
                    context.strings.tomorrow,
                    today.add(const Duration(days: 1)),
                  ),
                  (
                    context.strings.nextMonday,
                    today.add(Duration(days: toMonday)),
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: label,
                      onTap: () => setState(
                        () => _selected = DateTime(
                          day.year,
                          day.month,
                          day.day,
                          _selected.hour,
                          _selected.minute,
                        ),
                      ),
                    ),
                  ),
                AppChip(
                  label: context.strings.clear,
                  onTap: () => Navigator.of(context).pop(''),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: CupertinoDatePicker(
              mode: widget.withTime
                  ? CupertinoDatePickerMode.dateAndTime
                  : CupertinoDatePickerMode.date,
              initialDateTime: _selected,
              use24hFormat: true,
              onDateTimeChanged: (v) => _selected = v,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppButton(
                label: context.strings.cancel,
                type: AppButtonType.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              AppButton(
                label: context.strings.save,
                onPressed: () => Navigator.of(context).pop(
                  widget.current != null && _parse(widget.current) == _selected
                      ? widget.current!
                      : widget.withTime
                      ? _selected.toUtc().toIso8601String()
                      : formatDate(_selected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
