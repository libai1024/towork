# 免费版隔离探针

这些入口验证 F0 可行性，不读写生产业务库，不属于 App 已完成功能。结果见第 001 轮记录。

## Kimi（显式联网）

真实凭据仅放本地忽略的 `.env` 或进程环境；请勿写进命令、源码、截图和日志。默认 CI 不调用此脚本。

```sh
# 编程订阅独立端点；最多一个小请求
dart run tool/free_probes/kimi_smoke.dart --allow-paid-request --kimi-code
# 加上两轮合成工具调用，最多三个请求，可能消耗订阅用量
dart run tool/free_probes/kimi_smoke.dart --allow-paid-request --kimi-code --tools
# 开放平台端点；必须自行配置对应产品凭据，不使用订阅 Key 混测
dart run tool/free_probes/kimi_smoke.dart --allow-paid-request
```

环境字段：`KIMI_API_KEY`；开放平台 `KIMI_MODEL_DEFAULT`，Code `KIMI_CODE_MODEL`（默认 kimi-for-coding）。产品只由显式参数选定，失败不跨端点重试。User-Agent 为真实 ToWork/1.0；诊断成功不表示官方授权范围或产品上线条件自动满足。

## SQLite（本地）

```sh
dart run build_runner build
dart run tool/free_probes/database_probe.dart
flutter test test/data/local/database_probe_test.dart
```

探针在系统临时目录建立自己的数据库并清理；两张 probe 表仅验证迁移、事务与幂等回执。`database_probe.g.dart` 是 Drift 生成文件，修改表结构后重新生成，不手工修改生成文件。

## Agent 事务闭环（显式联网）

```sh
# Code 独立端点，最多 3 轮模型请求，只使用合成待办与临时数据库
dart run tool/free_probes/agent_smoke.dart --allow-paid-request --kimi-code
```

此入口调用真实 `AgentRunner`、`KimiModelGateway` 和生产 SQLite 命令层：提案 → 总是询问阻止写入 → 校验合成目标后批准 → 事务回执 → 模型总结 → 关闭/重开验证。结束后清理临时数据库，不触碰用户业务库。日志只记录产品、模型、轮数、回执数、重开结果与供应商 usage，不打印 Key、完整协议或推理内容。它是用户主动运行的测试，不能注册为 Code 后台任务；不属于聊天页面已经接通的证据。
