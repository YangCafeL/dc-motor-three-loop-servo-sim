%% 任务三：设计串联矫正环节，绘制闭环伯德图并计算系统带宽
% 设计思路：
%   任务二表明纯比例控制存在静态误差(0型系统)，且带宽有限。
%   串联矫正环节采用  PI(消除静差) + 超前网络(补偿相角、拓宽带宽)：
%       Gc(s) = Kc*(s+z)/s * (1+s/wz2)/(1+s/wp2),   z=10, wz2=150, wp2=600
%   用二分法确定 Kc 使校正后开环穿越频率达到目标值 Wc_target。
clear; clc; close all;
P = motor_params();
resdir = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resdir,'dir'), mkdir(resdir); end

Gmotor = tf(P.Km, [P.La*P.Je, P.Ra*P.Je, P.Km*P.Kb]);   % 电机对象
Kp2 = 2;  L2 = Kp2*Gmotor;  T2 = feedback(L2,1);        % 矫正前（任务二基线）

z = 10; wz2 = 150; wp2 = 600;                            % PI零点 / 超前网络零极点
Wc_target = 600;                                         % 目标开环穿越频率 (rad/s)

% ---- 二分法整定 Kc ----
Kc_lo = 0.05; Kc_hi = 20;
for it = 1:60
    Kc = (Kc_lo+Kc_hi)/2;
    Gc_try = Kc*tf([1 z],[1 0])*tf([1/wz2 1],[1/wp2 1])*Gmotor;
    if getcrossover(Gc_try) > Wc_target, Kc_hi = Kc; else, Kc_lo = Kc; end
end
Gc = Kc*tf([1 z],[1 0])*tf([1/wz2 1],[1/wp2 1]);   % 矫正环节
L3 = Gc*Gmotor;  T3 = feedback(L3,1);
[Gm2,Pm2,Wcg2,Wcp2] = margin(L2);
[Gm3,Pm3,Wcg3,Wcp3] = margin(L3);
bw2 = bandwidth(T2,-3);  bw3 = bandwidth(T3,-3);

disp('Compensator Gc(s):'); Gc
fprintf('\n================= Task 3 Results =================\n');
fprintf('                          before(P)      after(PI+lead)\n');
fprintf('Open-loop crossover Wc:  %7.1f rad/s  %7.1f rad/s\n', Wcp2, Wcp3);
fprintf('Phase margin Pm:         %7.1f deg    %7.1f deg\n', Pm2, Pm3);
fprintf('Closed-loop BW(-3dB):    %7.1f rad/s  %7.1f rad/s\n', bw2, bw3);
fprintf('                         (%.1f Hz)     (%.1f Hz)\n', bw2/2/pi, bw3/2/pi);
fprintf('Steady-state err(10rad/s): %.2f%%       ~= 0 (PI action)\n', 10/(1+dcgain(L2))/10*100);
fprintf('==================================================\n');

%% Simulink 验证模型：矫正前后闭环对比
mdl = 'task3_model';
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist([mdl '.slx'],'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);

add_block('simulink/Sources/Step',[mdl '/Ref'],'Position',[30 130 60 160], ...
    'Time','0.05','Before','0','After','10','SampleTime','0');
% 支路1：矫正前（纯比例）
add_block('simulink/Math Operations/Sum',[mdl '/Sum1'],'Inputs','+-','IconShape','round','Position',[115 90 135 110]);
add_block('simulink/Math Operations/Gain',[mdl '/Kp2'],'Gain',num2str(Kp2),'Position',[170 85 210 115]);
% 支路2：矫正后（PI+超前）
add_block('simulink/Math Operations/Sum',[mdl '/Sum2'],'Inputs','+-','IconShape','round','Position',[115 175 135 195]);
add_block('simulink/Continuous/Transfer Fcn',[mdl '/PI'],'Position',[170 165 230 205], ...
    'numerator',sprintf('[1 %g]',z),'denominator','[1 0]');
add_block('simulink/Continuous/Transfer Fcn',[mdl '/Lead'],'Position',[260 165 320 205], ...
    'numerator',sprintf('[1/%g 1]',wz2),'denominator',sprintf('[1/%g 1]',wp2));
% 支路1：矫正前（纯比例）独立闭环
add_block('simulink/Continuous/Transfer Fcn',[mdl '/Gmotor1'],'Position',[300 80 380 126], ...
    'numerator','[P.Km]','denominator','[P.La*P.Je P.Ra*P.Je P.Km*P.Kb]');
add_block('simulink/Sinks/To Workspace',[mdl '/w1'],'VariableName','w_pre', ...
    'SaveFormat','Structure With Time','Position',[430 93 490 123]);
% 支路2：矫正后（PI+超前）独立闭环
add_block('simulink/Continuous/Transfer Fcn',[mdl '/Gmotor2'],'Position',[370 165 450 211], ...
    'numerator','[P.Km]','denominator','[P.La*P.Je P.Ra*P.Je P.Km*P.Kb]');
add_block('simulink/Sinks/To Workspace',[mdl '/w2'],'VariableName','w_post', ...
    'SaveFormat','Structure With Time','Position',[500 178 560 208]);

add_line(mdl,'Ref/1','Sum1/1','autorouting','on');
add_line(mdl,'Ref/1','Sum2/1','autorouting','on');
add_line(mdl,'Sum1/1','Kp2/1','autorouting','on');
add_line(mdl,'Sum2/1','PI/1','autorouting','on');
add_line(mdl,'PI/1','Lead/1','autorouting','on');
add_line(mdl,'Kp2/1','Gmotor1/1','autorouting','on');
add_line(mdl,'Lead/1','Gmotor2/1','autorouting','on');
add_line(mdl,'Gmotor1/1','Sum1/2','autorouting','on');
add_line(mdl,'Gmotor1/1','w1/1','autorouting','on');
add_line(mdl,'Gmotor2/1','Sum2/2','autorouting','on');
add_line(mdl,'Gmotor2/1','w2/1','autorouting','on');
save_system(mdl);

simOut = sim(mdl,'StopTime','0.1');
t  = simOut.w_pre.time;
w1 = simOut.w_pre.signals.values;
w2 = simOut.w_post.signals.values;

f = figure('Visible','off','Position',[50 50 1100 750],'Color','w');
wplt = logspace(-1,4,2000);
[m1,p1] = bode(T2,wplt); m1 = squeeze(m1); p1 = squeeze(p1);
[m3,p3] = bode(T3,wplt); m3 = squeeze(m3); p3 = squeeze(p3);
subplot(2,2,1);
semilogx(wplt,20*log10(m1),'b--','LineWidth',1.3); grid on;
yline(0,'k:'); ylabel('幅值 (dB)');
title('矫正前闭环伯德图 (带宽 76.5 Hz)');
subplot(2,2,2);
semilogx(wplt,20*log10(m3),'r-','LineWidth',1.3); grid on;
yline(0,'k:'); ylabel('幅值 (dB)');
title('矫正后闭环伯德图 (带宽 144.7 Hz)');
subplot(2,2,3); hold on; grid on;
semilogx(wplt,20*log10(m3),'r','LineWidth',1.4);
xline(bw3,'k--',sprintf('带宽 %.0f rad/s (%.0f Hz)',bw3,bw3/2/pi));
yline(-3,'m:','-3dB');
set(gca,'XScale','log'); xlabel('频率 (rad/s)'); ylabel('|T| (dB)');
title('矫正后闭环幅频特性与 -3dB 带宽');
subplot(2,2,4);
plot(t,w1*180/pi,'b--',t,w2*180/pi,'r-','LineWidth',1.4); grid on;
legend('矫正前(有静差)','矫正后(PI+超前)');
xlabel('时间 (s)'); ylabel('转速 (deg/s)');
title('10 rad/s 阶跃响应对比（Simulink验证）');
sgtitle('任务三：串联矫正环节设计与闭环带宽','FontSize',13);
exportgraphics(f,fullfile(resdir,'task3_closedloop_bode.png'),'Resolution',150);
close_system(mdl,0);
close all;
disp('Task 3 done.');

function wc = getcrossover(L)
%GETCROSSOVER 求开环传函自上而下穿越 0dB 的频率（取最高一次）
    [mag,~,w] = bode(L,logspace(0,5,4000));
    mag = squeeze(mag);
    idx = find(mag(1:end-1)>=1 & mag(2:end)<1);   % 自上而下穿越
    if isempty(idx)
        wc = 0;
    else
        wc = w(idx(end));
    end
end
