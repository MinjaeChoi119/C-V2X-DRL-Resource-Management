% MATLAB Code to load DATAvalues from multiple folders and merge them

% Define the base folder path
baseFolder = 'E:\한양대 과제\종합설계\최종 workspace\WiLabV2Xsim-main (5)\Output\raw200\CRlimit_final_policy_85' ;  % 변경 필요

% Define the range of rho values (100 to 400 with step of 20)
rho_values = [100:10:200, 202:2:218];

% Initialize an empty array to store the merged data
mergedData = [];

% Loop over each rho value and load the DATAvalues.xlsx file
for rho = rho_values
    % Create the folder name dynamically
    folderName = sprintf('LTEV2X_10MHz_DQN_rho_%d', rho);
    
    % Create the full path to the DATAvalues.xlsx file
    filePath = fullfile(baseFolder, folderName, 'DATAvalues.xlsx');
    
    % Check if the file exists (in case some folders might be missing)
    if exist(filePath, 'file')
        % Read the data from the DATAvalues.xlsx file
        data = readmatrix(filePath);
        
        % Add the current rho value as the first column of the data
        dataWithRho = [rho, data];
        
        % Append the data to the mergedData array
        mergedData = [mergedData; dataWithRho];
    else
        fprintf('File not found: %s\n', filePath);
    end
end

% Define the output file path for the merged data
outputFile = fullfile(baseFolder, 'Merged_DATAvalues.xlsx');

% Write the merged data to a new Excel file
writematrix(mergedData, outputFile);

% Inform the user that the process is complete
disp('Data merging complete, and file saved.');