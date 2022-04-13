data = load('lab2_2_data.mat');

p_i(1,:) = data.p0;
p_i(2,:) = data.p1;
p_i(3,:) = data.p2;

%%
d_i(1,:) = distort_image(p_i(1,:), 0.05);
d_i(2,:) = distort_image(p_i(1,:), 0.1);
d_i(3,:) = distort_image(p_i(1,:), 0.25);

d_i(4,:) = distort_image(p_i(2,:), 0.05);
d_i(5,:) = distort_image(p_i(2,:), 0.1);
d_i(6,:) = distort_image(p_i(2,:), 0.25);

d_i(7,:) = distort_image(p_i(3,:), 0.05);
d_i(8,:) = distort_image(p_i(3,:), 0.1);
d_i(9,:) = distort_image(p_i(3,:), 0.25);

%%
N = size(p_i, 2); % # neurons
W = (p_i' * p_i)/N;
for i = 1:size(W, 1)
    W(i, i) = 0;
end
b = ones(N,1)*0.5;

%%
for i=1:size(d_i,1) 
    fprintf('Pattern %d\n', i);
    
    %prendo un input distorto u, appartenente ad uno dei 9 pattern.
    %size(u) = 1x1024
    u = d_i(i,:);
    
    %inizializzo epoche, epsilon (stopping condition)
    epoch = 1;
    epsilon = 1;
    t = 1;
    
    %initialization
    state = (W*u')';
    activation = u;
    
    %E0
    energy = -u*(W*u')/2 -u*b;   %of the whole network
    E = [energy];
    energy_old = energy;

    %first step for reconstruction
    overlap(1) = (p_i(1,:)*u')/N;
    overlap(2) = (p_i(2,:)*u')/N;
    overlap(3) = (p_i(3,:)*u')/N;
    O = [overlap];
    
    while true
        
        energy_old=energy;
        
        %storage phase
        for j = randperm(N)
             
            t = t + 1;
            
            %initialization
            current_state = state(t-1, :);
            current_activation = activation(t-1, :);
            
            %update
            current_state(j) = W(j,:) * activation(t-1, :)' + b(j);
            
            %gestisci pixel bianchi e neri
            if current_state(j) <= 0 
                current_activation(j) = -1;
            else
                current_activation(j) = 1;
            end
            
            %update os
            overlap(1) = (p_i(1,:)*current_activation')/N;
            overlap(2) = (p_i(2,:)*current_activation')/N;
            overlap(3) = (p_i(3,:)*current_activation')/N;
            
            %update e
            energy = -current_activation*(W*current_activation')/2 -current_activation*b;   
            
            %store new values
            state = [state; current_state];
            activation = [activation; current_activation]; 
            E(end+1) = energy;
            O = [O; overlap];
            
        end
        
        fprintf('epoch: %d - energy: %f - energy diff: %f\n', epoch, energy, abs(energy - energy_old));
        epoch = epoch+1;
        
        if abs(energy - energy_old) < epsilon            
            break
        end
        
    end
    
    %plot energy
    figure
    plot(1:t, E);
    xlabel('t');
    ylabel('energy');
    title('Energy');
    savefig(['./images/energyfunction_' num2str(mod(i-1, 9) + 1) '.fig']);
  
    %plot overlap
    %categorizza il pattern attuale per assegnare la distorsione corretta
    if i <= 3 %0
        j = 1;
    elseif i >= 7 %2
        j = 3;
    else %1
        j = 2;
    end
    
    distortion = [0.05 0.1 0.25];
    which_distortion = distortion(mod(i-1, 3) + 1);
    
    figure
    plot(1:t, O(:,1), 1:t, O(:,2), 1:t, O(:,3));
    legend('0 overlap','1 overlap','2 overlap');
    xlabel('t');
    ylabel('overlap');
    title('Overlap');
    savefig(['./images/overlap_' num2str(j-1) '-' num2str(which_distortion) '.fig']);
   
    %plot reconstructed
    original = p_i(j,:);
    retrieved = current_activation(end, :);
    current_overlap = (original*retrieved')/N;
     
    distorted = d_i(i, :);
 
    cnt = 0;
    %metrica: itera per ogni pixel e conta quelli diversi
    for m=1:size(retrieved,2)
        if(retrieved(m)==original(m))
            cnt=cnt+0;
        else
            cnt=cnt+1;
        end
    end
     
    figure
    subplot(1, 3, 1)
    imagesc(reshape(original, 32, 32));
    title('Original');
    subplot(1, 3, 2)
    imagesc(reshape(distorted, 32, 32));
    title('Distorted');
    subplot(1, 3, 3)
    imagesc(reshape(retrieved, 32, 32));
    title('Retrievied');
    %di nuovo e` necessario gestire i pixel 
    if(current_overlap(end)>0)
        sgt = sgtitle(sprintf('Distortion: %0.2f, overlap with %d, overlap = %0.2f and discrepancy: %d', which_distortion, j-1, current_overlap(end), cnt));
    else
        sgt = sgtitle(sprintf('Distortion: %0.2f, overlap with %d, overlap = %0.2f and discrepancy: %d', which_distortion, j-1, current_overlap(end)*(-1), cnt));   
    end
    sgt.FontSize = 8;
    savefig(['./images/reconstruction_' num2str(j-1) '-' num2str(which_distortion) '.fig']);
    
end