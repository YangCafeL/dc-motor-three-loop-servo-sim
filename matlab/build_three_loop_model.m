function build_three_loop_model()
%BUILD_THREE_LOOP_MODEL 搭建三环（电流环+速度环+位置环）直流伺服电机 Simulink 模型
%   模型名: task4_three_loop.slx
%   结构: 位置环PID(离散,1ms) -> 速度环PI(离散,1ms) -> 电流环PI(离散,1ms)
%         -> PWM电压限幅 -> 电机(La/Ra电气回路 + Je机械积分) -> 编码器/陀螺仪/电流采样反馈
%   反馈通道含测量模型: 编码器16位量化(0~360deg), 各环噪声(按PPT频段设定)
%   位置环PID增益引用工作区变量 Kpp/Kpi/Kpd，供任务五 PSO 在线寻优
P = motor_params();
mdl = 'task4_three_loop';
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist([mdl '.slx'],'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);

enc_rad = P.enc_res*pi/180;   % 编码器分辨率 (rad)

%% 位置环
add_block('simulink/Sources/Step',[mdl '/Ref'],'Position',[30 170 60 200], ...
    'Time','0.05','Before','0','After','pi','SampleTime','0');   % 180deg = pi rad
add_block('simulink/Math Operations/Sum',[mdl '/SumP'],'Inputs','+-','IconShape','round','Position',[110 170 130 190]);
add_block('simulink/Discrete/Discrete PID Controller',[mdl '/PID_pos'],'Position',[170 155 250 205], ...
    'Controller','PID','TimeDomain','Discrete-time','SampleTime','P.Ts', ...
    ...
    'P','Kpp','I','Kpi','D','Kpd','N','100', ...
    'LimitOutput','on','UpperSaturationLimit','P.Vref_max','LowerSaturationLimit','-P.Vref_max', ...
    'AntiWindupMode','clamping');

%% 速度环
add_block('simulink/Math Operations/Sum',[mdl '/SumV'],'Inputs','+-','IconShape','round','Position',[300 170 320 190]);
add_block('simulink/Discrete/Discrete PID Controller',[mdl '/PID_vel'],'Position',[360 155 440 205], ...
    'Controller','PI','TimeDomain','Discrete-time','SampleTime','P.Ts', ...
    ...
    'P',num2str(P.Kpi_v),'I',num2str(P.Kpi_v/P.Ti_v), ...
    'LimitOutput','on','UpperSaturationLimit',num2str(P.Imax),'LowerSaturationLimit',num2str(-P.Imax), ...
    'AntiWindupMode','clamping');

%% 电流环
add_block('simulink/Math Operations/Sum',[mdl '/SumI'],'Inputs','+-','IconShape','round','Position',[490 170 510 190]);
add_block('simulink/Discrete/Discrete PID Controller',[mdl '/PID_cur'],'Position',[550 155 630 205], ...
    'Controller','PI','TimeDomain','Discrete-time','SampleTime','P.Ts', ...
    ...
    'P',num2str(P.Kpi_i),'I',num2str(P.Kpi_i/P.Ti_i), ...
    'LimitOutput','on','UpperSaturationLimit',num2str(P.Umax),'LowerSaturationLimit',num2str(-P.Umax), ...
    'AntiWindupMode','clamping');

%% 电机本体（含反电动势内反馈）
add_block('simulink/Math Operations/Sum',[mdl '/SumE'],'Inputs','+-','IconShape','round','Position',[680 170 700 190]);
add_block('simulink/Continuous/Transfer Fcn',[mdl '/ElecTF'],'Position',[740 162 820 208], ...
    'numerator','[1]','denominator','[P.La P.Ra]');
add_block('simulink/Math Operations/Gain',[mdl '/Km'],'Gain','P.Km','Position',[850 175 890 205]);
add_block('simulink/Continuous/Transfer Fcn',[mdl '/MechTF'],'Position',[920 167 1000 213], ...
    'numerator','[1]','denominator','[P.Je 0]');
add_block('simulink/Math Operations/Gain',[mdl '/Kb'],'Gain','P.Kb','Position',[920 290 960 320], ...
    'Orientation','left');
add_block('simulink/Continuous/Integrator',[mdl '/PosInt'],'Position',[1030 180 1060 210]);

%% 测量与噪声模型
% 电流环噪声: 功率谱密度 ~ 1/f  -> 白噪声经 1/(s+0.5) 整形
add_block('simulink/Sources/Band-Limited White Noise',[mdl '/NoiseI'],'Position',[640 400 690 430], ...
    'Cov',num2str(P.noise_i_NP),'Seed','12345','Ts','P.Ts');
add_block('simulink/Continuous/Transfer Fcn',[mdl '/ShapeI'],'Position',[720 395 790 435], ...
    'numerator','[1]','denominator','[1 0.5]');
add_block('simulink/Math Operations/Sum',[mdl '/AddI'],'Inputs','++','Position',[840 330 860 350]);
% 速度环噪声: 30~100Hz 带通
add_block('simulink/Sources/Band-Limited White Noise',[mdl '/NoiseV'],'Position',[640 500 690 530], ...
    'Cov',num2str(P.noise_v_NP),'Seed','22222','Ts','P.Ts');
add_block('simulink/Continuous/Transfer Fcn',[mdl '/ShapeV'],'Position',[720 495 790 535], ...
    'numerator',sprintf('[2*pi*%g 0]',30),'denominator', ...
    sprintf('[1 2*pi*(%g+%g) (2*pi*%g)*(2*pi*%g)]',30,100,30,100));
add_block('simulink/Math Operations/Sum',[mdl '/AddV'],'Inputs','++','Position',[840 480 860 500]);
% 位置环噪声: 20~60Hz 带通 + 编码器16位量化
add_block('simulink/Sources/Band-Limited White Noise',[mdl '/NoiseP'],'Position',[640 600 690 630], ...
    'Cov',num2str(P.noise_p_NP),'Seed','33333','Ts','P.Ts');
add_block('simulink/Continuous/Transfer Fcn',[mdl '/ShapeP'],'Position',[720 595 790 635], ...
    'numerator',sprintf('[2*pi*%g 0]',20),'denominator', ...
    sprintf('[1 2*pi*(%g+%g) (2*pi*%g)*(2*pi*%g)]',20,60,20,60));
add_block('simulink/Discontinuities/Quantizer',[mdl '/Enc'],'Position',[1030 280 1060 310], ...
    'QuantizationInterval',num2str(enc_rad));
add_block('simulink/Math Operations/Sum',[mdl '/AddP'],'Inputs','++','Position',[1120 270 1140 290]);

%% 数据记录
logblk = 'simulink/Sinks/To Workspace';
add_block(logblk,[mdl '/L_ref'],'VariableName','ref_sim','SaveFormat','Structure With Time','Position',[110 250 170 280]);
add_block(logblk,[mdl '/L_cur'],'VariableName','cur_sim','SaveFormat','Structure With Time','Position',[840 390 900 420]);
add_block(logblk,[mdl '/L_curraw'],'VariableName','cur_raw','SaveFormat','Structure With Time','Position',[840 440 900 470]);
add_block(logblk,[mdl '/L_vel'],'VariableName','vel_sim','SaveFormat','Structure With Time','Position',[1050 110 1110 140]);
add_block(logblk,[mdl '/L_velm'],'VariableName','vel_meas_sim','SaveFormat','Structure With Time','Position',[900 550 960 580]);
add_block(logblk,[mdl '/L_pos'],'VariableName','pos_sim','SaveFormat','Structure With Time','Position',[1120 100 1180 130]);
add_block(logblk,[mdl '/L_posm'],'VariableName','pos_meas_sim','SaveFormat','Structure With Time','Position',[1180 340 1240 370]);

%% 连线
LN = @(a,b) add_line(mdl,a,b,'autorouting','on');
LN('Ref/1','SumP/1');      LN('SumP/1','PID_pos/1');
LN('PID_pos/1','SumV/1');  LN('SumV/1','PID_vel/1');
LN('PID_vel/1','SumI/1');  LN('SumI/1','PID_cur/1');
LN('PID_cur/1','SumE/1');  LN('SumE/1','ElecTF/1');
LN('ElecTF/1','Km/1');     LN('Km/1','MechTF/1');
LN('MechTF/1','PosInt/1'); LN('PosInt/1','Enc/1');
LN('Enc/1','AddP/1');      LN('ShapeP/1','AddP/2');
LN('AddP/1','SumP/2');     LN('AddP/1','L_posm/1');
LN('MechTF/1','AddV/1');   LN('ShapeV/1','AddV/2');
LN('AddV/1','SumV/2');     LN('AddV/1','L_velm/1');
LN('ElecTF/1','AddI/1');   LN('ShapeI/1','AddI/2');
LN('AddI/1','SumI/2');     LN('AddI/1','L_cur/1');
LN('ElecTF/1','L_curraw/1');
LN('MechTF/1','Kb/1');     LN('Kb/1','SumE/2');
LN('MechTF/1','L_vel/1');  LN('PosInt/1','L_pos/1');
LN('Ref/1','L_ref/1');
LN('NoiseI/1','ShapeI/1'); LN('NoiseV/1','ShapeV/1'); LN('NoiseP/1','ShapeP/1');

%% 求解器配置：固定步长 RK4, 步长 1e-4 s（控制器离散采样 1 ms，电气极点 594 rad/s 远离步长限制）
set_param(mdl,'SolverType','Fixed-step','Solver','ode4','FixedStep','1e-4','StopTime','3');
save_system(mdl);
fprintf('Model %s built and saved.\n', mdl);
end
