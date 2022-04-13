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

epochs = 800;

%%
nh = [80 120];
eta = [0.01 0.001 0.0001];
momentum = [0.1 0.9];
lambda = [0.01 0.001]; %regularization
window = [5 10];

valEforG = [];

%%
for current_nh = nh
for current_eta = eta
for current_momentum = momentum
for current_lambda = lambda
for current_window = window

    fprintf('\nnh: %d - eta: %f - alpha: %f - lambda: %f - window: %d\n',current_nh, current_eta, current_momentum, current_lambda, current_window);
    
    idnn_net = timedelaynet(0:current_window, nh, 'traingdm');
    
    idnn_net.trainParam.epochs = epochs;
    idnn_net.trainParam.lr = current_eta;
    idnn_net.trainParam.mc = current_momentum;
    idnn_net.performParam.regularization = current_lambda;
    idnn_net.divideFcn = 'dividetrain';
    
    [delayedInput_tr, initialInput_tr, initialStates_tr, delayedTarget_tr] = preparets(idnn_net, X_tr, y_tr);

    [delayedInput_val, initialInput_val, initialStates_val, delayedTarget_val] = preparets(idnn_net, X_val, y_val);
    
    [idnn_net, tr] = train(idnn_net, delayedInput_tr, delayedTarget_tr, initialInput_tr);
    
    y_tr_pred = idnn_net(delayedInput_tr, initialInput_tr);
    error_tr = immse(cell2mat(delayedTarget_tr), cell2mat(y_tr_pred));

    y_val_pred = idnn_net(delayedInput_val, initialInput_val);
    val_e = immse(cell2mat(delayedTarget_val), cell2mat(y_val_pred));
    valEforG(end+1) = val_e;
    
    fprintf('Training error: %f,\t - Validation error: %f\n', error_tr, val_e);
    
end
end
end
end
end

%%
[value, index] = min(valEforG);
[N, E, M, L, W] = ndgrid(nh,eta,momentum,lambda, window);
grid = [N(:) E(:) M(:) L(:) W(:)];
N1 = grid(index,1);
E1 = grid(index,2);
M1 = grid(index,3);
L1 = grid(index,4);
W1 = grid(index,5);
best_validation = value;
best_training = valEforG(index);

%%
idnn_net = timedelaynet(0:W1, N1, 'traingdm');
idnn_net.trainParam.epochs = epochs;
idnn_net.trainParam.lr = E1;
idnn_net.trainParam.mc = M1;
idnn_net.performParam.regularization = L1;
idnn_net.divideFcn = 'dividetrain';

[delayedInput_finaltr, initialInput_finaltr, initialStates_finaltr, delayedTarget_finaltr] = preparets(idnn_net, X_final, y_final);

[delayedInput_ts, initialInput_ts, initialStates_ts, delayedTarget_ts] = preparets(idnn_net, X_ts, y_ts);

[idnn_net, tr_final] = train(idnn_net, delayedInput_finaltr, delayedTarget_finaltr, initialInput_finaltr);

y_finaltr_pred = idnn_net(delayedInput_finaltr, initialInput_finaltr);
error_finaltr = immse(cell2mat(delayedTarget_finaltr), cell2mat(y_finaltr_pred));

y_ts_pred = idnn_net(delayedInput_ts, initialInput_ts);
error_ts = immse(cell2mat(delayedTarget_ts), cell2mat(y_ts_pred));

fprintf('- final TR error: %f,\t - final TS error: %f\n', error_finaltr, error_ts);

%%
figure
plotperform(tr_final);
title('Learning Curve');
xlabel('epochs');
ylabel('error');
savefig('./images/idnn_learning_curve');

%%
figure
title('Train, Target vs Output');
plot(cell2mat(y_final));
hold
plot(cell2mat(y_finaltr_pred));
legend('GT', 'Pred');
savefig('./images/idnn_train');

%%
figure
title('Test, Target vs Output');
plot(cell2mat(y_ts));
hold
plot(cell2mat(y_ts_pred));
legend('GT', 'Pred');
savefig('./images/idnn_test');

%%
save('idnn_summary.mat', 'N1', 'E1', 'M1', 'L1', 'W1', 'best_training', 'best_validation', 'error_finaltr', 'error_ts')
