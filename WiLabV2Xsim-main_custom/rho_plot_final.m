close all;    % 모든 열린 그림 창 닫기
clear;        % 변수 초기화
clc;          % 커맨드 창 정리

% 폴더 경로 설정 (사용자 경로로 수정)
base_folder = 'Output\raw200';
folders = {'CRlimit_00031','CRlimit_00061','CRlimit_1000','CRlimit_ETSI','CRlimit_final_policy_90'};

% 색상 설정
color_order = lines(length(folders));

% 차량 밀도 값 지정
specified_densities = [100:10:160, 162:2:198, 200:10:360];
%specified_densities = [100:10:200, 202:2:238, 240:10:360];
%specified_densities = [100:10:170, 172:2:178, 192:2:198, 200:10:360];

%% RHO - PDR 그래프 그리기
figure;
hold on;

% 목표 PDR 값
target_pdr = 0.9;
%target_pdr = 0.85;

% Upper bound와 Lower bound를 저장할 변수 초기화
upper_bound_x = [];
upper_bound_y = [];
lower_bound_x = [];
lower_bound_y = [];

for i = 1:length(folders)
    folder_path = fullfile(base_folder, folders{i});
    file_path = fullfile(folder_path, 'Merged_DATAvalues.xlsx');
    
    if isfile(file_path)
        data = readmatrix(file_path);
        
        % 차량 밀도 필터링
        density_column = data(:, 1);
        filtered_data = data(ismember(density_column, specified_densities), :);
        
        if ~isempty(filtered_data)
            x = filtered_data(:, 1); % x축 데이터 (차량 밀도)
            y = filtered_data(:, 4); % y축 데이터 (PDR)
            
            % 폴더별 스타일로 데이터 그리기
            if strcmp(folders{i}, 'CRlimit_1000')
                plot(x, y, 'k--', 'DisplayName', 'DCC not applied', 'LineWidth', 1.5);
                upper_bound_x = x;
                upper_bound_y = y;
            elseif strcmp(folders{i}, 'CRlimit_0003')
                plot(x, y, 'k-.', 'DisplayName', 'Lower bound', 'LineWidth', 1.5);
                lower_bound_x = x;
                lower_bound_y = y;
            elseif strcmp(folders{i}, 'CRlimit_ETSI')
                plot(x, y, 'r-', 'DisplayName', 'ETSI', 'LineWidth', 1.5);
            elseif strcmp(folders{i}, 'CRlimit_final_policy_85')
                plot(x, y, 'b-', 'DisplayName', 'DQN (85%)', 'LineWidth', 2);
            end
        else
            warning(['지정된 차량 밀도 값에 일치하는 데이터가 없습니다: ', file_path]);
        end
    else
        warning(['파일이 존재하지 않습니다: ', file_path]);
    end
end

% 목표 QoS 구간을 채색 (Upper bound와 Lower bound가 target PDR과 만나는 지점 계산)
if ~isempty(upper_bound_x) && ~isempty(lower_bound_x)
    % 목표 PDR과 upper bound의 교차점 계산
    x_qos_start = interp1(upper_bound_y, upper_bound_x, target_pdr, 'linear', 'extrap');
    % 목표 PDR과 lower bound의 교차점 계산
    x_qos_end = interp1(lower_bound_y, lower_bound_x, target_pdr, 'linear', 'extrap');
    
    % 교차점이 유효한 범위 내에 있는지 확인
    if ~isnan(x_qos_start) && ~isnan(x_qos_end) && (x_qos_start <= x_qos_end)
        y_qos = [0.65, 1.0];
        fill([x_qos_start, x_qos_end, x_qos_end, x_qos_start], [y_qos(1), y_qos(1), y_qos(2), y_qos(2)], 'c', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % QoS 구간 텍스트 추가 (QoS 구간의 중간에 Y축 상단에 위치)
        text((x_qos_start + x_qos_end) / 2, 0.97, 'Target QoS Section', 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'blue');
    end
end

% 목표 PDR 라인 표시
yline(target_pdr, 'b', 'Target PDR Line', 'LineWidth', 1.5);

% 그래프 설정
xlim([100, 250]); %90
%xlim([100, 300]); %85
ylim([0.75, 1.0]);%90
%ylim([0.65, 1.0]); %85
xlabel('Vehicle density ρ [veh/km]');
ylabel('Average PDR');

% Legend에서 필요한 항목만 포함 (Lower bound, Upper bound, ETSI, DQN)
legend_entries = findobj(gca, '-regexp', 'DisplayName', '^(Lower bound|DCC not applied|ETSI|DQN \(85%\))$');
legend(legend_entries, 'Location', 'southwest');

% 그리드 설정
grid on; % 그리드 활성화

hold off;

filename = 'plot_image.png'; % 파일명과 형식 설정 (PNG로 저장)
exportgraphics(gca, filename, 'Resolution', 300);
