%% 任务五：PSO（粒子群）优化位置环 PID 参数
% 粒子群优化算法 (Kennedy & Eberhart, 1995)：
%   每个粒子代表一组候选 PID 参数 x=[Kpp,Kpi,Kpd]，粒子根据个体历史最优 pbest
%   与群体全局最优 gbest 更新速度与位置：
%       v = w*v + c1*r1*(pbest-x) + c2*r2*(gbest-x);   x = x + v
%   适应度函数（在 Simulink 三环模型上闭环评估）：
%       J = ITAE + 2000*超调(>2°部分)^2 + 500*调节时间(>1.5s部分)^2 + 100*稳态误差^2
%   即在保证任务四指标(超调<=2°, ts<1.8s)前提下最小化 ITAE（时间加权误差）。
clear; clc; close all;
rng(1);
resdir = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resdir,'dir'), mkdir(resdir); end

mdl = 'task4_three_loop';
if ~bdIsLoaded(mdl)
    if exist([mdl '.slx'],'file'), load_system(mdl); else, build_three_loop_model(); end
end

%% PSO 参数
nPop = 18;  nIter = 15;
lb = [2   0     0    ];   % Kpp, Kpi, Kpd 下限
ub = [40  20    0.05 ];   % 上限
w_max = 0.9; w_min = 0.4; c1 = 1.8; c2 = 1.8;

X  = lb + rand(nPop,3).*(ub-lb);          % 初始位置
V  = zeros(nPop,3);
J  = zeros(nPop,1);
for i = 1:nPop, J(i) = pso_cost(X(i,:),mdl,true); end
[pbestJ, ib] = min(J);  pbestJ0 = J; pbestX = X; gbestX = X(ib,:); gbestJ = pbestJ;
histJ = gbestJ;

%% PSO 主循环（首次评估时自动启用 Fast Restart 加速批量仿真）
for k = 1:nIter
    w = w_max - (w_max-w_min)*k/nIter;
    for i = 1:nPop
        r1 = rand(1,3); r2 = rand(1,3);
        V(i,:) = w*V(i,:) + c1*r1.*(pbestX(i,:)-X(i,:)) + c2*r2.*(gbestX-X(i,:));
        X(i,:) = max(min(X(i,:)+V(i,:),ub),lb);
        J(i) = pso_cost(X(i,:),mdl,true);
        if J(i) < pbestJ0(i)
            pbestJ0(i) = J(i); pbestX(i,:) = X(i,:);
        end
    end
    [gbestJ, ib] = min(pbestJ0);
    gbestX = pbestX(ib,:);
    histJ(end+1) = gbestJ; %#ok<AGROW>
    fprintf('PSO iter %2d/%d: best J = %.4f  (Kpp=%.3f Ki=%.3f Kd=%.4f)\n', ...
        k, nIter, gbestJ, gbestX(1), gbestX(2), gbestX(3));
end
set_param(mdl,'FastRestart','off');   % 关闭 Fast Restart 以便变步长/变StopTime运行
fprintf('\nPSO 最优参数: Kpp=%.4f, Kpi=%.4f, Kpd=%.5f\n', gbestX(1),gbestX(2),gbestX(3));

%% 最优参数运行 + 与手动整定对比
outBest = run_position_sim(mdl,gbestX(1),gbestX(2),gbestX(3),3.0);
report_and_plot(outBest,gbestX(1),gbestX(2),gbestX(3),resdir,'task5_pso');

outMan = run_position_sim(mdl,10,0,0,3.0);
t  = outMan.pos_sim.time;  pMan = outMan.pos_sim.signals.values;
t2 = outBest.pos_sim.time; pPso = outBest.pos_sim.signals.values;

f = figure('Visible','off','Position',[60 60 950 550],'Color','w');
plot(t,pMan*180/pi,'b--','LineWidth',1.5); hold on; grid on;
plot(t2,pPso*180/pi,'r-','LineWidth',1.5);
yline(180,'k:','180°');
legend('手动整定 (K_p=10,K_i=0,K_d=0)', ...
    sprintf('PSO优化 (K_p=%.2f,K_i=%.2f,K_d=%.3f)',gbestX(1),gbestX(2),gbestX(3)));
xlabel('时间 (s)'); ylabel('位置 (deg)');
title('任务五：PSO 优化 PID 与手动整定的位置阶跃响应对比');
exportgraphics(f,fullfile(resdir,'task5_comparison.png'),'Resolution',150);

f2 = figure('Visible','off','Position',[80 80 700 420],'Color','w');
plot(0:numel(histJ)-1,histJ,'o-','LineWidth',1.4); grid on;
xlabel('迭代次数'); ylabel('全局最优适应度 J');
title('任务五：PSO 收敛曲线');
exportgraphics(f2,fullfile(resdir,'task5_pso_convergence.png'),'Resolution',150);

save('results/task5_pso_best.mat','gbestX','histJ');
close_system(mdl,0);
close all;
disp('Task 5 done.');

%% ---------- 适应度函数 ----------
function J = pso_cost(x, mdl, fastOn)
    persistent evallog
    if isempty(evallog)
        evallog = fopen('results/task5_eval.log','w','n','UTF-8');
    end
    try
        out = run_position_sim(mdl,x(1),x(2),x(3),2.5,fastOn);
        t = out.pos_sim.time; pos = out.pos_sim.signals.values;
        fprintf(evallog,'x=[%.3f %.3f %.4f] n=%d tEnd=%.3f maxAbs=%.4f finiteAll=%d\n', ...
            x(1),x(2),x(3),numel(pos),t(end),max(abs(pos)),all(isfinite(pos)));
        if any(~isfinite(pos)) || any(abs(pos)>50)
            fprintf(evallog,'  -> PENALTY (nan or >50 rad)\n');
            J = 1e9; return;
        end
    catch ME
        fprintf(evallog,'x=[%.3f %.3f %.4f] EXCEPTION: %s\n', x(1),x(2),x(3),ME.message);
        J = 1e9; return
    end
    ref = pi;
    idx = t >= 0.05;
    tt = t(idx)-0.05; ee = abs(ref-pos(idx));
    itae = trapz(tt, tt.*ee);
    over_deg = (max(pos)-ref)*180/pi; if over_deg<0, over_deg=0; end
    [~,ts] = settle_metrics(t,pos,ref,0.02);
    ess = abs(ref-pos(end))*180/pi;
    J = itae + 2000*over_deg^2 + 500*max(ts-1.5,0)^2 + 100*ess^2;
end
