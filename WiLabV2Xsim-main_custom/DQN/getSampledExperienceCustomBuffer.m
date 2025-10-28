function [dataArray] = getSampledExperienceCustomBuffer(obj,varargin)
    % Get sampled experiences for mini-batch to be created
    % dataArray = getSampledExperience(obj,BatchSize,gamma,n);
    dataArray = obj.Memory(1:obj.Length);
end
