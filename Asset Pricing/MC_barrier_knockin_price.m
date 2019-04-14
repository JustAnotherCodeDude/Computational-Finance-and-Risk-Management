function [callMC_Barrier_Knockin_Price_1_step, putMC_Barrier_Knockin_Price_1_step] = ...
    MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, numSteps, numPaths);

% Simulate asset paths for the geometric random walk
S = GRWPaths(S0, mu, sigma, T, numSteps, numPaths);

% Knock-In Option, if asset price crosses barrier than we have standard
% european Option

% Number of Rows in S
m = length(S(1,:));

% Loop to create new S, S_barr which only has asset price if barrier is
% crossed

S_barr = [];

for i = 1:m
    if sum(S(:,i) >= Sb) == 0
        S(:,i) = 0;
    else
        S_barr(:,end+1) = S(:,i);
    end
end

if all(S_barr(:) == 0)
    PutPayoffT = 0;
    CallPayoffT = 0;
else
    CallPayoffT = max((S_barr(end,:))- K,0);
    PutPayoffT = max(K-(S_barr(end,:)),0);
end

% Discount back
putMC_Barrier_Knockin_Price_1_step = mean(PutPayoffT)*exp(-r*T);
callMC_Barrier_Knockin_Price_1_step = mean(CallPayoffT)*exp(-r*T);

end


