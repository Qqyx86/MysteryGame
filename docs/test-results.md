# 自动化测试执行记录

## 执行环境

| 项目 | 内容 |
| --- | --- |
| 执行日期 | 2026-11-10 |
| 工具 | DevEco Studio 26.0.0.865 |
| HarmonyOS SDK | 26.0.0.105 |
| 测试框架 | `@ohos/hypium` 1.0.25 |
| 执行方式 | Hvigor 本地单元测试 |
| 模拟器 | Mate 90 Pro Max，API 26 |

## 执行命令

```powershell
$env:DEVECO_SDK_HOME = 'D:\deveco\DevEco Studio\sdk'
& 'D:\deveco\DevEco Studio\tools\hvigor\bin\hvigorw.bat' test `
  --mode module -p product=default -p module=entry@default `
  -p buildMode=debug --no-daemon
```

## 原始结果

```text
class=MysteryGameDomain
test=story_catalog_meets_assignment_minimums
result=Success
test=new_game_starts_at_library_with_persistable_schema
result=Success
test=library_choice_adds_clue_and_advances_node
result=Success
test=missing_clue_blocks_archive_unlock
result=Success
test=scenes_unlock_in_story_order
result=Success
test=branch_choice_changes_later_availability
result=Success
test=alternative_route_evidence_unlocks_gear_analysis
result=Success
test=complete_best_path_enters_deduction
result=Success
test=correct_deduction_unlocks_truth_ending
result=Success
test=wrong_suspect_unlocks_echo_ending
result=Success
test=insufficient_evidence_cannot_claim_truth
result=Success
test=save_round_trip_restores_state
result=Success
test=malformed_save_is_rejected_without_exception
result=Success
Tests run: 13, Failure: 0, Error: 0, Pass: 13, Ignore: 0
```

## 覆盖统计

由同一轮测试生成的 `coverageReport.json`：

| 指标 | 覆盖率 |
| --- | --- |
| 总行覆盖率 | 70.70% |
| 总函数覆盖率 | 65.12% |
| 总分支覆盖率 | 55.63% |
| `GameEngine.ets` 行覆盖率 | 73.81% |
| `GameEngine.ets` 函数覆盖率 | 83.33% |
| `StoryCatalog.ets` 行覆盖率 | 100% |
| `SaveCodec.ets` 行覆盖率 | 91.67% |

总覆盖率统计包含未由本地测试启动的 UIAbility 生命周期代码和大型 UI 文件，因此低于纯领域模块覆盖率。核心业务规则、剧情配置与存档编解码均已直接测试。
