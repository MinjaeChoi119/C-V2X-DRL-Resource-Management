%% Custom Code Start
clear  % Workspace를 초기화하여 변수들을 삭제
close all  % 열려있는 모든 figure를 닫음
clc  % 명령 창을 깨끗하게 함
%% Parameter Setting (초기설정 및 환경정의)
obsInfo = rlNumericSpec([2, 1]);  % 관측 값을 2x1벡터로
obsInfo.Name = "CartPole Example Observation";  % 관측 값의 이름 설정
obsInfo.Description = "PRR, x";  % 각 관측 값을 PRR(패킷 수신 비율), x(거리)로
actInfo = rlNumericSpec([4, 1]);  % 관측 값을 4x1벡터로
actInfo.Name = "CartPole Action";  % 행동 정보의 이름 설정
actInfo.Description = "Force[N]";  % 행동 정보의 설명 설정
first_decay_episode = true;  % 첫 감쇠 에피소드 여부 설정
last_decay_episode = true;  % 마지막 감쇠 에피소드 여부 설정
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