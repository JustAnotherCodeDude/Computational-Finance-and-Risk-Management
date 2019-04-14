function  [x_optimal cash_optimal] = strat_equally_weighted(x_init, cash_init, mu, Q, cur_prices)
    
    % For the 20 stocks, calculate the equal weights
    n = 20;
    weight = 1/n
    
    % Find the portfolio value
    portf_value = cur_prices * x_init + cash_init;
    value_i = weight * portf_value;
    value_vector = zeros(n,1);
    value_vector(:,:) = value_i;
    
    % Find optimal shares by using (w * V)/p
    x_optimal = floor(value_vector ./ (cur_prices'));
    
    portfolio_changes = x_init - x_optimal;
    
    % Current cash in cash account, check for non negative later
    cash_optimal = cash_init + cur_prices * portfolio_changes;
end