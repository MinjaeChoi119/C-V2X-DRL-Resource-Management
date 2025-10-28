function [f, lineReward,lineAveReward, lineEpsilon, pointEpisode, lineQValueAction1, lineQValueAction2, lineQValueAction3, lineMaxQValueAction, lineExperienceMSE, lineEpisodeMSE] = hBuildFigure()

    % Copyright 2021 The MathWorks, Inc.

    plotRatio = 16/9;
%     trainingPlot = figure(...
%         'Visible','off',...
%         'HandleVisibility','off', ...
%         'NumberTitle','off',...
%         'Name','Cart Pole Custom Training (DQN agent)');
%     trainingPlot.Position(3) = plotRatio * trainingPlot.Position(4);
    
    f = figure;
    f.Visible = 'off';
    ax1 = subplot(4, 1, 1);
%     ax = gca(trainingPlot);
%     subplot()
    lineReward = animatedline(ax1, 'Color','black', 'LineWidth', 1.5);
    lineAveReward = animatedline(ax1,'Color','r','LineWidth',2);
    xlabel(ax1,'Episode')
    ylabel(ax1,'Reward')
    legend(ax1,'Cumulative Reward','Average Reward','Location','northwest')
    title(ax1,'Training Progress');
    
    ax2 = subplot(4, 1, 2);
    lineQValueAction1 = animatedline(ax2, 'Color','red', 'LineStyle', '-', 'LineWidth', 1.5);
    lineQValueAction2 = animatedline(ax2, 'Color','blue', 'LineStyle', '-', 'LineWidth', 1.5);
    lineQValueAction3 = animatedline(ax2, 'Color','green', 'LineStyle', '-', 'LineWidth', 1.5);
    lineMaxQValueAction = animatedline(ax2, 'Color','black', 'LineStyle', '-', 'LineWidth', 1.5);
    xlabel(ax2,'Episode')
    ylabel(ax2,'Action-Value (Q-Prediction)')
    legend(ax2,'Action 1 - Q-Value','Action 2 - Q-Value','Action 3 - Q-Value','Max Q-Value','Location','southwest')
    title(ax2,'Q-Value Prediction')



    ax3 = subplot(4, 1, 3);
    lineEpsilon = animatedline(ax3, 'Color','black', 'LineStyle', '-', 'LineWidth', 1.5);
    pointEpisode = animatedline(ax3, 'Color', 'r', 'LineStyle','none', 'Marker','*', 'MarkerSize', 6);
    xlabel(ax3,'Total Step')
    ylabel(ax3,'Epsilon (%)')
    legend(ax3,'Epsilon Value','Episode End Point','Location','northeast')
    ylim([0, 100]);
    yticks(0:10:100);
    title(ax3,'Epsilon Decay Progress')

    
    ax4 = subplot(4, 1, 4);
    lineExperienceMSE = animatedline(ax4, 'Color','blue', 'LineStyle', '-', 'LineWidth', 1.5);
    lineEpisodeMSE = animatedline(ax4, 'Color','red', 'LineStyle', '-', 'LineWidth', 1.5);
    xlabel(ax4,'Episode')
    ylabel(ax4,'MSE (Model Loss Function)')
    legend(ax4,'Experience MSE','Episode MSE','Location','southwest')
    title(ax4,'MSE Progress')
end