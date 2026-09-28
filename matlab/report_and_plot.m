function report_and_plot(out, Kpp, Kpi, Kpd, resdir, tag)
%REPORT_AND_PLOT 计算位置阶跃指标并绘图
    t    = out.pos_sim.time;
    pos  = out.pos_sim.signals.values;
    vel  = out.vel_sim.signals.values;
    curm = out.cur_sim.signals.values;
    curr = out.cur_raw.signals.values;
    posm = out.pos_meas_sim.signals.values;
    velm = out.vel_meas_sim.signals.values;
    ref  = pi;
    [~,ts]  = settle_metrics(t,pos,ref,0.02);
    [~,ts1] = settle_metrics(t,pos,ref,0.01);
    over_deg = (max(pos)-ref)*180/pi; if over_deg<0, over_deg=0; end
    ess_deg = abs(ref-pos(end))*180/pi;
    fprintf('\n========== %s Results (PID: Kp=%.4g Ki=%.4g Kd=%.4g) ==========\n', upper(tag),Kpp,Kpi,Kpd);
    fprintf('Overshoot: %.3f deg  (spec <= 2 deg)\n', over_deg);
    fprintf('Settling time (+-2%% of 180deg): %.3f s  (spec < 1.8 s)\n', ts);
    fprintf('Settling time (+-1%% of 180deg): %.3f s\n', ts1);
    fprintf('Steady-state error: %.4f deg\n', ess_deg);
    fprintf('Measurement noise RMS: current %.4f A, speed %.4f rad/s, position %.4f deg\n', ...
        std(curm-curr), std(velm-vel), std(posm-pos)*180/pi);
    fprintf('==================================================================\n');

    f = figure('Visible','off','Position',[40 40 1200 800],'Color','w');
    subplot(2,2,[1 2]);
    plot(t,pos*180/pi,'b','LineWidth',1.5); hold on; grid on;
    yline(180,'r--','给定 180°');
    yline(182,'k:','+2°'); yline(178,'k:','-2°');
    xlabel('时间 (s)'); ylabel('位置 (deg)');
    title(sprintf('位置环 180° 阶跃响应  超调 %.2f° (≤2°), t_s %.3f s (<1.8s)',over_deg,ts));
    subplot(2,2,3);
    plot(t,velm*180/pi,'Color',[0 0.4 0.8],'LineWidth',1.2); grid on;
    xlabel('时间 (s)'); ylabel('角速度 (deg/s)'); title('转子角速度（陀螺仪量程 ±1000°/s 内）');
    yline(1000,'r:'); yline(-1000,'r:');
    subplot(2,2,4);
    plot(t,curm,'Color',[0.8 0.2 0.2],'LineWidth',1.0); grid on;
    xlabel('时间 (s)'); ylabel('电枢电流 (A)'); title('电枢电流（电流环限幅 ±10A）');
    yline(10,'k:'); yline(-10,'k:');
    sgtitle(sprintf('%s: 三环伺服系统位置阶跃响应 (K_p=%.3g, K_i=%.3g, K_d=%.3g)',tag,Kpp,Kpi,Kpd),'FontSize',13);
    exportgraphics(f,fullfile(resdir,[tag '_position_step.png']),'Resolution',150);
    close all;
end
