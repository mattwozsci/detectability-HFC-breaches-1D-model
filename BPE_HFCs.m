% Bayesian Parameter Estimation Model for HFC-134a and HFC-143a

clear all

cd('RUN_DIRECTORY');

save_directory = 'SAVE_DIRECTORY';

%% Parameters that can be edited to produce results reported in the paper

gas = "HFC-134a";                  % Sets which HFC the model will analyze ("HFC-134a" or "HFC-143a")
uncertainty_analysis = 0;          % 0 for normal model, 1 for known consumption, 2 for known emission factors, 3 for known atmospheric lifetimes
sensitivity_analysis = 0;          % 0 for normal model, 1 for lower A5 consumption 2016-2023, 2 for higher A5 baseline
forceRunPriors = true;

%% Additional editable parameters
% We don't adjust these for the results reported in the paper, but editing
% them within the specified bounds will not break the model

N = 10*10^5;                          % Number of samples for the prior distributions (integer > 0)
N_resamps = 3*10^5;                % Number of samples for the posterior distributions (integer > 0)
rng("shuffle","twister");          % Random number generator setting ("shuffle" can be replaced by a postive integer to produce same results multiple times)
UB_percentile = 95;                % Percentile of compliant emissions projection used as compliant upper bound (value between 0 and 100)
rho1_min = .85;                    % Min NA5 autocorrelation 1 (1990-2021) (value between 0 and 1)
rho2_min = .5;                     % Min NA5 autocorrelation 2 (2022-2023) (value between 0 and 1)
rho3_min = .7;                     % Min A5 autocorrelation (value between 0 and 1)
NA5_cons_adder = .15;              % Standard deviation of NA5 consumption prior as a proportion of consumption (value between 0 and 1)
A5_cons_adder = .15;               % Standard deviation of NA5 consumption prior as a proportion of consumption (value between 0 and 1)
MF_sd_max = 0.03;                  % Max standard deviation of modeled mole fractions (value between 0 and 1)

%% Generate run metadata

run_time = datetime;

run_ID = strcat(...
    string(year(run_time)),...
    string(month(run_time)),...
    string(day(run_time)),...
    string(hour(run_time)),...
    string(minute(run_time)),...
    string(round(second(run_time))));

%% Translate some parameters to words for metadata

if uncertainty_analysis == 0
    UA_setting = "Off";
elseif uncertainty_analysis == 1
    UA_setting = "Known_Consumption";
elseif uncertainty_analysis == 2
    UA_setting = "Known_EFs";
elseif uncertainty_analysis == 3
    UA_setting = "Known_Atmospheric_Lifetime";
end

if sensitivity_analysis == 0
    sens_setting = "Base";
elseif sensitivity_analysis == 1
    sens_setting = "A5Lwr2016to2023";
elseif sensitivity_analysis == 2
    sens_setting = "higherA5Baseline";
elseif sensitivity_analysis == 3
    sens_setting = "nonStationaryEF";
end
  
%% Set additional parameters based on gas
% AGAGE_col is the column of data for the HFC in the AGAGE input data set
% mw is molecular weight in g/mol, from National Center for Biotechnology Information (PubChem)

if gas == "HFC-134a"
    AGAGE_col = 8; % for new annual data
    mw = 102.03;  

elseif gas == "HFC-143a"
    AGAGE_col = 10; % for new annual data
    mw = 84.04;
end

if gas == "HFC-125"
    AGAGE_col = 6;
    mw = 120.02;

elseif gas == "HFC-32"
    AGAGE_col = 4;
    mw = 52.023;
end

%% Converting ppt (mole fraction) to Mg/yr (emission): 
% (1*10^32)/(6.02*10^23*10^9*F_factor)

% Set f factor to 1 (wrong b/c emissions enhance surface MFs, but most defensible)
ppt_millionmols = 1/6.02;  
ppt_to_Mg = ppt_millionmols * mw * 1000; % (1 Megagram = 1 metric tonne = 1000 Kg)

disp("initialization complete.")

%% load or generate priors

fileName = [save_directory 'priors_' char(gas) '_UA-' char(UA_setting) '_SA-' char(sens_setting) '.mat'];
if ~isfile(fileName) || forceRunPriors
    
    fprintf('Generating priors...\n');
    if gas == "HFC-134a" || gas == "HFC-143a"
        %run('BPE_134a_143a_MCW_generate_priors.m'); % Or just call the script name directly if it's a function
        run('BPE_134a_143a_MCW_generate_priors.m')
    end
    if gas == "HFC-125" || gas == "HFC-32"
        run('BPE_125_32_MCW_generate_priors.m'); % Or just call the script name directly if it's a function
    end
    
else
    fprintf('Priors for these settings already exists and override is false. Loading priors from file.');
    load(fileName)
    fprintf('Priors loaded from file.')
end

%% AGAGE data upload and processing
% AGAGE data is in ppt
AGAGE_yrs = 1991:2024;
AGAGE_PATH = "Input_data/AGAGE_12box_global_means_03052026.csv";

AGAGE = readtable(AGAGE_PATH);
AGAGE_array = table2array(AGAGE);

for i = 1:length(AGAGE_yrs)
    yr = AGAGE_yrs(i);
    
    % Average the AGAGE global mean data for each year
    AGAGE_annual_means(i) = squeeze(AGAGE_array(AGAGE_array(:,1) == yr, AGAGE_col));

    % Average the AGAGE sd for each year
    AGAGE_annual_sd(i) = squeeze(AGAGE_array(AGAGE_array(:,1) == yr, AGAGE_col+1));
 
end

disp('AGAGE read')


%% Likelihood section (log-likelihood) - OPTIMIZED
tau_ac = lognrnd(1.1055, 0.435, N, 1); 
rho4 = exp(-1 ./ tau_ac);
%rho4 = zeros(N,1);
AGAGE_Nyrs = length(AGAGE_yrs);

MF_total_yr1 = find(1990:2024 == AGAGE_yrs(1));
MF_total_yr2 = find(1990:2024 == AGAGE_yrs(end));

mf_particles = MF_total(:, MF_total_yr1:MF_total_yr2);

% Setup constants
[t1, t2] = meshgrid(1:AGAGE_Nyrs, 1:AGAGE_Nyrs);
exp_val = abs(t1 - t2);
const_term = -0.5 * AGAGE_Nyrs * log(2 * pi);

MF_sd_max = 0.05;
mod_frac_error = MF_sd_max .* betarnd(2,2,N,1);

log_likelihood = zeros(N, 1);
MF_sd_prior = zeros(N, AGAGE_Nyrs);

% --- USE PARFOR FOR 1,000,000 PARTICLES ---
% (If you don't have Parallel Computing Toolbox, replace 'parfor' with 'for')
fprintf('Computing log-likelihood for %d particles...\n', N);

parfor ii = 1:N
    rho = rho4(ii);
    mf_particle = mf_particles(ii, :);
    
    % 1. Standard Deviations
    sd_p = mod_frac_error(ii) * mf_particle;
    MF_sd_prior(ii,:) = sd_p;
    sigma_total = sqrt(AGAGE_annual_sd.^2 + sd_p.^2);
    
    % 2. Covariance Matrix via Toeplitz AR(1)
    % C_ij = sigma_i * sigma_j * rho^|i-j|
    Rho_matrix = rho.^exp_val;
    Cov_matrix = (sigma_total' * sigma_total) .* Rho_matrix;
    
    % 3. Residual Vector
    diff_vec = (mf_particle - AGAGE_annual_means)';
    
    % 4. Fast Factorization
    [L, p] = chol(Cov_matrix, 'lower');
    if p > 0
        [L, ~] = chol(Cov_matrix + eye(AGAGE_Nyrs)*1e-6, 'lower');
    end
    
    y_solve = L \ diff_vec;
    quad_term = -0.5 * sum(y_solve.^2);
    log_det = -sum(log(diag(L)));
    
    log_likelihood(ii) = const_term + log_det + quad_term;
end

disp('Log-Likelihood Completed Safely')

delete(gcp('nocreate'));

% Determine optimal tempering factor, T, based on ESS target of 1000
target_ESS = 1000;
T_vec = 1:0.1:50;
for t = T_vec
    tempered_log_lik = log_likelihood / t;
    
    % Log-sum-exp trick to convert back to raw weights safely without overflow/underflow
    max_log = max(tempered_log_lik);
    likelihood = exp(tempered_log_lik - max_log);
    
    % Normalize weights so they sum to 1
    likelihood = likelihood / sum(likelihood);
    ESS = sum(likelihood)^2/sum(likelihood.^2);
    if (ESS>target_ESS)
        T = t
        break;
    end
    if t==T_vec(end) && ESS < target_ESS
        disp(['tempering failed to optimize before T= ' num2str(T_vec(end))])
        return
    end
end

% Updating priors based on Sampling Importance Ratio
IR_vec1 = cumsum(likelihood);

disp("Likelihood determined")
%%  Resampling

ResampleIndex = datasample(1:N, N_resamps, 'Weights', likelihood, 'Replace', true);

disp('Resampling completed')

% % Save variables and outputs from this run to .MAT
filename = strcat(save_directory,"BPE_output_",gas);

if uncertainty_analysis > 0 
    filename = strcat(filename,"_", UA_setting);
end

if sensitivity_analysis > 0 
    filename = strcat(filename,"_", sens_setting);
end

filename = strcat(filename,".mat");

save(filename,"-v7.3")

return % stop run before compliance analysis
