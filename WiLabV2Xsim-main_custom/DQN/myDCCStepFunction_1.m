function [NextObs,Reward,IsDone,LoggedSignals] = myDCCStepFunction(Action,LoggedSignals)
persistent data rho_values;

if isempty(data)
    data = readtable('C:\Program Files\MATLAB\WiLabV2Xsim-main\DQN\DATA.xlsx'); 
    rho_values = 100:20:400;
end

rho = LoggedSignals.State(1); % 차량 밀도
CBR = LoggedSignals.State(2); % 현재 CBR

rho_initial_segmentated_index=round((rho_values)/20)-4;


%[isMember, index] = ismember(rho, rho_values); % LoggedSignals에 들어온 정보 중 DATA 엑셀에 일치하는 인덱스 반환 

if isMember
    if Action == 1
        average_prr = data{rho_initial_segmentated_index, 4}; % Action이 1일 때 4번째 열 사용
        rho = data{rho_initial_segmentated_index, 1};
        CBR = data{rho_initial_segmentated_index, 2};
        LoggedSignals.State = [rho; CBR]; 
        NextObs = LoggedSignals.State ;     
    elseif Action == 0.03
        average_prr = data{rho_initial_segmentated_index, 9}; % Action이 0.03일 때 9번째 열 사용
        rho = data{rho_initial_segmentated_index, 6};
        CBR = data{rho_initial_segmentated_index, 7};
        LoggedSignals.State = [rho; CBR]; 
        NextObs = LoggedSignals.State ; 
    elseif Action == 0.006
        average_prr = data{rho_initial_segmentated_index, 14}; % Action이 0.006일 때 14번째 열 사용
        rho = data{rho_initial_segmentated_index, 11};
        CBR = data{rho_initial_segmentated_index, 12};
        LoggedSignals.State = [rho; CBR]; 
        NextObs = LoggedSignals.State ;
    elseif Action == 0.003
        average_prr = data{rho_initial_segmentated_index, 19}; % Action이 0.003일 때도 14번째 열 사용
        rho = data{rho_initial_segmentated_index, 16};
        CBR = data{rho_initial_segmentated_index, 17};
        LoggedSignals.State = [rho; CBR]; 
        NextObs = LoggedSignals.State ;
    else
        error('Invalid Action value');
    end
end

Reward = -abs(0.9 - average_prr);

IsDone=0;










