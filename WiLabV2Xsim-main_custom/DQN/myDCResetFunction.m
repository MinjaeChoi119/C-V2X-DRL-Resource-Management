function [InitialObservation, LoggedSignal] = myDCCResetFunction()

%rho_values = 100:20:400; %100~400 중 임의의 20 배수
%rho_initial = randsample(rho_values, 1); 

rho_values = 180:20:220;
rho_initial = randsample(rho_values, 1);
rho_initial_segmentated_index=round((rho_values)/20)-4;

CBR_initial_table = [0.471129045;
                    0.546971022;
                    0.614906569;
                    0.674315107;
                    0.721577499;
                    0.761341181;
                    0.796477273;
                    0.824161055;
                    0.851615964;
                    0.87109677;
                    0.891393936;
                    0.907352874;
                    0.920753606;
                    0.92969531;
                    0.940673526;
                    0.948941533];

CBR_initial = CBR_initial_table(rho_initial_segmentated_index,1); % 0~1사이의 실수

LoggedSignal.State = rho_initial;
InitialObservation = LoggedSignal.State;

end