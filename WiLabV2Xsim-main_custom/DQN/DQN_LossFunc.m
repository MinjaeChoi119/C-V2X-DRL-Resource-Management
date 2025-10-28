function Loss = DQN_LossFunc(QPrediction,LossInput)
    % Deep Q-Learning loss.
    %   QPrediction: output from model
    %   LossInput: struct contains type of Q representation, logical action
    %   indication matrix and target q value matrix
%     disp(LossInput.TotalStep);
    batchSize = LossInput.BatchSize;
    Z = repmat(LossInput.ActInfo.Elements,1,batchSize);
    actionIndicationMatrix = (LossInput.ActionBatch{1}(:,:)*1000) == (Z*1000);
    QPrediction = QPrediction{1};
    QPrediction = QPrediction(actionIndicationMatrix);
%     Loss = mse(QPrediction, reshape(LossInput.TargetQValues,size(QPrediction)),'DataFormat','CB');
    
    error = (QPrediction - reshape(LossInput.TargetQValues,size(QPrediction)));
%     error(error > 10) = 10;
%     error(error < -10) = -10;
    error_square = error.^2;
    Loss = mean(error_square);
%     disp(Loss)
end