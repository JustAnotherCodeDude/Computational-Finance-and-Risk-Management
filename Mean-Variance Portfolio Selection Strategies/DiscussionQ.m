clc;
clear all;
format long

% Input files
input_file_prices  = 'Daily_closing_prices.csv';

% Add path to CPLEX
addpath('E:\Random Software\MATLAB\CPLEX Optimazation Studio\cplex\matlab\x64_win64');

% Read daily prices
if(exist(input_file_prices,'file'))
  fprintf('\nReading daily prices datafile - %s\n', input_file_prices)
  fid = fopen(input_file_prices);
     % Read instrument tickers
     hheader  = textscan(fid, '%s', 1, 'delimiter', '\n');
     headers = textscan(char(hheader{:}), '%q', 'delimiter', ',');
     tickers = headers{1}(2:end);
     % Read time periods
     vheader = textscan(fid, '%[^,]%*[^\n]');
     dates = vheader{1}(1:end);
  fclose(fid);
  data_prices = dlmread(input_file_prices, ',', 1, 1);
else
  error('Daily prices datafile does not exist')
end

% Convert dates into array [year month day]
format_date = 'mm/dd/yyyy';
dates_array = datevec(dates, format_date);
dates_array = dates_array(:,1:3);

% Find the number of trading days in Nov-Dec 2014 and
% compute expected return and covariance matrix for period 1
day_ind_start0 = 1;
day_ind_end0 = length(find(dates_array(:,1)==2014));
cur_returns0 = data_prices(day_ind_start0+1:day_ind_end0,:) ./ data_prices(day_ind_start0:day_ind_end0-1,:) - 1;
mu = mean(cur_returns0)';
Q = cov(cur_returns0);

% Remove datapoints for year 2014
data_prices = data_prices(day_ind_end0+1:end,:);
dates_array = dates_array(day_ind_end0+1:end,:);
dates = dates(day_ind_end0+1:end,:);

% Initial positions in the portfolio
init_positions = [5000 950 2000 0 0 0 0 2000 3000 1500 0 0 0 0 0 0 1001 0 0 0]';

% Initial value of the portfolio
init_value = data_prices(1,:) * init_positions;
fprintf('\nInitial portfolio value = $ %10.2f\n\n', init_value);

% Initial portfolio weights
w_init = (data_prices(1,:) .* init_positions')' / init_value;

% Number of periods, assets, trading days
N_periods = 6*length(unique(dates_array(:,1))); % 6 periods per year
N = length(tickers);
N_days = length(dates);

% Annual risk-free rate for years 2015-2016 is 2.5%
r_rf = 0.025;


% Number of strategies
strategy_functions = {'strat_buy_and_hold' 'strat_equally_weighted' 'strat_min_variance' 'strat_max_Sharpe'};
strategy_names     = {'Buy and Hold' 'Equally Weighted Portfolio' 'Mininum Variance Portfolio' 'Maximum Sharpe Ratio Portfolio'};
% N_strat = 1; % comment this in your code
N_strat = length(strategy_functions); % uncomment this in your code
fh_array = cellfun(@str2func, strategy_functions, 'UniformOutput', false);

for (period = 1:N_periods)
   % Compute current year and month, first and last day of the period
   if(dates_array(1,1)==15)
       cur_year  = 15 + floor(period/7);
   else
       cur_year  = 2015 + floor(period/7);
   end
   cur_month = 2*rem(period-1,6) + 1;
   day_ind_start = find(dates_array(:,1)==cur_year & dates_array(:,2)==cur_month, 1, 'first');
   day_ind_end = find(dates_array(:,1)==cur_year & dates_array(:,2)==(cur_month+1), 1, 'last');
   fprintf('\nPeriod %d: start date %s, end date %s\n', period, char(dates(day_ind_start)), char(dates(day_ind_end)));

   % Prices for the current day
   current_prices = data_prices(day_ind_start,:);

   % Execute portfolio selection strategies
   for(strategy = 1:N_strat)

      % Get current portfolio positions
      if(period==1)
         curr_positions = init_positions;
         curr_cash = 0;
         portf_value{strategy} = zeros(N_days,1);
      else
         curr_positions = x{strategy,period-1};
         curr_cash = cash{strategy,period-1};
      end

      % Compute strategy
      [x{strategy,period} cash{strategy,period}] = fh_array{strategy}(curr_positions, curr_cash, mu, Q, current_prices);

      % Verify that strategy is feasible (you have enough budget to re-balance portfolio)
      % Check that cash account is >= 0
      % Check that we can buy new portfolio subject to transaction costs

      %%%%%%%%%%% Insert your code here %%%%%%%%%%%%
      
      % Calculate the amount of cash after reblancing in cash account
      rebalance_trans = curr_positions - x{strategy, period};
      transaction_cost = current_prices * abs(rebalance_trans) * 0.005;
      cash{strategy, period} = cash{strategy, period} - transaction_cost;
      
      % Check if cash account is negative, if so, buy less of the most
      % rebalace changes
      
      if cash{strategy, period} < 0
          [M, I] = max(abs(rebalance_trans));
          stock_to_change = I;
          stock_to_change_price = current_prices(1, stock_to_change);
          number_of_shares_change = ceil(abs(cash{strategy, period}) / stock_to_change_price);
          saved_trans_cost = number_of_shares_change * stock_to_change_price * 0.005
          
          new_cash = number_of_shares_change * stock_to_change_price + saved_trans_cost + cash{strategy, period};
          cash{strategy, period} = round(new_cash, 2);
          
          % If the maximum change in holdings is to sell,sell less of it.
          % If the maximum change in holdings is to buy, buy less of it.
          
          if max(rebalance_trans) > 0 % buy
            x_new = x{strategy, period}(stock_to_change , 1) - number_of_shares_change;
          else %sell
            x_new = x{strategy, period}(stock_to_change , 1) + number_of_shares_change;
          end 
          
          x{strategy, period}(stock_to_change , 1) = x_new;
      end
      
      % Compute portfolio value
      portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period};

      fprintf('   Strategy "%s", value begin = $ %10.2f, value end = $ %10.2f\n', char(strategy_names{strategy}), portf_value{strategy}(day_ind_start), portf_value{strategy}(day_ind_end));

   end
      
   % Compute expected returns and covariances for the next period
   cur_returns = data_prices(day_ind_start+1:day_ind_end,:) ./ data_prices(day_ind_start:day_ind_end-1,:) - 1;
   mu = mean(cur_returns)';
   Q = cov(cur_returns);
   
end

% Plot results
% figure(1);
%%%%%%%%%%% Insert your code here %%%%%%%%%%%%

% Initial Position Change for discussion question
[x_test{1,1}, cash_test{1,1}] = strat_equally_weighted(init_positions, 0, mu, Q, data_prices(1,:));
[x_test{2,1}, cash_test{2,1}] = strat_min_variance(init_positions, 0, mu, Q, data_prices(1,:));
[x_test{3,1}, cash_test{3,1}] = strat_max_Sharpe(init_positions, 0, mu, Q, data_prices(1,:));


test1_portf_value = []
for (days = 1:length(dates_array))
    test1_portf_value = [test1_portf_value data_prices(days,:) * x_test{1,1} + cash_test{1,1}];
end

test2_portf_value = []
for (days = 1:length(dates_array))
    test2_portf_value = [test2_portf_value data_prices(days,:) * x_test{2,1} + cash_test{2,1}];
end

test3_portf_value = []
for (days = 1:length(dates_array))
    test3_portf_value = [test3_portf_value data_prices(days,:) * x_test{3,1} + cash_test{3,1}];
end

figure(1);
days =1:length(dates_array);

hold on
plot(days, portf_value{1},'g')
plot(days, portf_value{2},'y')
plot(days, portf_value{3},'c')
plot(days, portf_value{4},'m')

plot(days, test1_portf_value,'r')
plot(days, test2_portf_value,'b')
plot(days, test3_portf_value,'k')

legend('Buy and Hold','Equally Weighted','Min Variance','Max Sharpe Ratio','Equally Weighted/Buy and Hold','MinVariance/Buy and Hold','MaxSharpe/Buy and Hold')
title('Daily Value of Portfolio');
xlabel('Days');
ylabel('Portfolio Value');
hold off

% Find number of days in different periods
days_in_each_period = [];
for year = [2015, 2016]
    for month = 1:12
        days_in_month = length(find(dates_array(:,1)==year & dates_array(:,2)==month));
        days_in_each_period = [days_in_each_period, days_in_month]; % append to array
    end
end


% Find the weight of portfolio at each period for minimum variance 
weight_array =zeros(20,12);
j = 1; % First day
for i = 1:12
    shares_array = x{3,i};
    current_prices = data_prices(j,:);
    total_value = current_prices * shares_array + cash{3,i};
    value_weight = diag(shares_array * current_prices);
    weight_array(:,i) = value_weight ./ total_value;
    
    j = j + days_in_each_period(1,i);

end


days_in_each_period = sum(reshape(days_in_each_period, 2, 12));

%{
figure(2)
[weight_array_minvar] = weight_array;
weight_array_minvar = [w_init,weight_array_minvar];
plot(0:12,weight_array_minvar)
legend(headers{1,1}(2:21,1))
title('Portfolio Allocations of Min Vairance')
xlabel('Period')
ylabel('Weight of Asset')



% Find the weight of portfolio at each period for max sharpe ratio
weight_array =zeros(20,12);
j = 1; % First day
for i = 1:12
    shares_array = x{4,i};
    current_prices = data_prices(j,:);
    total_value = current_prices * shares_array + cash{4,i};
    value_weight = diag(shares_array * current_prices);
    weight_array(:,i) = value_weight ./ total_value;
    
    j = j + days_in_each_period(1,i);

end

figure(3)
[weight_array_sharpeR] = weight_array;
weight_array_sharpeR = [w_init,weight_array_sharpeR];
plot(0:12,weight_array_sharpeR)
legend(headers{1,1}(2:21,1))
title('Portfolio Allocations of Max Sharpe Ratio')
xlabel('Period')
ylabel('Weight of Asset')

%}