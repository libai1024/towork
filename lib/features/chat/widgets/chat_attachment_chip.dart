part of 'chat_input_bar.dart';

extension _ChatAttachmentChip on _ChatInputBarState {
  /// 待发附件条：图片缩略图或文件图标 + 名称 + 移除。
  /// 读屏播报为单一「待发送附件：名称」节点，移除按钮单独可聚焦。
  Widget _attachmentChip(AppColors c) {
    final image = _pendingImage;
    final preview = _pendingImagePreview;
    final label = image?.displayName ?? _pendingText?.name ?? '';
    return Padding(
      key: const ValueKey('pending-attachment-chip'),
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
      child: Semantics(
        container: true,
        label: context.strings.attachmentToSend(label),
        child: Row(
          children: [
            if (image != null && preview != null)
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    preview,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              )
            else
              ExcludeSemantics(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.fill1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.fileText,
                    size: 20,
                    color: c.labelSecondary,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.footnote.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
              ),
            ),
            // IconButton 自带 tooltip 语义，不再外包一层重复的 Tooltip。
            IconButton(
              key: const ValueKey('remove-attachment'),
              tooltip: context.strings.removeAttachment,
              onPressed: _removeAttachment,
              icon: Icon(LucideIcons.x, size: 16, color: c.labelSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
