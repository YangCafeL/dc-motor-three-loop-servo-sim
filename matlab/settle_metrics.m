function [ess_out, ts] = settle_metrics(t, y, yfinal, band)
%SETTLE_METRICS  从仿真数据计算静态误差与稳定时间
%   [ess, ts] = settle_metrics(t, y, yfinal, band)
%   t       : 时间向量
%   y       : 输出向量
%   yfinal  : 稳态值（取末段均值）
%   band    : 误差带比例（如 0.02 表示 ±2%）
%   ess_out : 输出相对稳态值的最终偏差
%   ts      : 输出最后一次离开 ±band*yfinal 误差带的时刻
    n = numel(y);
    ess_out = y(end) - yfinal;          % 末时刻偏差（含数值误差）
    lo = yfinal*(1-band); hi = yfinal*(1+band);
    out_idx = find(y < lo | y > hi, 1, 'last');
    if isempty(out_idx)
        ts = t(1);
    elseif out_idx == n
        ts = t(end);
    else
        ts = t(out_idx+1);
    end
end
