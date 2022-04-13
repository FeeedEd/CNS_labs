data = load("NARMA10timeseries.mat");

input = data.NARMA10timeseries.input;
y = data.NARMA10timeseries.target;

X_tr = input(1:4000);
X_val = input(4001:5000);
X_final = [X_tr X_val];
X_ts = input(5001:end);

y_tr = y(1:4000);
y_val = y(4001:5000);
y_final = [y_tr y_val];
y_ts = y(5001:end);

%%
scaling = [0.7 1 1.3];
n_r_u = [120 180 600];
rho = [0.4 0.7 1 1.3 1.6];
lambda = [0.01 0.001 0.0001];

%%
reservoir_guesses = 8;

n_u = 1;
training_length = size(X_tr, 2);
validation_length = size(X_val, 2);

tr_e = [];
val_e = [];

washout = 100;

%%
for current_scaling = scaling
for current_n_r_u = n_r_u
for current_rho = rho
for current_lambda = lambda

    fprintf('scaling: %.3f - n_r_u: %d - rho: %.3f - lambda: %.4f\n', current_scaling, current_n_r_u, current_rho, current_lambda);

    temp_error_tr = [];
    temp_error_val = [];
    
    for i=1:reservoir_guesses
        
        %initialization
        Win = current_scaling*(2*rand(current_n_r_u,n_u+1)-1);
        Wrandom = 2*rand(current_n_r_u,current_n_r_u)-1;
        Wr = current_rho * (Wrandom / max(abs(eig(Wrandom))));
        
        %tr
        stateXtr = zeros(1+current_n_r_u+n_u,training_length-washout);
        x = zeros(current_n_r_u,1);
        indexX = 1;
        
        for j=1:training_length
           
            u = cell2mat(X_tr(j));
            x = tanh(Win*[1;u] + Wr*x);
            
            if j > washout
            % riempio la matrice di stati mettendo in ogni colonna il valore
            % attuale dell'input e l'output della tanh
                stateXtr(:,indexX) = [1;u;x];
                indexX = indexX + 1;  
            end
            
        end
        
        stateXtr = [stateXtr;ones(1,size(stateXtr,2))];
        
        Wout = cell2mat(y_tr(washout+1:end))*stateXtr'*inv(stateXtr*stateXtr'+current_lambda*eye(current_n_r_u+3)); 

        y_tr_pred = Wout * stateXtr;
        err_tr = immse(cell2mat(y_tr(washout+1:end)),y_tr_pred);
        temp_error_tr(end+1) = err_tr;
        %end tr
        
        %val
        stateXval = zeros(1+current_n_r_u+n_u,validation_length-washout);
        x = zeros(current_n_r_u,1);
        indexX = 1;

        for j=1:validation_length
           
            u = cell2mat(X_val(j));
            x = tanh(Win*[1;u] + Wr*x);
            
            if j > washout
                stateXval(:,indexX) = [1;u;x];
                indexX = indexX + 1;  
            end
            
        end

        stateXval = [stateXval;ones(1,size(stateXval,2))];
        
        y_val_pred = Wout * stateXval;
        err_val = immse(cell2mat(y_val(washout+1:end)),y_val_pred);
        temp_error_val(end+1) = err_val;
        %end val      
    end
    
    m_tr_e = mean(temp_error_tr);
    tr_e(end+1) = m_tr_e;
    fprintf('Error on training set: %.5f\n', m_tr_e);
    
    m_val_e = mean(temp_error_val);
    val_e(end+1) = m_val_e;
    fprintf('Error on validation set: %.5f\n\n', m_val_e);   
    
end
end
end
end

%%
[value, index] = min(val_e);
[input_scaling, reservoir_units, spectral_radius, regul] = ndgrid(scaling,n_r_u,rho,lambda);
grid = [input_scaling(:) reservoir_units(:) spectral_radius(:) regul(:)];
h1_scaling= grid(index,1);
h2_n_r_u = grid(index,2);
h3_rho = grid(index,3);
h4_lambda = grid(index,4);

best_validation = value;
best_training = tr_e(index);

%%
final_length = size(X_final,2);
test_length = size(X_ts,2);

final_e = [];
ts_e = [];

for cnt=1:reservoir_guesses    
    
    %initialization
    Win = h1_scaling*(2*rand(h2_n_r_u,n_u+1)-1);
    Wrandom = 2*rand(h2_n_r_u,h2_n_r_u)-1;
    Wr = h3_rho * (Wrandom / max(abs(eig(Wrandom))));
    
    %final
    stateXfinal = zeros(1+h2_n_r_u+n_u,final_length-washout);
    x = zeros(h2_n_r_u,1);
    indexX = 1;
    
    for k=1:final_length
           
        u = cell2mat(X_final(k));
        x = tanh(Win*[1;u] + Wr*x);

        if k > washout
            stateXfinal(:,indexX) = [1;u;x];
            indexX = indexX + 1;  
        end   
        
    end

    stateXfinal = [stateXfinal;ones(1,size(stateXfinal,2))];

    Wout = cell2mat(y_final(washout+1:end))*stateXfinal'*inv(stateXfinal*stateXfinal'+current_lambda*eye(h2_n_r_u+3)); 

    y_final_pred = Wout * stateXfinal;
    err_final = immse(cell2mat(y_final(washout+1:end)),y_final_pred);
    final_e(end+1) = err_final;
    %end final

    %test
    stateXts = zeros(1+h2_n_r_u+n_u,test_length-washout);
    x = zeros(h2_n_r_u,1);
    indexX = 1;

    for l=1:test_length

        u = cell2mat(X_ts(l));
        x = tanh(Win*[1;u] + Wr*x);

        if l > washout
            stateXts(:,indexX) = [1;u;x];
            indexX = indexX + 1;  
        end

    end

    stateXts = [stateXts;ones(1,size(stateXts,2))];

    y_ts_pred = Wout * stateXts;
    err_ts = immse(cell2mat(y_ts(washout+1:end)),y_ts_pred);
    ts_e(end+1) = err_ts;
    %end test
end

mse_finaltr = mean(final_e);
fprintf('Final set error: %.5f\n', mse_finaltr);
mse_test = mean(ts_e);
fprintf('Test set error: %.5f\n', mse_test);

%%
figure
plot(cell2mat(y_final(washout+1:end)));
hold 
plot(y_final_pred);
title('Train, GT vs Pred');
legend('GT', 'Pred');
savefig('./images/train');

%%
figure
plot(cell2mat(y_ts(washout+1:end)));
hold
plot(y_ts_pred);
title('Test, GT vs Pred');
legend('GT', 'Pred');
savefig('./images/test');

%%
save('summary.mat','h1_scaling','h2_n_r_u','h3_rho','h4_lambda','Win','Wr','Wout','best_training','best_validation','mse_finaltr','mse_test')
