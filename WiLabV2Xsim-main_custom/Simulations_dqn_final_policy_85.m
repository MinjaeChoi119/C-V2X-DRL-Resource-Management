close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window

%% Config
packetSize=300;        % 1000B packet size
nTransm=1;              % Number of transmission for each packet
sizeSubchannel=10;      % Number of Resource Blocks for each subchannel
Raw=200;                % Range of Awarness for evaluation of metrics
speed=50;               % Average speed
speedStDev=3;           % Standard deviation speed
SCS=15;                 % Subcarrier spacing [kHz]
pKeep=0.8;              % keep probability
periodicity=0.1;        % periodic generation every 100ms
sensingThreshold=-126;  % threshold to detect resources as busy
BandMHz=10;
MCS=3;
simTime = 100;

%rho_values = [100:10:200, 201:239, 240:10:360];
rho_values = [100:10:200, 201:239, 240:10:360];

% Configuration file
configFile = 'dqn_main.cfg';


%% Simulation DQN
for rho = rho_values
    % I/O folder, each rho has its own output directory
    outputFolder = sprintf('Output/raw200/CRlimit_final_policy_85/LTEV2X_%dMHz_DQN_rho_%d', BandMHz, rho);

    WiLabV2Xsim_final_policy_85(configFile,'outputFolder',outputFolder,'Technology','LTE-V2X','MCS_LTE',MCS,'beaconSizeBytes',packetSize,...
        'simulationTime',simTime,'rho',rho,'probResKeep',pKeep,'BwMHz',BandMHz,'vMean',speed,'vStDev',speedStDev,...
        'cv2xNumberOfReplicasMax',nTransm,'allocationPeriod',periodicity,'sizeSubchannel',sizeSubchannel,...
        'powerThresholdAutonomous',sensingThreshold,'Raw',Raw,'FixedPdensity',false,'dcc_active',true,'cbrActive',true)

end