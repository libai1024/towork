part of 'settings_page.dart';

extension _SettingsMorningTime on _SettingsPageState {
  /// 每日晨报时间滚轮（仅时:分），确认即生效 + Toast。
  void _pickMorningTime() {
    final c = AppColors.of(context);
    var (hour, minute) = ref.read(notifyMorningTimeProvider);
    var saving = false;
    AppSheet.show<void>(
      context,
      title: context.strings.morningDigestTime,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AbsorbPointer(
                absorbing: saving,
                child: SizedBox(
                  height: 160,
                  child: DefaultTextStyle(
                    style: AppTextStyles.title3.copyWith(color: c.labelPrimary),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: hour,
                            ),
                            itemExtent: 36,
                            backgroundColor: c.bgPrimary,
                            onSelectedItemChanged: (i) => hour = i,
                            children: [
                              for (var h = 0; h < 24; h++)
                                Center(
                                  child: Text(h.toString().padLeft(2, '0')),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          ':',
                          style: AppTextStyles.title3.copyWith(
                            color: c.labelTertiary,
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: minute,
                            ),
                            itemExtent: 36,
                            backgroundColor: c.bgPrimary,
                            onSelectedItemChanged: (i) => minute = i,
                            children: [
                              for (var m = 0; m < 60; m++)
                                Center(
                                  child: Text(m.toString().padLeft(2, '0')),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: AppButton(
                  label: context.strings.ok,
                  expand: true,
                  loading: saving,
                  onPressed: () async {
                    if (saving) return;
                    setSheetState(() => saving = true);
                    final saved = await savePreferences(context, ref, {
                      'morning_hour': hour,
                      'morning_minute': minute,
                    });
                    if (!context.mounted) return;
                    setSheetState(() => saving = false);
                    if (!saved) return;
                    Navigator.of(context).pop();
                    AppToast.show(
                      context,
                      message: context.strings.morningDigestSetTo(
                        hour.toString().padLeft(2, '0'),
                        minute.toString().padLeft(2, '0'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
