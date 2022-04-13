table = readtable('lab2_1_data.csv');
data = table2array(table);

epochs = 1000;
eta = 0.0005;

dataLength = size(data,2);
w = -1 + 2.*rand(2,1);

weights = [];

wNormalized = zeros(1, epochs);
wUpdated = zeros(2, epochs);


% the stopping condition is the number of the epochs
for iteration=1:epochs
   
    wOld = w;
    
    % array of numbers from 1 to 100 in a random order
    shuffle = randperm(dataLength);
    
    for pattern=1:dataLength
       
        % get a random entry of the data
        randomInputU = data(:, shuffle(pattern)); 
        
        % compute the output
        v = w' * randomInputU;
        % update the weights 
        w = w + eta*(v*randomInputU);
        
    end
    
    err = norm(w - wOld);
    wNormalized(iteration) = norm(w);
    
    wUpdated(:,iteration) = w;
   
end

% correlation matrix of the input
Q = data*data';

% eigenvalues of the correlation matrix
% [V,D] = eig(A) returns diagonal matrix D of eigenvalues and matrix V whose
% columns are the corresponding right eigenvectors, so that A*V = V*D.
[V, D] = eig(Q);

%%
plotv(V(:,2));
hold on
plotv(wUpdated(:,end)/norm(w));
hold on
scatter(data(1,:), data(2,:));
legend('eigenvector','weight','scatter');
savefig('./images/base_scattereig.fig');

%%
plot(wUpdated(1,:));
xlabel('Epochs')
ylabel('w1');
savefig('./images/base_w1.fig');

%%
plot(wUpdated(2,:));
xlabel('Epochs')
ylabel('w2');
savefig('./images/base_w2.fig');

%%
plot(wNormalized);
xlabel('Epochs')
ylabel('wNormalized');
savefig('./images/base_wnorm.fig');

%%
save('summary.mat', 'wUpdated');
