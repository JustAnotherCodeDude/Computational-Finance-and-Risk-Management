clc;
clear all;
format long

% Pricing a European option using Black-Scholes formula and Monte Carlo simulations
% Pricing a Barrier option using Monte Carlo simulations

S0 = 100;     % spot price of the underlying stock today
K = 105;      % strike at expiry
mu = 0.05;    % expected return
sigma = 0.2;  % volatility
r = 0.05;     % risk-free rate
T = 1.0;      % years to expiry
Sb = 110;     % barrier


% Implement your Black-Scholes pricing formula
[call_BS_European_Price, putBS_European_Price] = BS_european_price(S0, K, T, r, sigma);


numSteps = [1 12];
numPaths = [10000:11000];

ideal_Step = [];
ideal_Path = [];

for i = 1:length(numSteps)
    Step = numSteps(i);
    for j = 1:length(numPaths)
        Path = numPaths(j);
        [callMC_European_Price_multi_step, putMC_European_Price_multi_step] = MC_european_price(S0, K, T, r, mu, sigma, Step, Path);
        if (abs(callMC_European_Price_multi_step-call_BS_European_Price)<0.01) & (abs(putMC_European_Price_multi_step-putBS_European_Price)<0.01)
            ideal_Step = [ideal_Step Step]
            ideal_Path = [ideal_Path Path]
            disp(['Black-Scholes price of an European call option is ',num2str(call_BS_European_Price)])
            disp(['Black-Scholes price of an European put option is ',num2str(putBS_European_Price)])
            disp(['MC price of an European call option is ',num2str(callMC_European_Price_multi_step)])
            disp(['MC price of an European put option is ',num2str(putMC_European_Price_multi_step)])
        end
    end
end



