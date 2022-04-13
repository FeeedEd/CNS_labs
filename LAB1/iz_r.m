a=0.02;  b=1; c=-55;  d=4;

u = [];
w = [];
u(1) = -65;
w(1) = -16;

uFiltered = [];  % memorizzo le u
wFiltered = []; % memorizzo le w
II=[];

tau = 0.5;  % discretizzazione tempo
tspan = 0:tau:400;  % durata esperimento

i=1;

for t=tspan
    
    if (t < 200)
        I=t/25;
    elseif t < 300
        I=0;
    elseif t < 312.5
        I=(t-300)/12.5*4;
    else
        I=0;
    end
  
    u(i+1) = u(i) + tau*(0.04*u(i)^2 + 5*u(i) + 140 - w(i) + I);
    
    if u(i+1)>30
        uFiltered(end+1) = 30;
    else
        uFiltered(end+1) = u(i+1);
    end
    
    w(i+1) = w(i) + tau*a*(b*(u(i+1)+65));
    
    if u(i+1)>30
        u(i+1) = c;
        w(i+1) = w(i+1) + d;
    end
    
    wFiltered(end+1) = w(i+1);
    II(end+1)=I;
    
    i = i+1;
end

%%
plot(tspan,uFiltered,tspan,II*1.5-90);
axis([0 max(tspan) -90 30])  
xlabel('t')
ylabel('u')
hYLabel = get(gca,'YLabel');
set(hYLabel,'rotation',0,'VerticalAlignment','middle')
title('(R) accomodation');
savefig('./images/R_membrane.fig');

%%
plot(uFiltered, wFiltered);
xlabel('u');
ylabel('w');
title('(R) accomodation');
savefig('./images/R_phase.fig');