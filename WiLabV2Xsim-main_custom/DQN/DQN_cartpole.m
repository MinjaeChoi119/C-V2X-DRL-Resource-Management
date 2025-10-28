%% Custom Code Start
clear  % Workspace를 초기화하여 변수들을 삭제
close all  % 열려있는 모든 figure를 닫음
clc  % 명령 창을 깨끗하게 함
%% Parameter Setting (초기설정 및 환경정의)
obsInfo = rlNumericSpec([4, 1]);  % 관측 값을 4x1벡터로
obsInfo.Name = "CartPole Example Observation";  % 관측 값의 이름 설정
obsInfo.Description = "x, dx, theta, dtheta";  % 각 관측 값을 x dx theta dtheta로
actInfo = rlFiniteSetSpec([-10 10]);  % 이산형 행동 정보 정의 -10 / 10
actInfo.Name = "CartPole Action";  % 행동 정보의 이름 설정
actInfo.Description = "Force[N]";  % 행동 정보의 설명 설정
first_decay_episode = true;  % 첫 감쇠 에피소드 여부 설정
last_decay_episode = true;  % 마지막 감쇠 에피소드 여부 설정
env = rlFunctionEnv(obsInfo, actInfo, 'myCartpoleStepFunction', 'myCartpoleResetFunction');  % 강화학습 환경 설정(관측벡터 행동벡터 스텝함수 스텝함수초기화)
cartpole_env = rlPredefinedEnv("CartPole-Discrete");  % 사전 정의된 카트폴 환경 설정
%% 수도코드 구현 (시각화 및 초기화)
[f, lineReward,lineAveReward, lineEpsilon, pointEpisode, lineQValueAction1, lineQValueAction2, lineMaxQValueAction, lineExperienceMSE, lineEpisodeMSE] = hBuildFigure;  % 그림과 보상 선 초기화 (그래프 설정 자세한 세팅은 AC_hBuildFigure.m에 있음)
f.Visible = 'on';  % 그림을 보이게 설정
episodeCumulativeRewardVector = [];  % 에피소드 누적 보상 벡터 초기화
aveWindowSize = 25;  % 이동 평균 창 크기 설정

capacity_size = 1e6; % 경험 리플레이 메모리 크기 설정

observation_size = [4 1]; % 관측 값은 4x1벡터
action_size = [1 1]; % 행동은 1x1 벡터 (-10, 10) 중 한개 값

buffer = rl.util.ExperienceBuffer(capacity_size, {observation_size}, {action_size}); % 경험 리플레이 메모리 생성

%% 훈련 조건 설정(훈련 중지 조건이 설정되어 있지만 실제로 적용은 안됨)
dnn = [
    featureInputLayer(obsInfo.Dimension(1),'Normalization','none','Name','state') % 관측 공간 입력층 (정규화 없음)
    fullyConnectedLayer(64,'Name','CriticStateFC1') % 64개의 노드로 이루어진 첫 번째 완전 연결층
    reluLayer('Name','CriticRelu1') % ReLU 활성화 함수
    fullyConnectedLayer(64, 'Name','CriticStateFC2') % 64개의 노드로 이루어진 두 번째 완전 연결층
    reluLayer('Name','CriticCommonRelu1') % ReLU 활성화 함수
    fullyConnectedLayer(length(actInfo.Elements),'Name','output')]; % 출력층 (행동별 Q-value 출력)

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
    'MaxEpisodes',10000, ... %원래 10000
    'MaxStepsPerEpisode',500, ...
    'Verbose',false, ...
    'Plots','training-progress',...
    'StopTrainingCriteria','AverageReward',...
    'StopTrainingValue',480);

EpsilonDecay = 0.001;
Epsilon = 1;
EpsilonMin = 0.01;

%% Iteration Block
total_step = 0; % 전체 스텝 수 초기화
cartpole_figure = CartpoleFigure(); % Cartpole 시각화 설정
total_episode_buffer = cell(1, trainOpts.MaxEpisodes); % 전체 에피소드별 경험 버퍼 초기화
unit_episode_buffer = rl.util.ExperienceBuffer(trainOpts.MaxStepsPerEpisode, {observation_size}, {action_size}); % 단일 에피소드 경험 버퍼 초기화

for episodeCt = 1:trainOpts.MaxEpisodes
    reset(unit_episode_buffer); % 에피소드 버퍼 리셋
    reset(env); % 환경 리셋
    CartpoleUpdateFigure(cartpole_figure, env.LoggedSignals.State, cartpole_env); % 시각화 업데이트
    episodeReward = zeros(trainOpts.MaxStepsPerEpisode,1); % 각 스텝별 보상 기록
    tempMSE = 0; % 임시 MSE 초기화

    for stepCt = 1:trainOpts.MaxStepsPerEpisode
        explor_prob = rand(); % 무작위 값 생성
        Obs = env.LoggedSignals.State; % 현재 상태 관측
        
        if explor_prob < Epsilon % Epsilon 탐색: 탐험 또는 이용 여부 결정
            Action =  randsample(actInfo.Elements,1); % 탐험 시 랜덤한 행동 선택
        elseif explor_prob >= Epsilon % 이용 시 최대 Q-value를 가지는 행동 선택
            Action = getAction(critic, {Obs});
        end
        
        % 행동을 환경에 적용하고 다음 상태와 보상, 종료 여부 반환
        [NextObs,Reward,IsDone,LoggedSignals] = step(env, Action);
        exp = {{Obs}, {Action}, Reward, {NextObs}, IsDone}; % 경험 기록
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
            ActionIdxMat = ActionBatch(:, :) == ActionElementArray;

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

        total_step = total_step + 1; % 전체 스텝 수 증가

        % 시각화 업데이트
        CartpoleUpdateFigure(cartpole_figure, NextObs, cartpole_env);

        % 에피소드가 종료되면 반복문 탈출
        if IsDone == 1
            break;
        end
        % 에피소드 최대 스텝 수에 도달하면 반복문 탈출
        if stepCt == trainOpts.MaxStepsPerEpisode
            break;
        end
    end

    % 경험으로부터 평균 MSE 계산
    experienceMSE = mean(tempMSE);



    % 에피소드 종료 후 에피소드 버퍼에서 데이터 추출(stepCT가 끝나면)
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
    ActionIdxMat = ActionBatch(:, :) == ActionElementArray;

    episodeQPrediction = episodeQPrediction(ActionIdxMat);
    episodeQPrediction = reshape(episodeQPrediction, size(episodeTargetQValue));

    error = episodeTargetQValue - episodeQPrediction;  
    error_square = error.^2;
    episodeMSE = mean(error_square);

    % Q-Value의 평균값 계산
    QPredictionAverage = mean(tempQPrediction{1}, 2);
    maxQPredictionAverage = mean(max(tempQPrediction{1}));  % 여기까지 수행

    % 그래프에 데이터 포인트 추가 (보상, MSE, Q-Value 등)
    addpoints(lineQValueAction1, episodeCt, double(QPredictionAverage(1)));
    addpoints(lineQValueAction2, episodeCt, double(QPredictionAverage(2)));
    addpoints(lineMaxQValueAction, episodeCt, double(maxQPredictionAverage));
    addpoints(lineExperienceMSE, episodeCt, double(experienceMSE));
    addpoints(lineEpisodeMSE, episodeCt, double(episodeMSE));

    % 누적 보상 업데이트 및 이동 평균 계산
    episodeCumulativeReward = sum(episodeReward);
    episodeCumulativeRewardVector = cat(2, episodeCumulativeRewardVector, episodeCumulativeReward);
    movingAveReward = movmean(episodeCumulativeRewardVector, aveWindowSize, 2);
    
    % 보상 기준 충족 시 훈련 중단
    if movingAveReward(end) >= trainOpts.StopTrainingValue
        disp(['Training stopped after ', int2str(episodeCt), ' episodes due to reaching the reward threshold of ', num2str(trainOpts.StopTrainingValue)]);
        break;
    end

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
    total_episode_buffer{episodeCt} = unit_episode_buffer; % 에피소드 버퍼 저장
end
save('ReferenceModel.mat', 'critic', 'target_critic');

%% learned model
dat = load('ReferenceModel.mat', 'critic', 'target_critic'); % 학습된 모델 로드
critic = dat.critic; % Critic 네트워크 로드
cartpole_figure = CartpoleFigure(); % CartPole 시각화 설정

% 학습된 모델로 100 에피소드 동안 시뮬레이션
for episodeCt = 1:100
    reset(env); % 환경 리셋
    for stepCt = 1:500
       CartpoleUpdateFigure(cartpole_figure, env.LoggedSignals.State, cartpole_env); % 시각화 업데이트
       Obs = env.LoggedSignals.State; % 현재 상태 관측
       Action = getAction(critic, {Obs}); % Critic 네트워크로 최적 행동 선택
       [NextObs,Reward,IsDone,LoggedSignals] = step(env, Action); % 환경에 행동 적용
       CartpoleUpdateFigure(cartpole_figure, NextObs, cartpole_env); % 시각화 업데이트
       pause(0.02); % 시뮬레이션 속도 조절
   end
end
