% MATLAB code to plot data from each merged_DataValues Excel file in folders on a single figure with larger legend box size
close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window

% Define the folder path (modify this to your actual folder location)
base_folder = 'Output\raw200'; % Modify this to your folder path
folders = {'CRlimit_1000','CRlimit_0006','CRlimit_0003','CRlimit_ETSI'};

% Define color order for different plots
color_order = lines(length(folders)); % MATLAB's default color scheme for lines

%% CBR - PDR
figure;
hold on; % Hold on to plot multiple datasets on the same axes

% Loop through each folder
for i = 1:length(folders)
    folder_path = fullfile(base_folder, folders{i});
    file_path = fullfile(folder_path, 'Merged_DATAvalues.xlsx');
    
    % Check if the file exists in the folder
    if isfile(file_path)
        % Read data from the Excel file
        data = readmatrix(file_path);
        
        % Check if data has at least four columns
        if size(data, 2) >= 4
            x = data(:, 2); % Second column for x-axis
            y = data(:, 4); % Fourth column for y-axis
            if i == 1
                plot(x, y, '', 'Color', color_order(i, :), 'MarkerFaceColor', color_order(i, :), ...
                 'DisplayName', folders{i},'LineStyle', '-', 'MarkerSize', 10, 'LineWidth', 1.5);
            % Plot the data with specified color and label
            else 
                plot(x, y, 'o', 'Color', color_order(i, :), 'MarkerFaceColor', color_order(i, :), ...
                 'DisplayName', folders{i},'LineStyle', 'none', 'MarkerFaceColor', 'none');
            end
        else
            warning(['File ', file_path, ' does not have enough columns.']);
        end
    else
        warning(['File ', file_path, ' does not exist.']);
    end
end

% Finalize the plot
title('CBR - PDR');
xlabel('Average CBR');
ylabel('Average PDR');
yline(0.9, 'HandleVisibility', 'off');
legend_obj = legend('show', 'Location', 'bestoutside'); % Show legend with folder names
grid on;

% Increase the size of the legend box
legend_obj.ItemTokenSize = [30, 18]; % Adjust this to control the icon size in the legend box
set(legend_obj, 'FontSize', 10); % Increase the font size if needed

hold off; % Release hold on the plot

%% RHO - CRlimit
figure;
hold on; % Create a new figure for the next plot

% Loop through each folder
for i = 1:length(folders)
    folder_path = fullfile(base_folder, folders{i});
    file_path = fullfile(folder_path, 'Merged_DATAvalues.xlsx');
    
    % Check if the file exists in the folder
    if isfile(file_path)
        % Read data from the Excel file
        data = readmatrix(file_path);
        
        % Check if data has at least four columns
        if size(data, 2) >= 4
            x = data(:, 1); % First column for x-axis
            y = data(:, 3); % Third column for y-axis
            
            % Apply scaling to y-values greater than or equal to 0.6
            y_adjusted = y;
            y_adjusted(y >= 0.6) = y(y >= 0.6) / 100;
            
            % Plot the data with specified color and label
            if i == 1 || i == 5
                plot(x, y_adjusted, '', 'Color', color_order(i, :), 'MarkerFaceColor', color_order(i, :), ...
                 'DisplayName', folders{i}, 'LineStyle', '-', 'MarkerSize', 10, 'LineWidth', 1.5);
            else 
                plot(x, y_adjusted, '', 'Color', color_order(i, :), 'MarkerFaceColor', color_order(i, :), ...
                 'DisplayName', folders{i}, 'LineStyle', '-', 'MarkerFaceColor', 'none');
            end
        else
            warning(['File ', file_path, ' does not have enough columns.']);
        end
    else
        warning(['File ', file_path, ' does not exist.']);
    end
end

% Finalize the plot
title('RHO - CRlimit');
xlabel('Rho');
ylabel('Average CRlimit');
yticks([0.003, 0.006, 0.01]);
yticklabels({'0.003', '0.006', '1'});
ylim([0 0.012]);

% Add break indicator on y-axis at 0.01
yline(0.01, '--k', 'HandleVisibility', 'off'); % Dashed line to indicate break

% Legend settings
legend_obj = legend('show', 'Location', 'bestoutside'); % Show legend with folder names
grid on;

% Increase the size of the legend box
legend_obj.ItemTokenSize = [30, 18]; % Adjust this to control the icon size in the legend box
set(legend_obj, 'FontSize', 10); % Increase the font size if needed

hold off; % Release hold on the plot

%% RHO - CBR
figure;
hold on; % Create a new figure for the next plot

% Loop through each folder
for i = 1:length(folders)
    folder_path = fullfile(base_folder, folders{i});
    file_path = fullfile(folder_path, 'Merged_DATAvalues.xlsx');
    
    % Check if the file exists in the folder
    if isfile(file_path)
        % Read data from the Excel file
        data = readmatrix(file_path);
        
        % Check if data has at least four columns
        if size(data, 2) >= 4
            x = data(:, 1); % Second column for x-axis
            y = data(:, 2); % Fourth column for y-axis
            if i == 1
                plot(x, y, '', 'Color', color_order(i, :), 'MarkerFaceColor', color_order(i, :), ...
                 'DisplayName', folders{i},'LineStyle', '-', 'MarkerSize', 10, 'LineWidth', 1.5);
            % Plot the data with specified color and label
            else 
                plot(x, y, 'o', 'Color', color_order(i, :), 'MarkerFaceColor', color_order(i, :), ...
                 'DisplayName', folders{i},'LineStyle', 'none', 'MarkerFaceColor', 'none');
            end
        else
            warning(['File ', file_path, ' does not have enough columns.']);
        end
    else
        warning(['File ', file_path, ' does not exist.']);
    end
end

% Finalize the plot
title('RHO - CBR');
xlabel('Rho');
ylabel('Average CBR');
legend_obj = legend('show', 'Location', 'bestoutside'); % Show legend with folder names
grid on;

% Increase the size of the legend box
legend_obj.ItemTokenSize = [30, 18]; % Adjust this to control the icon size in the legend box
set(legend_obj, 'FontSize', 10); % Increase the font size if needed

hold off; % Release hold on the plot

%% RHO - PDR
figure;
hold on; % Create a new figure for the next plot

% Loop through each folder
for i = 1:length(folders)
    folder_path = fullfile(base_folder, folders{i});
    file_path = fullfile(folder_path, 'Merged_DATAvalues.xlsx');
    
    % Check if the file exists in the folder
    if isfile(file_path)
        % Read data from the Excel file
        data = readmatrix(file_path);
        
        % Check if data has at least four columns
        if size(data, 2) >= 4
            x = data(:, 1); % Second column for x-axis
            y = data(:, 4); % Fourth column for y-axis
            if i == 1
                plot(x, y, 'x', 'Color', color_order(i, :), 'MarkerFaceColor', color_order(i, :), ...
                 'DisplayName', folders{i},'LineStyle', 'none', 'MarkerSize', 10, 'LineWidth', 1.5);
            % Plot the data with specified color and label
            else 
                plot(x, y, 'o', 'Color', color_order(i, :), 'MarkerFaceColor', color_order(i, :), ...
                 'DisplayName', folders{i},'LineStyle', 'none', 'MarkerFaceColor', 'none');
            end
        else
            warning(['File ', file_path, ' does not have enough columns.']);
        end
    else
        warning(['File ', file_path, ' does not exist.']);
    end
end

% Finalize the plot
title('RHO - PDR');
xlabel('Rho');
ylabel('Average PDR');
yline(0.9, 'HandleVisibility', 'off');
legend_obj = legend('show', 'Location', 'bestoutside'); % Show legend with folder names
grid on;

% Increase the size of the legend box
legend_obj.ItemTokenSize = [30, 18]; % Adjust this to control the icon size in the legend box
set(legend_obj, 'FontSize', 10); % Increase the font size if needed

hold off; % Release hold on the plot
