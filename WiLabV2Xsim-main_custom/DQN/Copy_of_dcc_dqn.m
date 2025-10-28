%% Custom Code Start
clear  
close all  
clc 

%% Parameter Setting (초기설정 및 환경정의)
obsInfo = rlNumericSpec([1, 1]); % rho에는 제한 없음, CBR은 0~1로 제한
obsInfo.Name = "DCC Example Observation";
obsInfo.Description = "rho"; 
actInfo = rlFiniteSetSpec([1 0.006 0.003]);
actInfo.Name = "CR_limit"; 
actInfo.Description = "Packet_generation_Control";
first_decay_episode = true;
last_decay_episode = true; 
env = rlFunctionEnv(obsInfo, actInfo, 'myDCStepFunction', 'myDCResetFunction');
%cartpole_env = rlPredefinedEnv("CartPole-Discrete");  

% myDCCStepFunction = 입력된 CBR에 ACTION이 선택되면...어떻게 해야되지  
% myDCCResetFunction = 학습이 완료된 후의 CBR 초기값은...0~1사이의 랜덤으로?

%% 수도코드 구현
[f, lineReward,lineAveReward, lineEpsilon, pointEpisode, lineQValueAction1, lineQValueAction2, lineQValueAction3, lineMaxQValueAction, lineExperienceMSE, lineEpisodeMSE] = DCC_hBuildFigure;  % 그림과 보상 선 초기화 (그래프 설정 자세한 세팅은 AC_hBuildFigure.m에 있음)
f.Visible = 'on';  % 그림을 보이게 설정

episodeCumulativeRewardVector = [];
aveWindowSize = 25;  % 이동 평균 창 크기 설정

capacity_size = 1e6;

observation_size = [1 1];
action_size = [1 1];


buffer = rl.util.ExperienceBuffer(capacity_size, {observation_size}, {action_size});

%% 훈련 조건 설정
dnn = [
    featureInputLayer(obsInfo.Dimension(1), 'Normalization', 'none', 'Name', 'state')  % 1차원 입력층
    fullyConnectedLayer(64, 'Name', 'CriticStateFC1')  % 64개의 노드로 이루어진 첫 번째 완전 연결층
    reluLayer('Name', 'CriticRelu1')  % ReLU 활성화 함수
    fullyConnectedLayer(64, 'Name', 'CriticStateFC2')  % 64개의 노드로 이루어진 두 번째 완전 연결층
    reluLayer('Name', 'CriticCommonRelu1')  % ReLU 활성화 함수
    fullyConnectedLayer(length(actInfo.Elements), 'Name', 'output')  % 4개의 노드를 가지는 출력층 (행동 수에 맞춰 설정)
];

criticOpts = rlRepresentationOptions('LearnRate',0.001,'GradientThreshold',1); % 신경망 학습 옵션 설정
critic = rlQValueRepresentation(dnn,obsInfo,actInfo,'Observation',{'state'},criticOpts); % Q-Value 신경망 설정
target_critic = rlQValueRepresentation(dnn,obsInfo,actInfo,'Observation',{'state'},criticOpts); % 타겟 Q-Value 신경망 설정

agentOpts = rlDQNAgentOptions(...
    'UseDoubleDQN',false, ... % Double DQN 사용 여부 설정 (False로 설정됨)
    'TargetSmoothFactor',1, ... % 타겟 신경망 가중치 동기화 비율 설정
    'TargetUpdateFrequency',500, ... % 타겟 신경망 업데이트 빈도 설정
    'ExperienceBufferLength',capacity_size, ... % 경험 리플레이 메모리 크기 설정
    'DiscountFactor',0.99, ... % 할인율 설정 (보상의 현재 가치)
    'MiniBatchSize',512); % 미니 배치 크기 설정 원래 512

agent = rlDQNAgent(critic,agentOpts); % DQN 에이전트 생성

trainOpts = rlTrainingOptions(...
    'MaxEpisodes',1500, ... 
    'MaxStepsPerEpisode',100, ...
    'Verbose',false, ...
    'Plots','none',...
    'StopTrainingCriteria','AverageReward',... % 이 부분도 수정이 필요함
    'StopTrainingValue',1000); % 이 부분 수정 요망

EpsilonDecay = 0.001;
Epsilon = 1;
EpsilonMin = 0.01;

%% Iteration Block
total_step = 0; 

total_episode_buffer = cell(1, trainOpts.MaxEpisodes);
unit_episode_buffer = rl.util.ExperienceBuffer(trainOpts.MaxStepsPerEpisode, {observation_size}, {action_size});

for episodeCt = 1:trainOpts.MaxEpisodes
    reset(unit_episode_buffer);
    reset(env);

    episodeReward = zeros(trainOpts.MaxStepsPerEpisode,1);
    tempMSE = 0; % 임시 MSE 초기화

    for stepCt = 1:trainOpts.MaxStepsPerEpisode
        explor_prob = rand(); 
        Obs = env.LoggedSignals.State;
         if explor_prob < Epsilon 
            Action =  randsample(actInfo.Elements,1); % 탐험 시 랜덤한 행동 선택
         elseif explor_prob >= Epsilon % 이용 시 최대 Q-value를 가지는 행동 선택
            Action = getAction(critic, {Obs});
         end
         [NextObs,Reward,IsDone,LoggedSignals] = step(env, Action);
         exp = {{Obs}, {Action}, Reward, {NextObs}, IsDone};
         append(buffer, {exp}); % 리플레이 버퍼에 경험 저장
         append(unit_episode_buffer, {exp}); % 에피소드 버퍼에 경험 저장
         episodeReward(stepCt, 1) = Reward; % 보상 기록
            
         if buffer.Length >= agent.AgentOptions.MiniBatchSize
         % 경험 리플레이에서 샘플링하여 미니 배치 생성
            miniBatch = createSampledExperienceMiniBatch(buffer, agent.AgentOptions.MiniBatchSize);
            
            % Training Network Optimize
            mini_obs = miniBatch{1};
            mini_act = miniBatch{2};
            mini_reward = miniBatch{3};
            mini_nexobs = miniBatch{4};
            mini_isdone = miniBatch{5};

            % 타겟 Q-value 계산
            [targetQValue, MaxActionIndices] = getMaxQValue(target_critic, miniBatch{4});
            
            % 타겟 Q-value 계산 (종료되지 않은 상태와 종료된 상태 구분)
            targetQValue(~logical(miniBatch{5})) = miniBatch{3}(~logical(miniBatch{5})) + ...
                agent.AgentOptions.DiscountFactor.*targetQValue(~logical(miniBatch{5}));
            
            targetQValue(logical(miniBatch{5})) = miniBatch{3}(logical(miniBatch{5}));
            
            % 손실 함수 및 그래디언트 계산
            lossData.BatchSize = agent.AgentOptions.MiniBatchSize;
            lossData.ActInfo = actInfo;
            lossData.ActionBatch = miniBatch{2};
            lossData.TargetQValues = targetQValue;
            lossData.TotalStep = total_step;
            Grad = gradient(critic, @DQN_LossFunc, miniBatch{1}, lossData);

            % dlarray로 변환
            for i = 1:numel(Grad)
                Grad{i} = dlarray(Grad{i}, 'CB');  % 'CB'는 완전 연결층에 적합한 레이블
            end

            % 그래디언트 클리핑
            for gradNum = 1:size(Grad, 1)
                Grad{gradNum}(Grad{gradNum} > 1) = 1;
                Grad{gradNum}(Grad{gradNum} < -1) = -1;
            end
            
            % 네트워크 예측 Q값 계산 및 MSE 기록
            tempQPrediction = evaluate(critic, mini_obs);
            tempQPrediction = tempQPrediction{:};

            ActionBatch = lossData.ActionBatch{:};
            ActionElementArray = repmat(lossData.ActInfo.Elements, 1, lossData.BatchSize);
            ActionIdxMat = (ActionBatch(:, :)*1000) == (ActionElementArray*1000);

            tempQPrediction = tempQPrediction(ActionIdxMat);
            tempQPrediction = reshape(tempQPrediction,size(lossData.TargetQValues));

            error = targetQValue - tempQPrediction;
            error_square = error.^2;
            tempMSE(stepCt) = mean(error_square); % 현재 스텝의 MSE(Mean Squared Error) 기록

            critic = optimize(critic, Grad); % 그래디언트 적용하여 네트워크 최적화

            % Epsilon 감소: 탐험 확률을 점진적으로 줄임
            Epsilon = max(Epsilon*(1-EpsilonDecay), EpsilonMin);

            % 일정 주기마다 타겟 네트워크 업데이트
            if mod(total_step, agent.AgentOptions.TargetUpdateFrequency) == 0
                target_critic = syncParameters(target_critic, critic, 1);
            end
        end

         total_step = total_step + 1;

         if IsDone == 1
            break;
         end

         %if stepCt == trainOpts.MaxStepsPerEpisode
         if stepCt == trainOpts.MaxStepsPerEpisode
            break;
         end
    end

    experienceMSE = mean(tempMSE);
   
    predict_batch = getSampledExperienceCustomBuffer(unit_episode_buffer);
    predict_batch = batchExperienceCustomBuffer(unit_episode_buffer, predict_batch);

    % Critic 네트워크로 Q-Value 예측
    episodeQPrediction = evaluate(critic, predict_batch{1});
    tempQPrediction = episodeQPrediction;
    % 타겟 네트워크로 타겟 Q-Value 계산
    [episodeTargetQValue, MaxActionIndices] = getMaxQValue(target_critic, predict_batch{4});
    
    episode_reward = predict_batch{3};
    episode_action = predict_batch{2};

    % 타겟 Q-Value 계산 (종료되지 않은 상태와 종료된 상태 구분)
    episodeTargetQValue(~logical(predict_batch{5})) = predict_batch{3}(~logical(predict_batch{5})) + ...
        agent.AgentOptions.DiscountFactor.*episodeTargetQValue(~logical(predict_batch{5}));
    episodeTargetQValue(logical(predict_batch{5})) = predict_batch{3}(logical(predict_batch{5}));

    % Q-Value 예측값과 타겟 Q-Value 간의 오차 계산 및 MSE 기록
    episodeQPrediction = episodeQPrediction{:};
    ActionBatch = predict_batch{2}{:};
    ActionElementArray = repmat(actInfo.Elements, 1, size(predict_batch{2}{1},3));
    %ActionIdxMat = ActionBatch(:, :) == ActionElementArray;
    ActionIdxMat = (ActionBatch(:, :) * 1000) == (ActionElementArray * 1000); %중요 action이 소수점이라 인식을 못 하여 수정
    
    episodeQPrediction = episodeQPrediction(ActionIdxMat);
    episodeQPrediction = reshape(episodeQPrediction, size(episodeTargetQValue));

    error = episodeTargetQValue - episodeQPrediction;  
    error_square = error.^2;
    episodeMSE = mean(error_square);

    % Q-Value의 평균값 계산
    QPredictionAverage = mean(tempQPrediction{1}, 2);
    maxQPredictionAverage = mean(max(tempQPrediction{1}));  

    % 그래프에 데이터 포인트 추가 (보상, MSE, Q-Value 등)
    addpoints(lineQValueAction1, episodeCt, double(QPredictionAverage(1)));
    addpoints(lineQValueAction2, episodeCt, double(QPredictionAverage(2)));
    addpoints(lineQValueAction3, episodeCt, double(QPredictionAverage(3)));
    addpoints(lineMaxQValueAction, episodeCt, double(maxQPredictionAverage));
    addpoints(lineExperienceMSE, episodeCt, double(experienceMSE));
    addpoints(lineEpisodeMSE, episodeCt, double(episodeMSE));

    % 누적 보상 업데이트 
    episodeCumulativeReward = sum(episodeReward);
    episodeCumulativeRewardVector = cat(2, episodeCumulativeRewardVector, episodeCumulativeReward);
    movingAveReward = movmean(episodeCumulativeRewardVector, aveWindowSize, 2);

    % 보상 기준 충족 시 훈련 중단
    %if movingAveReward(end) >= trainOpts.StopTrainingValue
    %    disp(['Training stopped after ', int2str(episodeCt), ' episodes due to reaching the reward threshold of ', num2str(trainOpts.StopTrainingValue)]);
    %    break;
    %end
    
    % 그래프에 보상 데이터 추가
    addpoints(lineReward, episodeCt, episodeCumulativeReward);
    addpoints(lineAveReward, episodeCt, movingAveReward(end));

    % Epsilon 관련 정보 업데이트 (감소 시작 및 마지막 단계 확인)
    if (Epsilon ~= 1) && (Epsilon ~= 0.01)
        if first_decay_episode
            disp(['First Decay Episode : ', int2str(episodeCt)]);
            first_decay_episode = false;
        end
        addpoints(lineEpsilon, total_step, Epsilon*100);
        addpoints(pointEpisode, total_step, Epsilon*100);

    elseif Epsilon == 0.01
        if last_decay_episode
            disp(['Last Decay Episode : ', int2str(episodeCt)]);
            addpoints(lineEpsilon, total_step, Epsilon*100);
            addpoints(pointEpisode, total_step, Epsilon*100);
            last_decay_episode = false;
        end
    end

    drawnow; % 그래프 업데이트
    total_episode_buffer{episodeCt} = unit_episode_buffer;
end    
save('ReferenceModel.mat', 'critic', 'target_critic');

