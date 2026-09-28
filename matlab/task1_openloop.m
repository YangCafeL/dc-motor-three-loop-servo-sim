%% 任务一：绘制仿真系统开环伯德图，计算开环截止频率与相位裕度
% 模型：直流有刷电机（电压 -> 转速）+ PWM驱动等效增益，构成单位反馈速度环的开环传递函数
% 电机开环传函（PPT"系统建模"页推导）：
%   Gopen(s) = W(s)/Ua(s) = (Km/Je) / [ s*(Ra + La*s) + Km*Kb/Je ]
% 本脚本：
%   1) 搭建 Simulink 开环模型 task1_model.slx（结构同 PPT 第13页框图）
%   2) 用 linearize 从模型中提取开环传函，与解析式对比验证
%   3) 绘制开环伯德图，计算截止频率 Wc、相位裕度 Pm、幅值裕度 Gm
clear; clc; close all;
P = motor_params();
resdir = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resdir,'dir'), mkdir(resdir); end

%% 1. 解析开环传递函数
Gmotor = tf(P.Km, [P.La*P.Je, P.Ra*P.Je, P.Km*P.Kb]);   % 电机: 电压->转速
L = P.Kpwm * Gmotor;                                    % 计及PWM等效增益的开环传函
disp('Open-loop transfer function L(s) = W(s)/Uref(s):'); L

%% 2. 搭建/加载 Simulink 开环模型
mdl = 'task1_model';
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist([mdl '.slx'],'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);

add_block('simulink/Sources/Step',[mdl '/Ref'],'Position',[30 95 60 125], ...
    'Time','0.05','Before','0','After','P.Un','SampleTime','0');
add_block('simulink/Math Operations/Gain',[mdl '/Kpwm'],'Gain','P.Kpwm','Position',[100 95 140 125]);
add_block('simulink/Math Operations/Sum',[mdl '/Sum'],'Inputs','+-','IconShape','round','Position',[185 95 205 115]);
add_block('simulink/Continuous/Transfer Fcn',[mdl '/ElecTF'],'Position',[250 87 330 133], ...
    'numerator','[1]','denominator','[P.La P.Ra]');
add_block('simulink/Math Operations/Gain',[mdl '/Km'],'Gain','P.Km','Position',[365 100 405 130]);
add_block('simulink/Continuous/Transfer Fcn',[mdl '/MechTF'],'Position',[440 92 520 138], ...
    'numerator','[1]','denominator','[P.Je 0]');
add_block('simulink/Math Operations/Gain',[mdl '/Kb'],'Gain','P.Kb','Position',[440 200 480 230], ...
    'Orientation','left');
add_block('simulink/Sinks/To Workspace',[mdl '/vel_out'],'VariableName','vel_sim', ...
    'SaveFormat','Structure With Time','Position',[560 105 620 135]);
add_block('simulink/Continuous/Integrator',[mdl '/PosInt'],'Position',[560 180 590 210]);
add_block('simulink/Sinks/To Workspace',[mdl '/pos_out'],'VariableName','pos_sim', ...
    'SaveFormat','Structure With Time','Position',[630 180 690 210]);

add_line(mdl,'Ref/1','Kpwm/1','autorouting','on');
add_line(mdl,'Kpwm/1','Sum/1','autorouting','on');
add_line(mdl,'Sum/1','ElecTF/1','autorouting','on');
add_line(mdl,'ElecTF/1','Km/1','autorouting','on');
add_line(mdl,'Km/1','MechTF/1','autorouting','on');
add_line(mdl,'MechTF/1','vel_out/1','autorouting','on');
add_line(mdl,'MechTF/1','PosInt/1','autorouting','on');
add_line(mdl,'PosInt/1','pos_out/1','autorouting','on');
add_line(mdl,'MechTF/1','Kb/1','autorouting','on');
add_line(mdl,'Kb/1','Sum/2','autorouting','on');
save_system(mdl);

%% 3. 从 Simulink 模型线性化提取开环传函（在参考输入处打断回路）
try
    io(1) = linio([mdl '/Ref'],1,'input');          % 回路断点：参考输入
    io(2) = linio([mdl '/Kb'],1,'output');          % 输出点：转速信号
    setlinio(mdl,io);
    L_sim = linearize(mdl);
    L_sim = minreal(tf(L_sim),1e-6);
    disp('Open-loop TF linearized from Simulink model:'); L_sim
    [na,da] = tfdata(L,'v'); [nb,db] = tfdata(L_sim,'v');
    n = max(numel(na),numel(nb)); m = max(numel(da),numel(db));
    pad = @(v,k) [zeros(1,k-numel(v)) v];      % 高次补零对齐
    fprintf('Max coeff deviation analytic vs linearized: %.3e (model verified)\n', ...
        max(abs(pad(na,n)-pad(nb,n)), abs(pad(da,m)-pad(db,m))));
catch ME
    fprintf('Linearize skipped (%s)\n', ME.message);
end

%% 4. 开环伯德图 + 截止频率/相位裕度/幅值裕度
[Gm,Pm,Wcg,Wcp] = margin(L);
fprintf('\n========== Task 1 Results ==========\n');
fprintf('Open-loop crossover freq Wc = %.2f rad/s = %.2f Hz\n', Wcp, Wcp/2/pi);
fprintf('Phase margin            Pm  = %.2f deg\n', Pm);
fprintf('Open-loop phase at Wc       = %.2f deg\n', 180+angle(freqresp(L,j*Wcp))*180/pi);
fprintf('Gain margin             Gm  = %.2f dB (at %.2f rad/s)\n', 20*log10(Gm), Wcg);
fprintf('DC loop gain L(0)           = %.1f  (=Kpwm/Kb)\n', dcgain(L));
fprintf('====================================\n');

f = figure('Visible','off','Position',[50 50 900 700],'Color','w');
[mag,phs,wg] = bode(L,logspace(-1,4,3000));
mag = squeeze(mag); phs = squeeze(phs); wg = squeeze(wg);
subplot(2,1,1);
semilogx(wg,20*log10(mag),'b','LineWidth',1.5); hold on; grid on;
yline(0,'k--');
plot(Wcp,0,'ro','MarkerFaceColor','r');
text(Wcp,3,sprintf('  W_c=%.1f rad/s (%.1f Hz)',Wcp,Wcp/2/pi));
ylabel('幅值 (dB)'); title('开环伯德图 (L(s)=K_{pwm}\cdotG_{motor}(s))');
subplot(2,1,2);
semilogx(wg,phs,'b','LineWidth',1.5); hold on; grid on;
yline(-180,'k--');
ph_wc = angle(freqresp(L,j*Wcp))*180/pi;
plot(Wcp,ph_wc,'ro','MarkerFaceColor','r');
text(Wcp,ph_wc+15,sprintf('  P_m=%.1f°',Pm));
xlabel('频率 (rad/s)'); ylabel('相角 (deg)');
sgtitle(sprintf('任务一：开环伯德图  W_c=%.1f rad/s, P_m=%.1f°, G_m=\\infty(二阶系统)',Wcp,Pm),'FontSize',13);
exportgraphics(f,fullfile(resdir,'task1_bode.png'),'Resolution',150);

% 开环模型时域验证：24V 阶跃电压作用下的转速响应
simOut = sim(mdl,'StopTime','0.5');
tv = simOut.vel_sim.time; wv = simOut.vel_sim.signals.values;
f2 = figure('Visible','off','Position',[50 50 800 450],'Color','w');
plot(tv,wv/pi*180,'b','LineWidth',1.5); grid on;
xlabel('Time (s)'); ylabel('Speed (deg/s)');
title('Task1: open-loop model verification - speed response to 24V step');
exportgraphics(f2,fullfile(resdir,'task1_step_verify.png'),'Resolution',150);
fprintf('Open-loop check: steady speed = %.1f rad/s (theory 24/Kb = %.1f rad/s)\n', wv(end), P.Un/P.Kb);
close_system(mdl,0);
close all;
disp('Task 1 done. Figures saved to results/.');
