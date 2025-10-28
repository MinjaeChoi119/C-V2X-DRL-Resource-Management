function [f] = CartpoleFigure()

    % Copyright 2021 The MathWorks, Inc.

    plotRatio = 16/9;
    f = figure;
    if ~strcmp(f.WindowStyle,'docked')
                f.Position(3:4) = [0 400];
    end
    f.Position(3) = plotRatio * f.Position(4);
    ha = gca(f);
    ha.XLimMode = 'manual';
    ha.YLimMode = 'manual';
    ha.ZLimMode = 'manual';
    ha.DataAspectRatioMode = 'manual';
    ha.PlotBoxAspectRatioMode = 'manual';
    ha.YTick = [];
    
    ha.XLim = [-5 5];
    ha.YLim = [0 3];
    
    hold(ha,'on');
end