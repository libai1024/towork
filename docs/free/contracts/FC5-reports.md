# FC5 · 多视图、统计、报告与产物

版本 `0.1-draft`。统计和产物均以本地记录为证据；模型仅负责文字总结。

## 输入与统计

输入 `period_start, period_end_exclusive, timezone, category_scope, filters, generation_revision`。选择一级分类默认含子分类，保存解析后的范围与快照；无记录明确输出 0/无数据，不虚构完成率。

列表/看板/日历/热力图/时间轴/分类分布/趋势使用同一查询口径。建议完成数按 completed_at 落在周期内的实例计数，新增数按 created_at；取消不计完成，重复待办统计实例而非规则。完成率必须带分子/分母/口径，不能把两个不同时间集合直接相除；具体产品指标在 F4 fixture 冻结。

报告输入先固化 `snapshot_id, captured_at, record_versions, metrics, evidence[]`；AI 回答不得覆盖本地数字。ReportDocument 含版本、标题、周期、昵称快照、分类范围、指标、总结段落、来源引用和模板 ID/版本。

```json
{"schema_version":1,"report_id":"report1","snapshot_id":"s1","period":{"start":"2026-09-14","end_exclusive":"2026-09-21","timezone":"Asia/Shanghai"},"metrics":{"completed":7},"sections":[{"title":"本周进展","text":"完成了七项任务。","evidence_ids":["e1"]}],"template_id":"weekly-simple","template_version":1}
```

## 状态、重试与接口

`queued → snapshot_ready → summary_ready → render_pending → completed`，任一步可 failed/cancelled。产物失败只重试渲染；总结已成功落盘不再次调用模型。未知模型响应是否完成时，费用仍可能发生，不能承诺取消必定不计费。

`report.generate` 返回 `job_id,report_id,status`，会话展示任务进度和报告入口，不等待到任意超时后谎报完成。定时与手动使用相同任务核心；同周默认自动唯一，手动重新生成提升 revision，旧版在新版完成前仍可用。

成功：`{"report_id":"report1","status":"completed","artifacts":[{"type":"png","id":"image1"},{"type":"pdf","id":"pdf1"}]}`。

失败：`{"report_id":"report1","status":"render_pending","last_error":"font_unavailable","retry_step":"render"}`。没有图片不能显示保存成功。

## 输出与验收

首版保留周/月/自定义周期；AI 写总结 + 用户可选海报模板；正文、Markdown、PDF、PNG 保存/分享与重新生成。PNG/PDF 共用结构化文档与本地字体，长中文、换页、无数据、深浅主题分别验证。分享由用户点击系统分享面板触发。

后台补跑仍统计原周期，保存 planned_at/generated_at；没有准时生成能力时清楚显示待补跑。通知链接仅指向已存在的报告或任务状态。

验收 fixture 固定时区、时间、分类树和实例版本；从明细重算每个统计值，校验归档报告不会因当前昵称/分类改名而默默重写。AI 总结出错可以重生成，但数字始终以 snapshot 为准。
