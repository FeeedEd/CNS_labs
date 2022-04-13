a=0.2;  b=0.26; c=-65;  d=0;

u = [];
w = [];
u(1) = -65;
w(1) = b*u(1);

uFiltered = [];  % memorizzo le u
wFiltered = []; % memorizzo le w

tau = 0.25;  % discretizzazione tempo
tspan = 0:tau:300;  % durata esperimento
T1 = tspan(end)/10;  % dopo quanto forniamo corrente 

i=1;

for t=tspan
    
     if (t>T1) 
        I= -0.7 + (0.015*(t-T1)); 
% Action potentials are generated in a certain frequency band that is
% relatively insensitive to changes in the strength of the applied current
    else
        I= -1;
    end
  
    u(i+1) = u(i) + tau*(0.04*u(i)^2 + 5*u(i) + 140 - w(i) + I);
    
    if u(i+1)>30
        uFiltered(end+1) = 30;
    else
        uFiltered(end+1) = u(i+1);
    end
    
    w(i+1) = w(i) + tau*a*(b*u(i+1) - w(i));
    
    if u(i+1)>30
        u(i+1) = c;
        w(i+1) = w(i+1) + d;
    end
    
    wFiltered(end+1) = w(i+1);
    
    i = i+1;
end

%%
plot(tspan,uFiltered,[0 T1 max(tspan) max(tspan)],-90+[0 0 20 0]); t
axis([0 max(tspan) -90 30])  
xlabel('t')
ylabel('u')
hYLabel = get(gca,'YLabel');
set(hYLabel,'rotation',0,'VerticalAlignment','middle')
title('(H) class 2 excitable');
savefig('./images/H_membrane.fig');

%%
plot(uFiltered, wFiltered);
xlabel('u');
ylabel('w');
title('(H) class 2 excitable');
savefig('./images/H_phase.fig');