a=-0.026;  b=-1; c=-45;  d=-2;

u = [];
w = [];
u(1) = -64;
w(1) = b*u(1);

uFiltered = [];  % memorizzo le u
wFiltered = []; % memorizzo le w

tau = 0.5;  % discretizzazione tempo
tspan = 0:tau:250;  % durata esperimento

i=1;

for t=tspan
    
    if (t < 50) | (t>250)
        I=80;
    else
        I=75;
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
plot(tspan,uFiltered,[0 50 50 250 250 max(tspan)],-80+[0 0 -10 -10 0 0]);
axis([0 max(tspan) -90 30]) 
xlabel('t')
ylabel('u')
hYLabel = get(gca,'YLabel');
set(hYLabel,'rotation',0,'VerticalAlignment','middle')
title('(T) inhibition-induced bursting');
savefig('./images/T_membrane.fig');

%%
plot(uFiltered, wFiltered);
xlabel('u');
ylabel('w');
title('(T) inhibition-induced bursting');
savefig('./images/T_phase.fig');