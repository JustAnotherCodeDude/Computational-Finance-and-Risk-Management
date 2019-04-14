function  [x_optimal, cash_optimal] = strat_max_Sharpe(x_init, cash_init, mu, Q, cur_prices)
    
    global yearindex

    n_1 = length(x_init);
    n_2 = n_1 + 1;
    QQ = zeros(n_2,n_2);
    QQ(1:n_1,1:n_1) = 2 * Q; 
    
    
    if yearindex == 2008
        r_rf = 0.045;
    else
        r_rf = 0.025;
    end
    daily_rf = r_rf / 252;
    A = zeros(2 , n_2);
    A(1, 1:n_1) = mu' - daily_rf;
    
    % Check if all mu-daily_rf is negative
    if sum((mu-daily_rf) <= 0) == n_1
        % Do not rebalance
        x_optimal = x_init;
        cash_optimal = cash_init;
    else
        A(2, 1:n_1) =  1;
        A(2, n_2) = - 1; 
        b = [1; 0];
        lb = zeros(n_2, 1);
        ub = inf * ones(n_2, 1);
    
    
        cplex1 = Cplex('max_sharpe_ratio');
        cplex1.addCols(zeros(n_2,1), [], lb, ub);
        cplex1.addRows(b, A, b);
        cplex1.Model.Q = QQ;
        cplex1.Param.qpmethod.Cur = 6; % concurrent algorithm
        cplex1.Param.barrier.crossover.Cur = 1; % enable crossover
        cplex1.DisplayFunc = []; % disable output to screen
        cplex1.solve();
        solution = cplex1.Solution.x;
        maxSharpe = solution(1:n_1, 1);
        maxSharpe = maxSharpe ./ solution(n_2, 1);

        totalvalue = cur_prices * x_init + cash_init;
        value_vector = maxSharpe .* totalvalue;

        x_optimal = floor(value_vector ./ (cur_prices'));
        portfolio_changes = x_init - x_optimal;
        cash_optimal = cash_init + cur_prices * portfolio_changes;
    end


end