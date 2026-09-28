# 直流有刷电机伺服控制建模 —— MATLAB/Simulink 仿真说明

## 1. 环境要求
- MATLAB R2024a（需含 Simulink、Control System Toolbox）
- 无需其他工具箱；所有脚本均为纯 MATLAB 代码，不依赖额外文件

## 2. 文件清单

| 文件 | 说明 |
|---|---|
| `motor_params.m` | 电机与控制器公共参数（所有任务共用） |
| `task1_openloop.m` | 任务一：开环伯德图 + 截止频率 + 相位裕度 |
| `task1_model.slx` | 任务一 Simulink 开环模型（结构同 PPT 框图） |
| `task2_speed_step.m` | 任务二：速度环阶跃响应及三项指标 |
| `task2_model.slx` | 任务二 Simulink 速度闭环模型 |
| `task3_lead_comp.m` | 任务三：串联矫正环节设计 + 闭环带宽 |
| `task3_model.slx` | 任务三矫正前后对比模型 |
| `task4_position_step.m` | 任务四：三环系统 180° 位置阶跃 |
| `task4_three_loop.slx` | 三环（电流+速度+位置）Simulink 模型 |
| `task5_pso_pid.m` | 任务五：PSO 优化位置环 PID |
| `settle_metrics.m` | 指标计算辅助函数（稳定时间/静差） |
| `build_three_loop_model.m` | 三环模型自动构建函数 |
| `run_position_sim.m` / `report_and_plot.m` | 仿真运行与出图辅助函数（任务四/五共用） |
| `results/` | 各任务结果图（PNG） |

## 3. 运行步骤
在 MATLAB 中将当前目录切换到本文件夹（`cd` 到 `matlab/`），在命令行依次执行：

```matlab
task1_openloop        % 任务一：约 3~5 min（含模型搭建与线性化验证）
task2_speed_step      % 任务二：约 2 min
task3_lead_comp       % 任务三：约 3 min
task4_position_step   % 任务四：约 3 min（首次运行自动搭建三环模型）
task5_pso_pid         % 任务五：约 10~20 min（PSO 约 290 次闭环仿真，已启用 Fast Restart 加速）
```

每个脚本自动完成：模型搭建/加载 → 仿真 → 指标计算（打印到命令行）→ 结果图保存到 `results/`。
各脚本相互独立，也可单独运行；三环模型中的位置环 PID 增益由脚本写入工作区变量 `Kpp/Kpi/Kpd`。

## 4. 结果汇总

| 任务 | 指标 | 结果 |
|---|---|---|
| 一 | 开环截止频率 Wc | 162.8 rad/s（25.9 Hz） |
| 一 | 相位裕度 Pm / 幅值裕度 Gm | 77.6° / ∞（二阶系统） |
| 二 | 超调量 / 稳定时间 / 静态误差 | 5.79% / 0.064 s / 0.03% |
| 三 | 矫正后闭环带宽(-3dB) | 909.5 rad/s（144.7 Hz），矫正前 76.5 Hz |
| 四 | 超调量 / 调节时间 | 0.003°(≤2°) / 0.503 s(<1.8 s) |
| 五 | PSO 最优 PID 与对比 | Kpp=15.45, Ki=0, Kd=0；超调 0.003°，ts=0.407s（比手动整定快 19%） |
