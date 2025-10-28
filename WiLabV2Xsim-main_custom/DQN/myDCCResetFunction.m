function [InitialObservation, LoggedSignal] = myDCCResetFunction()

rho_values = 100:20:400; %100~400 중 임의의 20 배수
rho_initial = randsample(rho_values, 1); 

CBR_initial = rand() % 0~1사이의 실수

LoggedSignal.State = [rho_initial; CBR_initial];
InitialObservation = LoggedSignal.State;

end