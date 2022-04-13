dataset = load('NARMA10timeseries.mat');

X = dataset.NARMA10timeseries.input;
y = dataset.NARMA10timeseries.target;

X_tr = X(1:4000);
X_val = X(4001:5000);
X_final = [X_tr X_val];
X_ts = X(5001:end);

y_tr = y(1:4000);
y_val = y(4001:5000);
y_final = [y_tr y_val];
y_ts = y(5001:end);

epochs = 500;

%%
nh = [40 80];
eta = [0.01 0.001 0.0001];
momentum = [0.1 0.9];
lambda = [0.01 0.001]; %regularization

valEforG = [];

%%

for current_nh = nh
for current_eta = eta
for current_momentum = momentum
for current_lambda = lambda
    
    fprintf('\nnh: %d - eta: %f - momentum: %f - lambda: %f\n',current_nh, current_eta, current_momentum, current_lambda);
    
    srn_net = layrecnet(1, current_nh, 'traingdm');

    srn_net.trainParam.epochs = epochs;
    srn_net.trainParam.lr = current_eta;
    srn_net.trainParam.mc = current_momentum;
    srn_net.performParam.regularization = current_lambda;
    srn_net.divideFcn = 'dividetrain';

    [delayedInput_tr, initialInput_tr, initialStates_tr, delayedTarget_tr] = preparets(srn_net, X_tr, y_tr);

    [delayedInput_val, initialInput_val, initialStates_val, delayedTarget_val] = preparets(srn_net, X_val, y_val);

    [srn_net, tr] = train(srn_net, delayedInput_tr, delayedTarget_tr, initialInput_tr);

    y_tr_pred = srn_net(delayedInput_tr, initialInput_tr);
    error_tr = immse(cell2mat(delayedTarget_tr), cell2mat(y_tr_pred));

    y_val_pred = srn_net(delayedInput_val, initialInput_val);
    val_e = immse(cell2mat(delayedTarget_val), cell2mat(y_val_pred));
    valEforG(end+1) = val_e;
    
    fprintf('Training error: %f,\t - Validation error: %f\n', error_tr, val_e);

end
end
end
end

%%
[value, index] = min(valEforG);
[N, E, M, L] = ndgrid(nh,eta,momentum,lambda);
grid = [N(:) E(:) M(:) L(:)];
N1 = grid(index,1);
E1 = grid(index,2);
M1 = grid(index,3);
L1 = grid(index,4);
best_validation = value;
best_training = valEforG(index);

%%
srs_net = layrecnet(1, N1, 'traingdm');
srn_net.trainParam.epochs = epochs;
srn_net.trainParam.lr = E1;
srn_net.trainParam.mc = M1;
srn_net.performParam.regularization = L1;
srn_net.divideFcn = 'dividetrain';

[delayedInput_finaltr, initialInput_finaltr, initialStates_finaltr, delayedTarget_finaltr] = preparets(srn_net, X_final, y_final);

[delayedInput_ts, initialInput_ts, initialStates_ts, delayedTarget_ts] = preparets(srn_net, X_ts, y_ts);

[srn_net, tr_final] = train(srn_net, delayedInput_finaltr, delayedTarget_finaltr, initialInput_finaltr);

y_finaltr_pred = srn_net(delayedInput_finaltr, initialInput_finaltr);
error_finaltr = immse(cell2mat(delayedTarget_finaltr), cell2mat(y_finaltr_pred));

y_ts_pred = srn_net(delayedInput_ts, initialInput_ts);
error_ts = immse(cell2mat(delayedTarget_ts), cell2mat(y_ts_pred));

fprintf('Final TR error: %f,\t - Final TS error: %f\n', error_finaltr, error_ts);

%%
figure
plotperform(tr_final);
title('Learning Curve');
xlabel('epochs');
ylabel('error');
savefig('./images/srs_learning_curve');

%%
figure
title('Train, Target vs Output');
plot(cell2mat(y_final));
hold
plot(cell2mat(y_finaltr_pred));
legend('GT', 'Pred');
savefig('./images/srs_train');

%%
figure
title('Test, Target vs Output');
plot(cell2mat(y_ts));
hold
plot(cell2mat(y_ts_pred));
legend('GT', 'Pred');
savefig('./images/srs_test');

%%
save('srn_summary.mat', 'N1', 'E1', 'M1', 'L1', 'best_training', 'best_validation', 'error_finaltr', 'error_ts')
