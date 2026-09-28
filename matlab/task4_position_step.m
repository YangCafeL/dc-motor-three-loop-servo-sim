%% 任务四：加入矫正环节后，位置环 180° 阶跃响应
% 指标要求：超调量 <= 2°，调节时间 < 1.8 s
% 系统结构（三环级联，内环等效为矫正环节）：
%   电流环 PI(Kpi_i,Ti_i) : 零点对消电磁极点 Ra/La, 穿越频率 ~300 rad/s,
%                           快速跟踪电流给定并限幅(±10A)保护驱动器
%   速度环 PI(Kpi_v,Ti_v) : 积分作用消除速度静差(对应任务三矫正思想), 穿越频率 ~50 rad/s
%   位置环 PID(Kpp,Kpi,Kpd): 位置环校正, 输出限幅 ±1000deg/s(陀螺仪量程约束)
%   反馈测量: 16位绝对式编码器(0~360deg量化), 陀螺仪(含30~100Hz噪声), 电流采样(含1/f噪声)
clear; clc; close all;
P = motor_params();
resdir = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resdir,'dir'), mkdir(resdir); end

% 位置环 PID 初值（手动整定）：
% 速度环闭环近似一阶 tau_v ≈ 1/50 = 0.02 s，位置环 L(s)=Kpp/(s*(tau_v*s+1))
% 取 Kpp=10: 等效阻尼比 zeta=1/(2*sqrt(Kpp*tau_v))≈1.1（过阻尼，理论无超调）
% 理论调节时间 ts ≈ 4/(zeta*wn), wn=sqrt(Kpp/tau_v)≈22.4 rad/s -> ts≈0.16s << 1.8s
Kpp = 10;  Kpi = 0;  Kpd = 0;

mdl = 'task4_three_loop';
if ~bdIsLoaded(mdl)
    if exist([mdl '.slx'],'file'), load_system(mdl); else, build_three_loop_model(); end
end

out = run_position_sim(mdl,Kpp,Kpi,Kpd,3.0);
report_and_plot(out,Kpp,Kpi,Kpd,resdir,'task4');
close_system(mdl,0);
disp('Task 4 done.');
