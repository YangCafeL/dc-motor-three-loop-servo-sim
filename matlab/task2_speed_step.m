%% 任务二：速度环阶跃响应，计算最大超调量、稳定时间、静态误差
% 结构：速度给定 -> 比例控制器 Kp -> 饱和(±24V) -> 电机 -> 转速反馈（单位负反馈）
% 基线采用纯比例控制（未加矫正），静态误差不为零（电机传函为0型系统，L(0)=Kp/Kb），
% 该误差即为任务三设计矫正环节（PI积分作用）的动机。
clear; clc; close all;
P = motor_params();
resdir = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resdir,'dir'), mkdir(resdir); end

Kp2 = 2;              % 比例控制器增益 (V/(rad/s))
ref_speed = 10;       % 速度阶跃给定 (rad/s) ≈ 573 deg/s，处于陀螺仪量程内

%% 1. 理论（线性）分析
Gmotor = tf(P.Km, [P.La*P.Je, P.Ra*P.Je, P.Km*P.Kb]);
L2 = Kp2*Gmotor;                       % 开环传函（不考虑饱和）
T2 = feedback(L2,1);                   % 闭环传函
S = stepinfo(T2);
ess_lin = ref_speed/(1+dcgain(L2));    % 0型系统阶跃静态误差
fprintf('Linear theory: overshoot %.1f%%, Ts(2%%) %.4f s, ess %.3f rad/s (%.2f%%)\n', ...
    S.Overshoot, S.SettlingTime, ess_lin, ess_lin/ref_speed*100);

%% 2. 搭建 Simulink 速度环模型（含驱动饱和，更贴近实际）
mdl = 'task2_model';
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist([mdl '.slx'],'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);

add_block('simulink/Sources/Step',[mdl '/Ref'],'Position',[30 95 60 125], ...
    'Time','0.05','Before','0','After',num2str(ref_speed),'SampleTime','0');
add_block('simulink/Math Operations/Sum',[mdl '/Sum'],'Inputs','+-','IconShape','round','Position',[105 95 125 115]);
add_block('simulink/Math Operations/Gain',[mdl '/Kp'],'Gain',num2str(Kp2),'Position',[160 90 200 120]);
add_block('simulink/Discontinuities/Saturation',[mdl '/Usat'],'Position',[230 90 260 120], ...
    'UpperLimit',num2str(P.Umax),'LowerLimit',num2str(-P.Umax));
add_block('simulink/Continuous/Transfer Fcn',[mdl '/ElecTF'],'Position',[300 82 380 128], ...
    'numerator','[1]','denominator','[P.La P.Ra]');
add_block('simulink/Math Operations/Gain',[mdl '/Km'],'Gain','P.Km','Position',[415 95 455 125]);
add_block('simulink/Continuous/Transfer Fcn',[mdl '/MechTF'],'Position',[490 87 570 133], ...
    'numerator','[1]','denominator','[P.Je 0]');
add_block('simulink/Sinks/To Workspace',[mdl '/vel_out'],'VariableName','vel_sim', ...
    'SaveFormat','Structure With Time','Position',[620 100 680 130]);

add_line(mdl,'Ref/1','Sum/1','autorouting','on');
add_line(mdl,'Sum/1','Kp/1','autorouting','on');
add_line(mdl,'Kp/1','Usat/1','autorouting','on');
add_line(mdl,'Usat/1','ElecTF/1','autorouting','on');
add_line(mdl,'ElecTF/1','Km/1','autorouting','on');
add_line(mdl,'Km/1','MechTF/1','autorouting','on');
add_line(mdl,'MechTF/1','vel_out/1','autorouting','on');
add_line(mdl,'MechTF/1','Sum/2','autorouting','on');
save_system(mdl);

%% 3. 运行仿真并计算实测指标
simOut = sim(mdl,'StopTime','0.4');
t  = simOut.vel_sim.time;  w = simOut.vel_sim.signals.values;
yf = w(end);
[~,ts] = settle_metrics(t,w,yf,0.02);
overshoot = max(max(w)-yf,0);
ess = abs(ref_speed - yf);

fprintf('\n========== Task 2 Results (speed step %.0f rad/s = %.0f deg/s) ==========\n', ...
    ref_speed, ref_speed*180/pi);
fprintf('Max overshoot: %.3f rad/s (%.2f%%)\n', overshoot, overshoot/ref_speed*100);
fprintf('Settling time (+-2%% band): %.4f s\n', ts);
fprintf('Steady-state error: %.4f rad/s = %.2f deg/s (%.2f%%)   [linear theory %.2f%%]\n', ...
    ess, ess*180/pi, ess/ref_speed*100, ess_lin/ref_speed*100);
fprintf('Final speed: %.3f rad/s\n', yf);
fprintf('==========================================================================\n');

%% 4. 绘图
f = figure('Visible','off','Position',[50 50 850 480],'Color','w');
plot(t,w/pi*180,'b','LineWidth',1.6); hold on; grid on;
yline(ref_speed*180/pi,'r--','给定值');
yline((yf+0.02*ref_speed)*180/pi,'k:','+2%误差带');
yline((yf-0.02*ref_speed)*180/pi,'k:','-2%误差带');
xlabel('时间 (s)'); ylabel('转速 (deg/s)');
title(sprintf('任务二：速度环阶跃响应（P控制基线）  \\sigma=%.1f%%, t_s=%.3fs, e_{ss}=%.2f%%', ...
    overshoot/ref_speed*100, ts, ess/ref_speed*100));
exportgraphics(f,fullfile(resdir,'task2_speed_step.png'),'Resolution',150);
close_system(mdl,0);
close all;
disp('Task 2 done.');
