clear all;
clc
format long;

Nout  = 100000; % number of out-of-sample scenarios
Nin   = 5000;   % number of in-sample scenarios
Ns    = 5;      % number of idiosyncratic scenarios for each systemic

C = 8;          % number of credit states

% Filename to save out-of-sample scenarios
filename_save_out  = 'scen_out';

% Read and parse instrument data
instr_data = dlmread('instrum_data.csv', ',');
instr_id   = instr_data(:,1);           % ID
driver     = instr_data(:,2);           % credit driver
beta       = instr_data(:,3);           % beta (sensitivity to credit driver)
recov_rate = instr_data(:,4);           % expected recovery rate
value      = instr_data(:,5);           % value
prob       = instr_data(:,6:6+C-1);     % credit-state migration probabilities (default to A)
exposure   = instr_data(:,6+C:6+2*C-1); % credit-state migration exposures (default to A)
retn       = instr_data(:,6+2*C);       % market returns

K = size(instr_data, 1); % number of  counterparties

% Read matrix of correlations for credit drivers
rho = dlmread('credit_driver_corr.csv', '\t');
sqrt_rho = (chol(rho))'; % Cholesky decomp of rho (for generating correlated Normal random numbers)

disp('======= Credit Risk Model with Credit-State Migrations =======')
disp('============== Monte Carlo Scenario Generation ===============')
disp(' ')
disp(' ')
disp([' Number of out-of-sample Monte Carlo scenarios = ' int2str(Nout)])
disp([' Number of in-sample Monte Carlo scenarios = ' int2str(Nin)])
disp([' Number of counterparties = ' int2str(K)])
disp(' ')

% Find credit-state for each counterparty
% 8 = AAA, 7 = AA, 6 = A, 5 = BBB, 4 = BB, 3 = B, 2 = CCC, 1 = default
[Ltemp, CS] = max(prob, [], 2);
clear Ltemp

% Account for default recoveries
exposure(:, 1) = (1-recov_rate) .* exposure(:, 1);

% Compute credit-state boundaries
CS_Bdry = norminv( cumsum(prob(:,1:C-1), 2) );

% -------- Insert your code here -------- %

if(~exist('scenarios_out.mat','file'))
    
    % -------- Insert your code here -------- %
z_true = normrnd(0,1,Nout,1);

    for s = 1:Nout
        % -------- Insert your code here -------- %
        y_true = normrnd(0,1,50,1);
        y_sr(s,:) = (sqrt_rho * y_true)';
        for i = 1:K
            W = beta(i) * y_sr(s,driver(i)) + sqrt(1-beta(i)^2) * z_true(s,1);
            indi = find(sort([CS_Bdry(i,:),W]) == W);
            Losses_out(s,i) = exposure(i,indi);  
        end
        
    end
    % Calculated out-of-sample losses (100000 x 100)
    % Losses_out

    save('scenarios_out', 'Losses_out')
else
    load('scenarios_out', 'Losses_out')
end

% Normal approximation computed from out-of-sample scenarios
mu_l = mean(Losses_out)';
var_l = cov(Losses_out);

% Compute portfolio weights
portf_v = sum(value);     % portfolio value
w0{1} = value / portf_v;  % asset weights (portfolio 1)
w0{2} = ones(K, 1) / K;   % asset weights (portfolio 2)
x0{1} = (portf_v ./ value) .* w0{1};  % asset units (portfolio 1)
x0{2} = (portf_v ./ value) .* w0{2};  % asset units (portfolio 2)

% Quantile levels (99%, 99.9%)
alphas = [0.99 0.999];

% Compute VaR and CVaR (non-Normal and Normal) for 100000 scenarios
for(portN = 1:2)
    for(q=1:length(alphas))
        alf = alphas(q);
        % -------- Insert your code here -------- %
        
        x = x0{portN}; % asset units
        w = w0{portN}; % asset weights
        Losses_port = sort(Losses_out * x);
        mu_port = mean(Losses_port);
        std_port = std(Losses_port);
        
        
        VaRout(portN,q)  = Losses_port(ceil(Nout*alf));
        VaRinN(portN,q)  = mu_port + norminv(alf,0,1) * std_port;
        CVaRout(portN,q) = (1/(Nout*(1-alf))) * ( (ceil(Nout*alf)-Nout*alf) * VaRout(portN,q) + sum(Losses_port(ceil(Nout*alf)+1:Nout)) );
        CVaRinN(portN,q) = mu_port + (normpdf(norminv(alf,0,1))/(1-alf))*std_port;
        % -------- Insert your code here -------- %        
 end
end


% Perform 100 trials
N_trials = 100;

for(tr=1:N_trials)
    
    % Monte Carlo approximation 1

    % -------- Insert your code here -------- %
    
    for s = 1:ceil(Nin/Ns) % systemic scenarios
        % -------- Insert your code here -------- %
        
        y_MC1 = normrnd(0,1,50,1);
        y_MC1_100(s,:) = (sqrt_rho * y_MC1)';
        z_MC1_100 = normrnd(0,1,5,1);
    
        for si = 1:Ns % idiosyncratic scenarios for each systemic
            % -------- Insert your code here -------- %
            
            for i = 1:K
                W_MC1 = beta(i) * y_MC1_100(s,driver(i)) + sqrt(1-beta(i)^2) * z_MC1_100(si);
                indi_MC1 = find(sort([CS_Bdry(i,:),W_MC1]) == W_MC1);
                Losses_inMC1(Ns*(s-1)+si,i) = exposure(i,indi_MC1);
            end
        end
    end
    
    % Calculated losses for MC1 approximation (5000 x 100)
    % Losses_inMC1
    
    % Monte Carlo approximation 2
    
    % -------- Insert your code here -------- %
    
    for s = 1:Nin % systemic scenarios (1 idiosyncratic scenario for each systemic)
        % -------- Insert your code here -------- %
        y_MC2 = normrnd(0,1,50,1);
        y_MC2_5000(s,:) = (sqrt_rho * y_MC2)';
        z_MC2_5000 = normrnd(0,1);
        for i = 1:K
            W_MC2 = beta(i) * y_MC2_5000(s,driver(i)) + sqrt(1-beta(i)^2) * z_MC2_5000;
            indi_MC2 = find(sort([CS_Bdry(i,:),W_MC2]) == W_MC2);
            Losses_inMC2(s,i) = exposure(i,indi_MC2);
        end
        
    end
        
    % Calculated losses for MC2 approximation (5000 x 100)
    % Losses_inMC2
    
    % Compute VaR and CVaR
    for(portN = 1:2)
        for(q=1:length(alphas))
            alf = alphas(q);
            % -------- Insert your code here -------- %   
            x = x0{portN};
            w = w0{portN};
            % Compute portfolio loss 
            portf_loss_inMC1 = sort(Losses_inMC1 * x);
            portf_loss_inMC2 = sort(Losses_inMC2 * x);
            mu_MCl = mean(Losses_inMC1)';
            var_MCl = cov(Losses_inMC1);
            mu_MC2 = mean(Losses_inMC2)';
            var_MC2 = cov(Losses_inMC2);
            % Compute portfolio mean loss mu_p_MC1 and portfolio standard deviation of losses sigma_p_MC1
            mu_p_MC1 = mean(portf_loss_inMC1);
            sigma_p_MC1 = std(portf_loss_inMC1);
            % Compute portfolio mean loss mu_p_MC2 and portfolio standard deviation of losses sigma_p_MC2
            mu_p_MC2 = mean(portf_loss_inMC2);
            sigma_p_MC2 = std(portf_loss_inMC2);
            % Compute VaR and CVaR for the current trial
            VaRinMC1{portN,q}(tr) = portf_loss_inMC1(ceil(Nin*alf));
            VaRinMC2{portN,q}(tr) = portf_loss_inMC2(ceil(Nin*alf));
            VaRinN1{portN,q}(tr) = mu_p_MC1 + norminv(alf,0,1)*sigma_p_MC1;
            VaRinN2{portN,q}(tr) = mu_p_MC2 + norminv(alf,0,1)*sigma_p_MC2;
            CVaRinMC1{portN,q}(tr) = (1/(Nin*(1-alf))) * ( (ceil(Nin*alf)-Nin*alf) * VaRinMC1{portN,q}(tr) + sum(portf_loss_inMC1(ceil(Nin*alf)+1:Nin)) );
            CVaRinMC2{portN,q}(tr) = (1/(Nin*(1-alf))) * ( (ceil(Nin*alf)-Nin*alf) * VaRinMC2{portN,q}(tr) + sum(portf_loss_inMC2(ceil(Nin*alf)+1:Nin)) );
            CVaRinN1{portN,q}(tr) = mu_p_MC1 + (normpdf(norminv(alf,0,1))/(1-alf))*sigma_p_MC1;
            CVaRinN2{portN,q}(tr) = mu_p_MC2 + (normpdf(norminv(alf,0,1))/(1-alf))*sigma_p_MC2;
            % -------- Insert your code here -------- %
        end
    end
end


% Display portfolio VaR and CVaR
for(portN = 1:2)
fprintf('\nPortfolio %d:\n\n', portN)    
 for(q=1:length(alphas))
    alf = alphas(q);
    fprintf('Out-of-sample: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, VaRout(portN,q), 100*alf, CVaRout(portN,q))
    fprintf('In-sample MC1: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, mean(VaRinMC1{portN,q}), 100*alf, mean(CVaRinMC1{portN,q}))
    fprintf('In-sample MC2: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, mean(VaRinMC2{portN,q}), 100*alf, mean(CVaRinMC2{portN,q}))
    fprintf(' In-sample No: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, VaRinN(portN,q), 100*alf, CVaRinN(portN,q))
    fprintf(' In-sample N1: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, mean(VaRinN1{portN,q}), 100*alf, mean(CVaRinN1{portN,q}))
    fprintf(' In-sample N2: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n\n', 100*alf, mean(VaRinN2{portN,q}), 100*alf, mean(CVaRinN2{portN,q}))
 end
end

% Plot results
figure(1);
% -------- Insert your code here -------- %
[frequencyCounts, binLocations] = hist(Losses_out * x0{1},50);
bar(binLocations, frequencyCounts);
hold on;
% 99% Out-of-sample VaR
line([VaRout(1,1) VaRout(1,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99% VaR MC1 VaR
line([mean(VaRinMC1{1,1}) mean(VaRinMC1{1,1})], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99% VaR MC2 VaR
line([mean(VaRinMC2{1,1}) mean(VaRinMC2{1,1})], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

normf = ( 1/(std(Losses_out * x0{1})*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(Losses_out * x0{1}))/std(Losses_out * x0{1})).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations,normf,'r','LineWidth',1);
hold on;

text(0.98*VaRout(1,1), max(frequencyCounts)/1.9, {'VaR','99%'})
text(1.5*mean(VaRinMC1{1,1}), max(frequencyCounts)/1.9, {'MC1_VaR','99%'})
text(2*mean(VaRinMC2{1,1}), max(frequencyCounts)/1.9, {'MC2_VaR','99%'})

hold off;
title('Portfolio 1 out-of-sample VS In-sample')
xlabel('Portfolio 1 Loss')
ylabel('Frequency')



figure(2);
% -------- Insert your code here -------- %
[frequencyCounts, binLocations] = hist(Losses_out * x0{2},50);
bar(binLocations, frequencyCounts);
hold on;
% 99% Out-of-sample VaR
line([VaRout(2,1) VaRout(2,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99% VaR MC1 VaR
line([mean(VaRinMC1{2,1}) mean(VaRinMC1{2,1})], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99% VaR MC2 VaR
line([mean(VaRinMC2{2,1}) mean(VaRinMC2{2,1})], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

normf = ( 1/(std(Losses_out * x0{2})*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(Losses_out * x0{2}))/std(Losses_out * x0{2})).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations,normf,'r','LineWidth',1);
hold on;

text(0.98*VaRout(2,1), max(frequencyCounts)/1.9, {'VaR','99%'})
text(1.5*mean(VaRinMC1{2,1}), max(frequencyCounts)/1.9, {'MC1_VaR','99%'})
text(2*mean(VaRinMC1{2,1}), max(frequencyCounts)/1.9, {'MC2_VaR','99%'})

hold off;
title('Portfolio 2 out-of-sample VS In-sample')
xlabel('Portfolio 2 Loss')
ylabel('Frequency')



figure(3);
% -------- Insert your code here -------- %
[frequencyCounts, binLocations] = hist(Losses_out * x0{1},100);
bar(binLocations, frequencyCounts);
hold on;
% 99% Out-of-sample VaRn
line([VaRout(1,1) VaRout(1,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99% VaRinN
line([VaRinN(1,1) VaRinN(1,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99%  VaRinN1
line([mean(VaRinN1{1,1}) mean(VaRinN1{1,1})], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99%  VaRinN2
line([mean(VaRinN2{1,1}) mean(VaRinN2{1,1})], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

normf = ( 1/(std(Losses_out * x0{1})*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(Losses_out * x0{1}))/std(Losses_out * x0{1})).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations,normf,'r','LineWidth',1);
hold on;

text(1.3*VaRout(1,1), max(frequencyCounts)/1.9, {'VaRout','99%'})
text(0.7*VaRinN(1,1), max(frequencyCounts)/1.9, {'VaRinN','99%'})
text(1.1*mean(VaRinN1{1,1}), max(frequencyCounts)/1.9, {'VaRinN1','99%'})
text(1.3*mean(VaRinN2{1,1}), max(frequencyCounts)/1.9, {'VaRinN2','99%'})

hold off;
title('Portfolio 1 out-of-sample VS normal')
xlabel('Portfolio 1 Loss')
ylabel('Frequency')


figure(4);
% -------- Insert your code here -------- %
[frequencyCounts, binLocations] = hist(Losses_out * x0{2},100);
bar(binLocations, frequencyCounts);
hold on;
% 99% Out-of-sample VaRn
line([VaRout(2,1) VaRout(2,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99% VaRinN
line([VaRinN(2,1) VaRinN(2,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99%  VaRinN1
line([mean(VaRinN1{2,1}) mean(VaRinN1{2,1})], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99%  VaRinN2
line([mean(VaRinN2{2,1}) mean(VaRinN2{2,1})], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

normf = ( 1/(std(Losses_out * x0{2})*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(Losses_out * x0{2}))/std(Losses_out * x0{2})).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations,normf,'r','LineWidth',1);
hold on;

text(1.3*VaRout(2,1), max(frequencyCounts)/1.9, {'VaRout','99%'})
text(0.7*VaRinN(2,1), max(frequencyCounts)/1.9, {'VaRinN','99%'})
text(1.1*mean(VaRinN1{2,1}), max(frequencyCounts)/1.9, {'VaRinN1','99%'})
text(1.3*mean(VaRinN2{2,1}), max(frequencyCounts)/1.9, {'VaRinN2','99%'})

hold off;
title('Portfolio 2 out-of-sample VS normal')
xlabel('Portfolio 2 Loss')
ylabel('Frequency')

figure(5);
% -------- Insert your code here -------- %
[frequencyCounts, binLocations] = hist(Losses_out * x0{1},50);
bar(binLocations, frequencyCounts);
hold on;
% 99% Out-of-sample VaR
line([VaRout(1,1) VaRout(1,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99.9 % Out-of-sample VaR
line([VaRout(1,2) VaRout(1,2)], [0 max(frequencyCounts)/2], 'Color', 'g', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99% Out-of-sample CVaR
line([CVaRout(1,1) CVaRout(1,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99.9% Out-of-sample CVaR
line([CVaRout(1,2) CVaRout(1,2)], [0 max(frequencyCounts)/2], 'Color', 'g', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

normf = ( 1/(std(Losses_out * x0{1})*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(Losses_out * x0{1}))/std(Losses_out * x0{1})).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations,normf,'r','LineWidth',1);
hold on;

text(0.98*VaRout(1,1), max(frequencyCounts)/1.9, {'VaR','99%'})
text(0.98*CVaRout(1,1), max(frequencyCounts)/1.9, {'CVaR','99%'})
text(0.98*VaRout(1,2), max(frequencyCounts)/1.9, {'VaR','99.9%'})
text(0.98*CVaRout(1,2), max(frequencyCounts)/1.9, {'CVaR','99.9%'})

hold off;
title('Portfolio 1 out-of-sample Loss Distribution')
xlabel('Portfolio 1 Loss')
ylabel('Frequency')

figure(6);
% -------- Insert your code here -------- %
[frequencyCounts, binLocations] = hist(Losses_out * x0{2},50);
bar(binLocations, frequencyCounts);
hold on;
% 99% Out-of-sample VaR
line([VaRout(2,1) VaRout(2,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99.9 % Out-of-sample VaR
line([VaRout(2,2) VaRout(2,2)], [0 max(frequencyCounts)/2], 'Color', 'g', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99% Out-of-sample CVaR
line([CVaRout(2,1) CVaRout(2,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

% 99.9% Out-of-sample CVaR
line([CVaRout(2,2) CVaRout(2,2)], [0 max(frequencyCounts)/2], 'Color', 'g', 'LineWidth', 1, 'LineStyle', '-.');
hold on;

normf = ( 1/(std(Losses_out * x0{2})*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(Losses_out * x0{2}))/std(Losses_out * x0{2})).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations,normf,'r','LineWidth',1);
hold on;

text(0.98*VaRout(2,1), max(frequencyCounts)/1.9, {'VaR','99%'})
text(0.98*CVaRout(2,1), max(frequencyCounts)/1.9, {'CVaR','99%'})
text(0.98*VaRout(2,2), max(frequencyCounts)/1.9, {'VaR','99.9%'})
text(0.98*CVaRout(2,2), max(frequencyCounts)/1.9, {'CVaR','99.9%'})

hold off;
title('Portfolio 2 out-of-sample Loss Distribution')
xlabel('Portfolio 2 Loss')
ylabel('Frequency')