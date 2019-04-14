function  [x_optimal, cash_optimal] = strat_equal_risk_contr(x_init, cash_init, mu, A, cur_prices)

global Q A_ineq A_eq

Q = A;
n = length(cur_prices);


% Compute the total assets 
total_value = cur_prices * x_init + cash_init;

% Equality constraints
A_eq = ones(1,n);
b_eq = 1;

% Inequality constraints
A_ineq = [];
b_ineql = [];
b_inequ = [];
           
% Define initial portfolio ("equally weighted" or "1/n portfolio")
w0 = cur_prices' .* x_init / total_value;

options.lb = zeros(1,n);       % lower bounds on variables
options.lu = ones (1,n);       % upper bounds on variables
options.cl = [b_eq' b_ineql']; % lower bounds on constraints
options.cu = [b_eq' b_inequ']; % upper bounds on constraints

% Set the IPOPT options
options.ipopt.jac_c_constant        = 'yes';
options.ipopt.hessian_approximation = 'limited-memory';
options.ipopt.mu_strategy           = 'adaptive';
options.ipopt.tol                   = 1e-10;
options.ipopt.print_level           = 0;

% The callback functions
funcs.objective         = @computeObjERC;
funcs.constraints       = @computeConstraints;
funcs.gradient          = @computeGradERC;
funcs.jacobian          = @computeJacobian;
funcs.jacobianstructure = @computeJacobian;
  
% Run IPOPT
[wsol, info] = ipopt(w0',funcs,options);

% Make solution a column vector
if(size(wsol,1)==1)
    w_erc = wsol';
else
    w_erc = wsol;
end

money_needed = w_erc * total_value;
x_optimal = floor(money_needed ./ cur_prices');
cash_optimal = total_value - cur_prices * x_optimal;

