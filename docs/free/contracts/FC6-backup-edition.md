# FC6 · 备份、恢复与版本边界

版本 `0.1-draft`。免费版无登录和默认自动云同步；商业版依赖独立远程实现。

## 备份输入输出

输入选择范围与目标文件；输出版本化 manifest + 业务 JSON/SQLite 一致性快照 + 附件。manifest 含 format_version、schema_version、app_version、created_at、local_user_id、各项记录数和 SHA-256 校验。制作期间使用一致性读取/SQLite 支持的备份方式，不直接拷贝尚未 checkpoint 的活跃 WAL 主文件。

备份不包含 Key、凭据引用秘密、原始调试日志、设备通知注册号和可自动恢复执行的 pending Agent 动作。对话/记忆属于用户业务数据，可在导出预览选择；不要误称普通 ZIP 已加密。JSON/CSV 原始业务导出与完整可恢复备份分别提供，CSV 对公式前缀和特殊字符做安全编码。

成功：`{"format_version":1,"backup_id":"backup1","counts":{"todos":12,"memories":3},"credentials_included":false}`。

失败：`{"code":"backup_write_failed","published":false}`；先临时文件写完校验再发布，失败不能留下看似完整的最终包。

## 恢复状态与失败

`selected → validating → preview → user_confirmed → staging → committing → completed / failed`。文件是非可信输入：限制总大小、条数、解压膨胀比，拒绝路径穿越/绝对路径/符号链接逃逸；校验 checksum、格式/schema 兼容、外键、引用与类型。

先在临时目录/数据库完整导入校验；暂停写入/任务、关闭连接并完成安全切换。切换前保留当前库恢复点，失败回到旧库；不把导入半成品覆盖正在使用的数据。未来 schema 无迁移链返回 `unsupported_version`，不尝试删库降级。

恢复示例失败：`{"code":"checksum_mismatch","entry":"attachments/image1","active_database_changed":false}`。

导入同一 backup/import ID 重试不得重复生成业务；完整替换与合并有明确预览，初版建议只做完整恢复，跨库合并另立协议。恢复后 Key 重新配置；重建通知/检索索引，未完成 Agent run 标 interrupted，不自动执行导入提案。

## Edition 与商业迁移

在应用装配层选择 Local/Remote 仓库与 Agent Gateway，页面复用。商业权限必须服务器核验，客户端 `isPro` 不是权益凭证。免费昵称为本地展示名；升级才进入明确账户映射与同步流程。

迁移输入是用户确认的数据包及目标账户；先预览范围，再上传/核验/对账，最后切换数据源；保留本地备份。稳定 source/import ID 防重复，不自动把不同账户数据合并。Key 不上传，待执行指令不迁移执行。降级通过导出/恢复，不承诺因此删除云端数据。

验收：损坏附件、路径穿越、未来版本、写满磁盘、重复导入、切换中断均不能破坏原数据；离线手动功能不依赖订阅服务。
