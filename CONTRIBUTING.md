# 参与开发

ToWork 使用 Flutter 3.47.5 / Dart 3.13.4，Android 与 macOS 共用本地业务层。工作入口是 [AGENTS.md](AGENTS.md)，当前升级状态见 [交接文档](docs/upgrade/HANDOFF.md)。

## 开始工作

先检查 `git status --short` 和当前分支，保留已有工作区改动。阅读任务对应的架构、功能和交接文档。新工作分支使用 `codex/` 前缀，已绑定任务包时继续其分支。

```sh
flutter pub get --enforce-lockfile
bash tool/fetch_asr_models.sh
bash tool/install_hooks.sh
```

ASR 模型按固定 SHA-256 校验并放入 gitignore 的 assets 目录。Flutter SDK 需位于 PATH，也可通过 `FLUTTER_BIN` / `DART_BIN` 指定。所有 Flutter 命令串行执行。

## 实现与验证

- 页面、共享组件、数据和装配按依赖方向放置，文件体积遵循 500 行及存量只减规则。[架构](docs/ARCHITECTURE.md)、[编码规范](docs/standards/CODING.md)
- 回归聚焦真实风险，再运行完整质量门。平台、脚本模型、真实模型与真人输入分别记录证据。[测试规范](docs/standards/TESTING.md)
- 界面复用颜色、字号、间距和可访问性控件，附手机、键盘和桌面布局截图。[设计规范](DESIGN.md)
- 工具共享权限、校验、事务与回执链路，提示词变更同步版本和契约测试。[Agent 工具规范](docs/standards/AGENT-TOOLS.md)

```sh
bash tool/check.sh
```

质量门包含交付脚本检查、文档链接、lockfile、格式、静态分析、架构和全部普通测试。原生行为变更按测试规范补充设备验证。

## 提交与任务包

提交主题采用 `type(scope): summary`，类型包括 feat、fix、docs、refactor、test、build、ci、chore 等。每次提交保持一个可评审的目的。任务包分支附 `Spec: <slug>` 页脚，任务包记录 boundary、依赖、可执行 verify 和实际结果。

```text
fix(assist): retry a failed engine refresh

Spec: 2026-11-13_upgrade-experience-architecture
```

启用 spec 技能的任务通过其 harness 验证、检查点和最终归档命令提交。完成时核对所有验收条目，验证结果随当前树保存。普通任务按仓库 hooks 提交。

## PR 与发布

PR 使用仓库模板，说明目的、验证结果、兼容影响与待人工验收项。版本号和 tag 严格对应。官网发布、GitHub Release、签名和共享服务器路径按发布手册执行。[发布手册](docs/release/README.md)

凭据使用系统安全存储或 CI secrets，报告与日志按稳定错误码脱敏。设备验收记录应使用合成业务数据，保留用户生产资料库和现有签名的升级兼容性。
