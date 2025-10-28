function BatchExperience = batchExperienceCustomBuffer(obj, DataArray)
    % Concatenate 1xBatchSize of raw experience cell array into single
    % cell of Observation, Action, NextObservation, Reward, IsDone
    % Use observation and action specs dimension info for batching.
    
    % e.g: Each observation has dimension d x d x ... x d
    % {d x d x ... x d} x BatchSize => {d x d x ... x d x BatchSize}
    % Reward and IsDone: 1 x BatchSize
    
    if isempty(DataArray)
        BatchExperience = {};
    else
        BatchSize = numel(DataArray);
        
        % for-loop to address multiple input channels
        % e.g. image observation and vector observation
        for i = numel(DataArray{1}{1}):-1:1
            % extract data from 1xN experience cell array
            MiniBatchObservation{i}     = cellfun(@(x) x{1}{i},DataArray,'UniformOutput',false);
            MiniBatchNextObservation{i} = cellfun(@(x) x{4}{i},DataArray,'UniformOutput',false);
            sz = [obj.ObservationDimension{i} BatchSize];
                     
            MiniBatchObservation{i}     = single(cat(numel(sz),MiniBatchObservation{i}{:}));
            MiniBatchNextObservation{i} = single(cat(numel(sz),MiniBatchNextObservation{i}{:}));                                       
        end
        for i = numel(DataArray{1}{2}):-1:1
            % extract data from 1xN experience cell array
            MiniBatchAction{i} = cellfun(@(x) x{2}{i},DataArray,'UniformOutput',false);
            sz = [obj.ActionDimension{i} BatchSize];
            
            MiniBatchAction{i} = single(cat(numel(sz),MiniBatchAction{i}{:}));
        end
        MiniBatchReward = cellfun(@(x) single(x{3}),DataArray);
        MiniBatchIsDone = cellfun(@(x) single(x{5}),DataArray);
        
        BatchExperience = {MiniBatchObservation,MiniBatchAction,MiniBatchReward,MiniBatchNextObservation,MiniBatchIsDone};
    end
end