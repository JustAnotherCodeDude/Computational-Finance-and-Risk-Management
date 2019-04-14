function [callMC_European_Price_1_step, putMC_European_Price_1_step] = MC_european_price(S0, K, T, r, mu, sigma, stepNum, numPaths)

% Simulate asset paths for the geometric random walk
S = GRWPaths(S0, mu, sigma, T, stepNum, numPaths);

% Calculate the payoff for each path for a Put
PutPayoffT = max(K-(S(end,:)),0);

% Calculate the payoff for each path for a Call
CallPayoffT = max((S(end,:))-K,0);

% Discount back
putMC_European_Price_1_step = mean(PutPayoffT)*exp(-r*T);
callMC_European_Price_1_step = mean(CallPayoffT)*exp(-r*T);
end
