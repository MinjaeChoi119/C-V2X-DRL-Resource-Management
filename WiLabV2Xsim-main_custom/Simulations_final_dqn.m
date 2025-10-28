close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window

%% Config
packetSize = 300;         % 300B packet size
nTransm = 1;              % Number of transmission for each packet
sizeSubchannel = 10;      % Number of Resource Blocks for each subchannel
Raw = 200;                % Range of Awareness for evaluation of metrics
speed = 50;               % Average speed
speedStDev = 3;           % Standard deviation of speed
SCS = 15;                 % Subcarrier spacing [kHz]
pKeep = 0.8;              % Keep probability
periodicity = 0.1;        % Periodic generation every 100ms
sensingThreshold = -126;  % Threshold to detect resources as busy
BandMHz = 10;
MCS = 3;
simTime = 1;
rho_values = [500];   

% Configuration file
configFile = 'dqn_main.cfg';

%% Load DDQN Agent if active
dcc_active = false;% ETSI
dcc_active_DDQN = true; %Proposed
dcc_active_SAE = false; % SAE
if dcc_active_DDQN
    load('conferenceModel_final_85.mat')
end

%% Simulation DQN
for rho = rho_values
    % I/O folder, each rho has its own output directory
    outputFolder = sprintf('Output/CRlimit_%s/LTEV2X_%dMHz_DQN_rho_%d', '85', BandMHz, rho);

    % Run simulation for each density (rho)
    WiLabV2Xsim_final_dqn(configFile, 'outputFolder', outputFolder, 'Technology', 'LTE-V2X', ...
        'MCS_LTE', MCS, 'beaconSizeBytes', packetSize, 'simulationTime', simTime, ...
        'rho', rho, 'probResKeep', pKeep, 'BwMHz', BandMHz, 'vMean', speed, ...
        'vStDev', speedStDev, 'cv2xNumberOfReplicasMax', nTransm, 'allocationPeriod', periodicity, ...
        'sizeSubchannel', sizeSubchannel, 'powerThresholdAutonomous', sensingThreshold, ...
        'Raw', Raw, 'FixedPdensity', false, 'dcc_active', false, 'cbrActive', true, 'Agent', Agent)
end

%%