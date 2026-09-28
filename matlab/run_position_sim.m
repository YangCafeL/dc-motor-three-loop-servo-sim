function out = run_position_sim(mdl, Kpp, Kpi, Kpd, Tstop, fastOn)
%RUN_POSITION_SIM 在三环模型上以给定位置环PID增益运行仿真
%   fastOn=true 时启用 Fast Restart（批量寻优时避免重复编译模型）。
%   Fast Restart 模式下 StopTime 必须与模型编译时一致，故不再向 sim 传 StopTime。
    if nargin < 5, Tstop = 3.0; end
    if nargin < 6, fastOn = false; end
    assignin('base','Kpp',Kpp);
    assignin('base','Kpi',Kpi);
    assignin('base','Kpd',Kpd);
    if ~evalin('base','exist(''P'',''var'')')
        assignin('base','P',motor_params());   % 模型中 P.Ts 等参数取自 base 工作区
    end
    if fastOn
        if strcmp(get_param(mdl,'FastRestart'),'off')
            set_param(mdl,'StopTime',num2str(Tstop));
            set_param(mdl,'FastRestart','on');
        end
        out = sim(mdl);                        % StopTime 由模型设置决定
    else
        out = sim(mdl,'StopTime',num2str(Tstop));
    end
end
