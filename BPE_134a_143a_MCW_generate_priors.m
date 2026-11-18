%% Data upload and initial processing
% Consumption values are in metric tonnes

% Non-Article 5 ("NA5") initial consumption estimates
cons_NA5_table = readtable("Input_data/NA5_data_input.csv");

% Article 5 ("A5") initial consumption estimates
cons_A5_all_HFCs_missingdat = readtable("Input_data/A5_data_input.csv");

% Interpolating missing data for A5 (linear interpolation)
cons_A5_all_HFCs_array = fillmissing(cons_A5_all_HFCs_missingdat{:,3:36},"linear",2);
cons_A5_table = cons_A5_all_HFCs_missingdat;
cons_A5_table(:,3:36) = array2table(cons_A5_all_HFCs_array);

%% Sort data by gas

gases = cons_NA5_table{:,1};
cons_NA5 = cons_NA5_table(matches(gases,gas),:);

gases = cons_A5_table{:,1};
cons_A5 = cons_A5_table(matches(gases,gas),:);

%% Sort data by application

% NA5
applications = cons_NA5{:,2};

cons_NA5_COM = cons_NA5{matches(applications,"2.F.1.a Commercial Refrigeration"),3:end};
cons_NA5_DOM = cons_NA5{matches(applications,"2.F.1.b Domestic Refrigeration"),3:end};
cons_NA5_IND = cons_NA5{matches(applications,"2.F.1.c Industrial Refrigeration"),3:end};
cons_NA5_TRA = cons_NA5{matches(applications,"2.F.1.d Transport Refrigeration"),3:end};
cons_NA5_MAC = cons_NA5{matches(applications,"2.F.1.e Mobile Air-conditioning"),3:end};
cons_NA5_SAC = cons_NA5{matches(applications,"2.F.1.f Stationary Air-conditioning"),3:end};
cons_NA5_CCF = cons_NA5{matches(applications,"2.F.2.a Closed Cells"),3:end};
cons_NA5_OCF = cons_NA5{matches(applications,"2.F.2.b Open Cells"),3:end};
cons_NA5_AER = cons_NA5{matches(applications,"2.F.4 Aerosols"),3:end};
cons_NA5_SOL = cons_NA5{matches(applications,"2.F.5 Solvents"),3:end};
cons_NA5_FIR = cons_NA5{matches(applications,"2.F.3 Fire Protection"),3:end};
cons_NA5_CON = cons_NA5{matches(applications,"2.F.6.b Contained"),3:end};
cons_NA5_EMI = cons_NA5{matches(applications,"2.F.6.a Emissive"),3:end};

% A5
applications = cons_A5{:,2};

cons_A5_COM = cons_A5{matches(applications,"Commercial"),3:end};
cons_A5_DOM = cons_A5{matches(applications,"Domestic"),3:end};
cons_A5_IND = cons_A5{matches(applications,"Industrial"),3:end};
cons_A5_TRA = cons_A5{matches(applications,"Transport"),3:end};
cons_A5_MAC = cons_A5{matches(applications,"MAC"),3:end}; % Mobile Air Conditioning
cons_A5_SAC = cons_A5{matches(applications,"SAC"),3:end}; % Stationary Air Conditioning
cons_A5_FOA = cons_A5{matches(applications,"Foams"),3:end};
cons_A5_AER = cons_A5{matches(applications,"Aerosols"),3:end};
cons_A5_SOL = cons_A5{matches(applications,"Solvent"),3:end};
cons_A5_FIR = cons_A5{matches(applications,"Fire fighting"),3:end};
cons_A5_OTH = cons_A5{matches(applications,"Other"),3:end};

%% Establish IPCC EF Ranges for each application
% From IPCC 2006 guidelines

DE_COM = [.005 .03]; % Includes stand-alone and medium/large
DE_DOM = [.002 .01];
DE_IND = [.002 .03]; % Includes chillers
DE_TRA = [.002 .01];
DE_MAC = [.002 .005];
DE_SAC = [.002 .01];  % Does not include chillers
DE_CCF = [.07 .4]; 
DE_OCF = [1 1]; 
% DE_AER = [.5 .5];
DE_AER = [0.3 0.7];
DE_SOL = DE_AER; 
DE_FIR = [.002 .03]; % IPCC does not give, assumed similar to R/AC applications 
DE_CON = [.002 .03]; % IPCC does not give, assumed similar to R/AC applications 
DE_EMI = DE_AER; % IPCC does not give, assumed same as aerosols/solvents

RF_COM = [.01 .35]; % Includes stand-alone and medium/large
RF_DOM = [.001 .005];
RF_IND = [.02 .25]; % Includes chillers
RF_TRA = [.15 .5];
RF_MAC = [.1 .2];
RF_SAC = [.01 .1]; % Does not include chillers
RF_CCF = [.005 .03];
RF_OCF = [1 1]; % IPCC does not give, assumed same as aerosols/solvents
RF_AER = [0.8 1]; 
RF_SOL = [1 1]; 
RF_FIR = [.01 .06]; % Includes flooding systems and portable extinguishers
RF_CON = [.02 .5]; % IPCC does not give, assumed similar to R/AC applications 
RF_EMI = [1 1]; % IPCC does not give, assumed same as aerosols/solvents

%% Group the applications based on emissions behavior and relative importance

if gas == "HFC-134a"

   %% Group 1
    % NA5 Group 1: Aerosols, Solvents, Emissive, Open Cells
    cons_NA5_grp1 = cons_NA5_AER + cons_NA5_SOL + cons_NA5_OCF + cons_NA5_EMI;
    
    % A5 Group 1: Aerosols, Solvents, Other
    cons_A5_grp1 = cons_A5_AER + cons_A5_SOL + cons_A5_OTH;
    
    % Calculate sum (in t) of consumption in these categories (total for full
    % timeseries)
    grp1_tot = sum(cons_NA5_grp1 + cons_A5_grp1, 2);
    
    % Calculate proportion of consumption for each application relative to
    % full grouping
    grp1_cons_array = vertcat(...
        (sum(cons_NA5_AER) + sum(cons_A5_AER))/grp1_tot,...
        (sum(cons_NA5_SOL) + sum(cons_A5_SOL))/grp1_tot,...
        (sum(cons_NA5_OCF))/grp1_tot,...
        (sum(cons_NA5_EMI) + sum(cons_A5_OTH))/grp1_tot);
    
    % Create array of DE information for grouping
    grp1_DE_array = vertcat(DE_AER, DE_SOL, DE_OCF, DE_EMI);
    
    % Take the min, max, and weighted average of the DEs 
    % (weighted by consumption proportion)
    grp1_DE_min = min(grp1_DE_array,[],"all");
    grp1_DE_max = max(grp1_DE_array,[],"all");
    grp1_DE_mode = sum(grp1_cons_array .* mean(grp1_DE_array,2));

    % Create array of RF information for grouping
    grp1_RF_array = vertcat(RF_AER, RF_SOL, RF_OCF, RF_EMI);
    
    % Take the min, max, and weighted average of the RFs 
    % (weighted by consumption proportion)
    grp1_RF_min = min(grp1_RF_array,[],"all");
    grp1_RF_max = max(grp1_RF_array,[],"all");
    grp1_RF_mode = sum(grp1_cons_array .* mean(grp1_RF_array,2));

    
    %% Group 2
    % NA5 Group 2: Commercial, Industrial, Transport Refrigeration, Mobile
    % Air Conditioning, Stationary Air Conditioning, Fire Protection, and 
    % Contained
    cons_NA5_grp2 = cons_NA5_COM + cons_NA5_IND + cons_NA5_TRA + cons_NA5_MAC...
        + cons_NA5_SAC + cons_NA5_FIR + cons_NA5_CON;
    
    % A5 Group 2: Commercial, Industrial, Transport Refrigeration, Mobile 
    % Air Conditioning, Stationary Air Conditioning, Fire protection, Other
    cons_A5_grp2 = cons_A5_COM + cons_A5_IND + cons_A5_TRA + cons_A5_MAC...
        + cons_A5_SAC + cons_A5_FIR;
    
    % Calculate sum (in t) of consumption in these categories (total for full
    % timeseries)
    grp2_tot = sum(cons_NA5_grp2 + cons_A5_grp2, 2);
    
    % Calculate proportion of consumption for each application relative to
    % full grouping
    grp2_cons_array = vertcat(...
        (sum(cons_NA5_COM) + sum(cons_A5_COM))/grp2_tot,...
        (sum(cons_NA5_IND) + sum(cons_A5_IND))/grp2_tot,...
        (sum(cons_NA5_TRA) + sum(cons_A5_TRA))/grp2_tot,...
        (sum(cons_NA5_MAC) + sum(cons_A5_MAC))/grp2_tot,...
        (sum(cons_NA5_SAC) + sum(cons_A5_SAC))/grp2_tot,...
        (sum(cons_NA5_FIR) + sum(cons_A5_FIR))/grp2_tot,...
        (sum(cons_NA5_CON))/grp2_tot);
        
    % Create array of DE information for grouping
    grp2_DE_array = vertcat(DE_COM, DE_IND, DE_TRA, DE_MAC, DE_SAC,...
        DE_FIR, DE_CON);
    
    % Create array of RF information for grouping
    grp2_RF_array = vertcat(RF_COM, RF_IND, RF_TRA, RF_MAC, RF_SAC,...
        RF_FIR, RF_CON);
    
    % Take the min, max, and weighted average of the DEs 
    % (weighted by consumption proportion)
    grp2_DE_min = min(grp2_DE_array,[],"all");
    grp2_DE_max = max(grp2_DE_array,[],"all");
    grp2_DE_mode = sum(grp2_cons_array .* mean(grp2_DE_array,2));
    
    % Take the min, max, and weighted average of the RFs 
    % (weighted by consumption proportion)
    grp2_RF_min = min(grp2_RF_array,[],"all");
    grp2_RF_max = max(grp2_RF_array,[],"all");
    grp2_RF_mode = sum(grp2_cons_array .* mean(grp2_RF_array,2));

    
    %% Grp 3
    % NA5 Group 3: Domestic Refrigeration 
    cons_NA5_grp3 = cons_NA5_DOM;
    
    % A5 Group 3: Domestic Refrigeration
    cons_A5_grp3 = cons_A5_DOM;
    
    % Take the min, max, and weighted average of the DEs 
    % (weighted by consumption proportion)
    grp3_DE_min = min(DE_DOM);
    grp3_DE_max = max(DE_DOM);
    grp3_DE_mode = mean(DE_DOM);
    
    % Take the min, max, and weighted average of the RFs 
    % (weighted by consumption proportion)
    grp3_RF_min = min(RF_DOM);
    grp3_RF_max = max(RF_DOM);
    grp3_RF_mode = mean(RF_DOM);
    
    %% Grp 4
    % NA5 Group 4: Closed Cells 
    cons_NA5_grp4 = cons_NA5_CCF;
    
    % A5 Group 4: Foam
    cons_A5_grp4 = cons_A5_FOA;
    
    % Take the min, max, and weighted average of the DEs 
    % (weighted by consumption proportion)
    grp4_DE_min = min(DE_CCF);
    grp4_DE_max = max(DE_CCF);
    grp4_DE_mode = mean(DE_CCF);
    
    % Take the min, max, and weighted average of the RFs 
    % (weighted by consumption proportion)
    grp4_RF_min = min(RF_CCF);
    grp4_RF_max = max(RF_CCF);
    grp4_RF_mode = mean(RF_CCF);


    %% DE distributions
    % Beta distribution with mode at the weighted average calculated
    % previously

    [a_grp1_DE, b_grp1_DE] = beta_params(grp1_DE_min, grp1_DE_max, grp1_DE_mode);
    DE_grp1 = grp1_DE_min + (grp1_DE_max - grp1_DE_min) * betarnd(a_grp1_DE, b_grp1_DE, N, 1);

    [a_grp2_DE, b_grp2_DE] = beta_params(grp2_DE_min, grp2_DE_max, grp2_DE_mode);
    DE_grp2 = grp2_DE_min...
        + (grp2_DE_max - grp2_DE_min) * betarnd(a_grp2_DE, b_grp2_DE, N, 1);

    [a_grp3_DE, b_grp3_DE] = beta_params(grp3_DE_min, grp3_DE_max, grp3_DE_mode);
    DE_grp3 = grp3_DE_min...
        + (grp3_DE_max - grp3_DE_min) * betarnd(a_grp3_DE, b_grp3_DE, N, 1);

    [a_grp4_DE, b_grp4_DE] = beta_params(grp4_DE_min, grp4_DE_max, grp4_DE_mode);
    DE_grp4 = grp4_DE_min...
        + (grp4_DE_max - grp4_DE_min) * betarnd(a_grp4_DE, b_grp4_DE, N, 1);
    
    %% RF distributions
    % Beta distribution with mode at the weighted average calculated
    % previously 

    % No beta distribution for group 1 since max and min are equal,
    % resulting in an error when trying to calculate beta parameters
    RF_grp1 = grp1_RF_min + (grp1_RF_max - grp1_RF_min) * ones(N,1);
    
    [a_grp2_RF, b_grp2_RF] = beta_params(grp2_RF_min, grp2_RF_max, grp2_RF_mode);
    RF_grp2 = grp2_RF_min...
        + (grp2_RF_max - grp2_RF_min) * betarnd(a_grp2_RF, b_grp2_RF, N, 1);

    [a_grp3_RF, b_grp3_RF] = beta_params(grp3_RF_min, grp3_RF_max, grp3_RF_mode);
    RF_grp3 = grp3_RF_min...
        + (grp3_RF_max - grp3_RF_min) * betarnd(a_grp3_RF, b_grp3_RF, N, 1);

    [a_grp4_RF, b_grp4_RF] = beta_params(grp4_RF_min, grp4_RF_max, grp4_RF_mode);
    RF_grp4 = grp4_RF_min...
        + (grp4_RF_max - grp4_RF_min) * betarnd(a_grp4_RF, b_grp4_RF, N, 1);


elseif gas == "HFC-143a"

    %% Group 1

    % NA5 Group 1: Other
    cons_NA5_grp1 = cons_NA5_DOM + cons_NA5_SAC + cons_NA5_MAC...
        + cons_NA5_CCF + cons_NA5_OCF + cons_NA5_AER + cons_NA5_SOL... 
        + cons_NA5_FIR + cons_NA5_CON + cons_NA5_EMI;

    % A5 Group 1: Other
    cons_A5_grp1 = cons_A5_DOM + cons_A5_SAC + cons_A5_MAC...
        + cons_A5_FOA + cons_A5_AER + cons_A5_SOL + cons_A5_FIR...
        + cons_A5_OTH;

    % Calculate sum (in t) of consumption in these categories (total for full
    % timeseries)
    grp1_tot = sum(cons_NA5_grp1 + cons_A5_grp1, 2);

    % Calculate proportion of consumption for each application relative to
    % full grouping
    grp1_cons_array = vertcat(...
        (sum(cons_NA5_DOM) + sum(cons_A5_DOM))/grp1_tot,...
        (sum(cons_NA5_SAC) + sum(cons_A5_SAC))/grp1_tot,...
        (sum(cons_NA5_MAC) + sum(cons_A5_MAC))/grp1_tot,...    
        (sum(cons_NA5_CCF) + sum(cons_A5_FOA))/grp1_tot,...
        (sum(cons_NA5_AER) + sum(cons_A5_AER))/grp1_tot,...
        (sum(cons_NA5_SOL) + sum(cons_A5_SOL))/grp1_tot,...
        (sum(cons_NA5_FIR) + sum(cons_A5_FIR))/grp1_tot,...
        (sum(cons_NA5_CON) + sum(cons_A5_OTH))/grp1_tot,...
        (sum(cons_NA5_OCF))/grp1_tot,...
        (sum(cons_NA5_EMI))/grp1_tot);

    % Create array of DE information for grouping
    grp1_DE_array = vertcat(DE_DOM, DE_SAC, DE_MAC, DE_CCF, DE_AER,...
        DE_SOL, DE_FIR, DE_CON, DE_OCF, DE_EMI);

    % Create array of RF information for grouping
    grp1_RF_array = vertcat(RF_DOM, RF_SAC, RF_MAC, RF_CCF, RF_AER,...
        RF_SOL, RF_FIR, RF_CON, RF_OCF, RF_EMI);

    % Take the min, max, and weighted average of the DEs 
    % (weighted by consumption proportion)
    grp1_DE_min = min(grp1_DE_array,[],"all");
    grp1_DE_max = max(grp1_DE_array,[],"all");
    grp1_DE_mode = sum(grp1_cons_array .* mean(grp1_DE_array,2),1,"omitmissing");

    % Take the min, max, and weighted average of the RFs 
    % (weighted by consumption proportion)
    grp1_RF_min = min(grp1_RF_array,[],"all");
    grp1_RF_max = max(grp1_RF_array,[],"all");
    grp1_RF_mode = sum(grp1_cons_array .* mean(grp1_RF_array,2),1,"omitmissing");


    %% Group 2

    % NA5 Group 2: Commercial, Industrial
    cons_NA5_grp2 = cons_NA5_COM + cons_NA5_IND;

    % A5 Group 2: Commercial, Industrial
    cons_A5_grp2 = cons_A5_COM + cons_A5_IND;

    % Calculate sum (in t) of consumption in these categories (total for full
    % timeseries)
    grp2_tot = sum(cons_NA5_grp2 + cons_A5_grp2, 2);

    % Calculate proportion of consumption for each application relative to
    % full grouping
    grp2_cons_array = vertcat(...
        (sum(cons_NA5_COM) + sum(cons_A5_COM))/grp2_tot,...
        (sum(cons_NA5_IND) + sum(cons_A5_IND))/grp2_tot);

    % Create array of DE information for grouping
    grp2_DE_array = vertcat(DE_COM, DE_IND);

    % Create array of RF information for grouping
    grp2_RF_array = vertcat(RF_COM, RF_IND);

    % Take the min, max, and weighted average of the DEs 
    % (weighted by consumption proportion)
    grp2_DE_min = min(grp2_DE_array,[],"all");
    grp2_DE_max = max(grp2_DE_array,[],"all");
    grp2_DE_mode = sum(grp2_cons_array .* mean(grp2_DE_array,2),1,"omitmissing");

    % Take the min, max, and weighted average of the RFs 
    % (weighted by consumption proportion)
    grp2_RF_min = min(grp2_RF_array,[],"all");
    grp2_RF_max = max(grp2_RF_array,[],"all");
    grp2_RF_mode = sum(grp2_cons_array .* mean(grp2_RF_array,2),1,"omitmissing");

    %% Group 3

    % NA5 Group 3: Transport
    cons_NA5_grp3 = cons_NA5_TRA;

    % A5 Group 3: Transport
    cons_A5_grp3 = cons_A5_TRA;

    % Take the min, max, and weighted average of the DEs 
    % (weighted by consumption proportion)
    grp3_DE_min = min(DE_TRA);
    grp3_DE_max = max(DE_TRA);
    grp3_DE_mode = mean(DE_TRA);
    
    % Take the min, max, and weighted average of the RFs 
    % (weighted by consumption proportion)
    grp3_RF_min = min(RF_TRA);
    grp3_RF_max = max(RF_TRA);
    grp3_RF_mode = mean(RF_TRA);

    %% Group 4

    cons_NA5_grp4 = zeros(1,width(cons_NA5_grp1));
    cons_A5_grp4 = zeros(1,width(cons_NA5_grp1));

    grp4_DE_mode = 0;
    grp4_RF_mode = 0;

    %% DE distributions
    % Beta distribution with mode at the weighted average calculated
    % previously 

    [a_grp1_DE, b_grp1_DE] = beta_params(grp1_DE_min, grp1_DE_max, grp1_DE_mode);
    DE_grp1 = grp1_DE_min...
        + (grp1_DE_max - grp1_DE_min) * betarnd(a_grp1_DE, b_grp1_DE, N, 1);

    [a_grp2_DE, b_grp2_DE] = beta_params(grp2_DE_min, grp2_DE_max, grp2_DE_mode);
    DE_grp2 = grp2_DE_min...
        + (grp2_DE_max - grp2_DE_min) * betarnd(a_grp2_DE, b_grp2_DE, N, 1);

    [a_grp3_DE, b_grp3_DE] = beta_params(grp3_DE_min, grp3_DE_max, grp3_DE_mode);
    DE_grp3 = grp3_DE_min...
        + (grp3_DE_max - grp3_DE_min) * betarnd(a_grp3_DE, b_grp3_DE, N, 1);
    
    DE_grp4 = zeros(N,1);
    a_grp4_DE = NaN;
    b_grp4_DE = NaN;
    
    %% RF distributions
    % Beta distribution with mode at the weighted average calculated
    % previously 

    [a_grp1_RF, b_grp1_RF] = beta_params(grp1_RF_min, grp1_RF_max, grp1_RF_mode);
    RF_grp1 = grp1_RF_min...
        + (grp1_RF_max - grp1_RF_min) * betarnd(a_grp1_RF, b_grp1_RF, N, 1);

    [a_grp2_RF, b_grp2_RF] = beta_params(grp2_RF_min, grp2_RF_max, grp2_RF_mode);
    RF_grp2 = grp2_RF_min...
        + (grp2_RF_max - grp2_RF_min) * betarnd(a_grp2_RF, b_grp2_RF, N, 1);

    [a_grp3_RF, b_grp3_RF] = beta_params(grp3_RF_min, grp3_RF_max, grp3_RF_mode);
    RF_grp3 = grp3_RF_min...
        + (grp3_RF_max - grp3_RF_min) * betarnd(a_grp3_RF, b_grp3_RF, N, 1);

    RF_grp4 = zeros(N,1);
    a_grp4_RF = NaN;
    b_grp4_RF = NaN;

end

disp('Emission factor priors done')

%% Sensitivity test 1
% Lowering A5 consumption on the basis of potential double-counting between
% input data sets

if sensitivity_analysis == 1

    % Store original 2023 A5 consumption before adjusting (this will be
    % used later in the Kigali Amendment scenarios
    cons_A5_grp1_2023_original = cons_A5_grp1(end);
    cons_A5_grp2_2023_original = cons_A5_grp2(end);
    cons_A5_grp3_2023_original = cons_A5_grp3(end);
    cons_A5_grp4_2023_original = cons_A5_grp4(end);

    % p is the mean percent of UNFCCC-derived consumption not included in UNEP
    % reporting for NA5 countries with reporting for both venues 2019-2021. We
    % will assume this percentage holds for the entire period 2016-2023.
    p = .30;
    
    cons_NA5_initial_tot = cons_NA5_grp1 + cons_NA5_grp2 + cons_NA5_grp3 + cons_NA5_grp4;
    absolute_diffs = p * (cons_NA5_initial_tot);
    
    % We assume that these absolute differences are subtracted from each A5
    % application grouping proportionally for 2020-2023
    cons_A5_initial_tot = cons_A5_grp1 + cons_A5_grp2 + cons_A5_grp3 + cons_A5_grp4;
    cons_A5_p = ((cons_A5_initial_tot - absolute_diffs)./cons_A5_initial_tot);

    cons_A5_grp1(31:end) = cons_A5_grp1(31:end).*(cons_A5_p(31:end));
    cons_A5_grp2(31:end) = cons_A5_grp2(31:end).*(cons_A5_p(31:end));
    cons_A5_grp3(31:end) = cons_A5_grp3(31:end).*(cons_A5_p(31:end));
    cons_A5_grp4(31:end) = cons_A5_grp4(31:end).*(cons_A5_p(31:end));

    % Then we redo the linear interpolation between TEAP data for 2015 and
    % UNEP data for 2020
    cons_A5_grp1(26:31) = linspace(cons_A5_grp1(26),cons_A5_grp1(31),6);
    cons_A5_grp2(26:31) = linspace(cons_A5_grp2(26),cons_A5_grp2(31),6);
    cons_A5_grp3(26:31) = linspace(cons_A5_grp3(26),cons_A5_grp3(31),6);
    cons_A5_grp4(26:31) = linspace(cons_A5_grp4(26),cons_A5_grp4(31),6);

end

%% priors adjusted for underreporting possibility (to be tested)

% =========================================================================
% PARAMETERS FOR LOGNORMAL TRANSITION & QUANTILE TRANSFORM
% =========================================================================
threshold_cons = 10000; % Threshold in Mg
scale_width    = 2000;  % Sigmoid transition width

% Early-year lognormal shape parameter (produces wide right tail)
sigma_log_early = log(1 + 1.96 * 0.50) / 1.96; % ~0.207

% High-volume lognormal shape parameter (~15% relative standard deviation)
sigma_log_late  = sqrt(log(1 + 0.15^2));        % ~0.148

% =========================================================================
% 1. NON-ARTICLE 5 (NA5) CONSUMPTION (1990–2023)
% =========================================================================
groups_NA5_base = {cons_NA5_grp1, cons_NA5_grp2, cons_NA5_grp3, cons_NA5_grp4};
cons_NA5_out    = cell(1, 4);

% Pre-allocate workspace structure
rho1_grp1 = zeros(1, 1, N); rho1_grp2 = zeros(1, 1, N);
rho1_grp3 = zeros(1, 1, N); rho1_grp4 = zeros(1, 1, N);
rho2_grp1 = zeros(1, 1, N); rho2_grp2 = zeros(1, 1, N);
rho2_grp3 = zeros(1, 1, N); rho2_grp4 = zeros(1, 1, N);
rho1_cells = {rho1_grp1, rho1_grp2, rho1_grp3, rho1_grp4};
rho2_cells = {rho2_grp1, rho2_grp2, rho2_grp3, rho2_grp4};

for g = 1:4
    base_cons = groups_NA5_base{g}(1:34); % 1 x 34 (1990–2023)

    % --- Phase 1: NA5 1990–2021 (Indices 1:32) ---
    rho1_vec = rho1_min + (1 - rho1_min) * betarnd(2, 2, N, 1);
    rho1_cells{g}(1, 1, :) = rho1_vec;
    Zm1 = zeros(N, 32);
    Zm1(:, 1) = randn(N, 1);
    for t = 2:32
        Zm1(:, t) = rho1_vec .* Zm1(:, t-1) + sqrt(1 - rho1_vec.^2) .* randn(N, 1);
    end

    % --- Phase 2: NA5 2022–2023 (Indices 33:34) ---
    rho2_vec = rho2_min + (1 - rho2_min) * betarnd(2, 2, N, 1);
    rho2_cells{g}(1, 1, :) = rho2_vec;
    Zm2 = zeros(N, 2);
    Zm2(:, 1) = randn(N, 1);
    Zm2(:, 2) = rho2_vec .* Zm2(:, 1) + sqrt(1 - rho2_vec.^2) .* randn(N, 1);

    % Combine correlated noise matrix [N x 34]
    Zm_NA5 = [Zm1, Zm2];

    % --- Map Gaussian Noise to Lognormal via Probability Integral Transform ---
    % 1. Convert standard normal Z draws into uniform percentiles U in (0,1)
    U_NA5 = normcdf(Zm_NA5);

    % 2. Calculate time-dependent sigmoid weights and shape parameters (1 x 34)
    w_t = 1 ./ (1 + exp(-(base_cons - threshold_cons) / scale_width));
    sigma_log_t = (1 - w_t) * sigma_log_early + w_t * sigma_log_late;

    % 3. Set lognormal mean parameter so median stays at base_cons
    mu_log_t = log(base_cons); 

    % 4. Apply inverse Lognormal CDF to generate non-negative skewed ensemble
    cons_mat = zeros(N, 34);
    for t = 1:34
        cons_mat(:, t) = icdf('Lognormal', U_NA5(:, t), mu_log_t(t), sigma_log_t(t));
    end

    cons_NA5_out{g} = cons_mat;
end

% Assign back to original workspace arrays
cons_grp1_NA5 = cons_NA5_out{1}; rho1_grp1 = rho1_cells{1}; rho2_grp1 = rho2_cells{1};
cons_grp2_NA5 = cons_NA5_out{2}; rho1_grp2 = rho1_cells{2}; rho2_grp2 = rho2_cells{2};
cons_grp3_NA5 = cons_NA5_out{3}; rho1_grp3 = rho1_cells{3}; rho2_grp3 = rho2_cells{3};
cons_grp4_NA5 = cons_NA5_out{4}; rho1_grp4 = rho1_cells{4}; rho2_grp4 = rho2_cells{4};

% =========================================================================
% 2. ARTICLE 5 (A5) CONSUMPTION (1990–2023)
% =========================================================================
groups_A5_base = {cons_A5_grp1, cons_A5_grp2, cons_A5_grp3, cons_A5_grp4};
cons_A5_out    = cell(1, 4);

rho3_grp1 = zeros(1, 1, N); rho3_grp2 = zeros(1, 1, N);
rho3_grp3 = zeros(1, 1, N); rho3_grp4 = zeros(1, 1, N);
rho3_cells = {rho3_grp1, rho3_grp2, rho3_grp3, rho3_grp4};

for g = 1:4
    base_cons = groups_A5_base{g}(1:34); % 1 x 34 (1990–2023)

    % --- Main AR(1) Correlation (1990–2023) ---
    rho3_vec = rho3_min + (1 - rho3_min) * betarnd(2, 2, N, 1);
    rho3_cells{g}(1, 1, :) = rho3_vec;
    Zm_A5 = zeros(N, 34);
    Zm_A5(:, 1) = randn(N, 1);
    for t = 2:34
        Zm_A5(:, t) = rho3_vec .* Zm_A5(:, t-1) + sqrt(1 - rho3_vec.^2) .* randn(N, 1);
    end

    % --- Uncorrelated 2022 Spike (Index 33) ---
    Zm_A5(:, 33) = randn(N, 1);

    % --- Map Gaussian Noise to Lognormal via Probability Integral Transform ---
    U_A5 = normcdf(Zm_A5);

    w_t = 1 ./ (1 + exp(-(base_cons - threshold_cons) / scale_width));
    sigma_log_t = (1 - w_t) * sigma_log_early + w_t * sigma_log_late;
    mu_log_t = log(base_cons);

    cons_mat = zeros(N, 34);
    for t = 1:34
        cons_mat(:, t) = icdf('Lognormal', U_A5(:, t), mu_log_t(t), sigma_log_t(t));
    end

    cons_A5_out{g} = cons_mat;
end

% Assign back to original workspace arrays
cons_grp1_A5 = cons_A5_out{1}; rho3_grp1 = rho3_cells{1};
cons_grp2_A5 = cons_A5_out{2}; rho3_grp2 = rho3_cells{2};
cons_grp3_A5 = cons_A5_out{3}; rho3_grp3 = rho3_cells{3};
cons_grp4_A5 = cons_A5_out{4}; rho3_grp4 = rho3_cells{4};


cons_grp1_NA5(cons_grp1_NA5<0) = 0;
cons_grp2_NA5(cons_grp2_NA5<0) = 0;
cons_grp3_NA5(cons_grp3_NA5<0) = 0;
cons_grp4_NA5(cons_grp4_NA5<0) = 0;

cons_grp1_A5(cons_grp1_A5<0) = 0;
cons_grp2_A5(cons_grp2_A5<0) = 0;
cons_grp3_A5(cons_grp3_A5<0) = 0;
cons_grp4_A5(cons_grp4_A5<0) = 0;

%% Uncertainty analyses 1–2

if uncertainty_analysis == 1 % No consumption uncertainty
    cons_grp1_NA5 = repmat(cons_NA5_grp1,N,1);
    cons_grp2_NA5 = repmat(cons_NA5_grp2,N,1);
    cons_grp3_NA5 = repmat(cons_NA5_grp3,N,1);
    cons_grp4_NA5 = repmat(cons_NA5_grp4,N,1);

    cons_grp1_A5 = repmat(cons_A5_grp1,N,1);
    cons_grp2_A5 = repmat(cons_A5_grp2,N,1);
    cons_grp3_A5 = repmat(cons_A5_grp3,N,1);
    cons_grp4_A5 = repmat(cons_A5_grp4,N,1);
end

if uncertainty_analysis == 2 % No emission factor uncertainty
    DE_grp1 = repmat(grp1_DE_mode,N,1);
    DE_grp2 = repmat(grp2_DE_mode,N,1);
    DE_grp3 = repmat(grp3_DE_mode,N,1);
    DE_grp4 = repmat(grp4_DE_mode,N,1);

    RF_grp1 = repmat(grp1_RF_mode,N,1);
    RF_grp2 = repmat(grp2_RF_mode,N,1);
    RF_grp3 = repmat(grp3_RF_mode,N,1);
    RF_grp4 = repmat(grp4_RF_mode,N,1);
end

disp('Consumption priors done')

%% Model emissions and banks

% Year one (1990) banks and emissions 
yr = 1; 

emiss_grp1_NA5(:,yr) = DE_grp1 .* cons_grp1_NA5(:,yr);
emiss_grp2_NA5(:,yr) = DE_grp2 .* cons_grp2_NA5(:,yr);
emiss_grp3_NA5(:,yr) = DE_grp3 .* cons_grp3_NA5(:,yr);
emiss_grp4_NA5(:,yr) = DE_grp4 .* cons_grp4_NA5(:,yr);

emiss_grp1_A5(:,yr) = DE_grp1 .* cons_grp1_A5(:,yr);
emiss_grp2_A5(:,yr) = DE_grp2 .* cons_grp2_A5(:,yr);
emiss_grp3_A5(:,yr) = DE_grp3 .* cons_grp3_A5(:,yr);
emiss_grp4_A5(:,yr) = DE_grp4 .* cons_grp4_A5(:,yr);

bank_grp1_NA5(:,yr) = (1-DE_grp1) .* cons_grp1_NA5(:,yr);
bank_grp2_NA5(:,yr) = (1-DE_grp2) .* cons_grp2_NA5(:,yr);
bank_grp3_NA5(:,yr) = (1-DE_grp3) .* cons_grp3_NA5(:,yr);
bank_grp4_NA5(:,yr) = (1-DE_grp4) .* cons_grp4_NA5(:,yr);

bank_grp1_A5(:,yr) = (1-DE_grp1) .* cons_grp1_A5(:,yr);
bank_grp2_A5(:,yr) = (1-DE_grp2) .* cons_grp2_A5(:,yr);
bank_grp3_A5(:,yr) = (1-DE_grp3) .* cons_grp3_A5(:,yr);
bank_grp4_A5(:,yr) = (1-DE_grp4) .* cons_grp4_A5(:,yr);

% Years 2–n Banks (1991–2020)
for yr = 2:width(cons_NA5_grp1)

    emiss_grp1_NA5(:,yr) =   DE_grp1 .* cons_grp1_NA5(:,yr) + RF_grp1 .* bank_grp1_NA5(:,yr-1);
    emiss_grp2_NA5(:,yr) =   DE_grp2 .* cons_grp2_NA5(:,yr) + RF_grp2 .* bank_grp2_NA5(:,yr-1);
    emiss_grp3_NA5(:,yr) =   DE_grp3 .* cons_grp3_NA5(:,yr) + RF_grp3 .* bank_grp3_NA5(:,yr-1);
    emiss_grp4_NA5(:,yr) =   DE_grp4 .* cons_grp4_NA5(:,yr) + RF_grp4 .* bank_grp4_NA5(:,yr-1);

    emiss_grp1_A5(:,yr) =   DE_grp1 .* cons_grp1_A5(:,yr) + RF_grp1 .* bank_grp1_A5(:,yr-1);
    emiss_grp2_A5(:,yr) =   DE_grp2 .* cons_grp2_A5(:,yr) + RF_grp2 .* bank_grp2_A5(:,yr-1);
    emiss_grp3_A5(:,yr) =   DE_grp3 .* cons_grp3_A5(:,yr) + RF_grp3 .* bank_grp3_A5(:,yr-1);
    emiss_grp4_A5(:,yr) =   DE_grp4 .* cons_grp4_A5(:,yr) + RF_grp4 .* bank_grp4_A5(:,yr-1);

    bank_grp1_NA5(:,yr) = (1-DE_grp1) .* cons_grp1_NA5(:,yr) + (1-RF_grp1) .* bank_grp1_NA5(:,yr-1);
    bank_grp2_NA5(:,yr) = (1-DE_grp2) .* cons_grp2_NA5(:,yr) + (1-RF_grp2) .* bank_grp2_NA5(:,yr-1);
    bank_grp3_NA5(:,yr) = (1-DE_grp3) .* cons_grp3_NA5(:,yr) + (1-RF_grp3) .* bank_grp3_NA5(:,yr-1);
    bank_grp4_NA5(:,yr) = (1-DE_grp4) .* cons_grp4_NA5(:,yr) + (1-RF_grp4) .* bank_grp4_NA5(:,yr-1);

    bank_grp1_A5(:,yr) = (1-DE_grp1) .* cons_grp1_A5(:,yr) + (1-RF_grp1) .* bank_grp1_A5(:,yr-1);
    bank_grp2_A5(:,yr) = (1-DE_grp2) .* cons_grp2_A5(:,yr) + (1-RF_grp2) .* bank_grp2_A5(:,yr-1);
    bank_grp3_A5(:,yr) = (1-DE_grp3) .* cons_grp3_A5(:,yr) + (1-RF_grp3) .* bank_grp3_A5(:,yr-1);
    bank_grp4_A5(:,yr) = (1-DE_grp4) .* cons_grp4_A5(:,yr) + (1-RF_grp4) .* bank_grp4_A5(:,yr-1);
 
end

%% Totals

cons_NA5_prior = cons_grp1_NA5 + cons_grp2_NA5 + cons_grp3_NA5 + cons_grp4_NA5;
cons_A5_prior = cons_grp1_A5 + cons_grp2_A5 + cons_grp3_A5 + cons_grp4_A5;
cons_total = cons_NA5_prior + cons_A5_prior;

bank_NA5 = bank_grp1_NA5 + bank_grp2_NA5 + bank_grp3_NA5 + bank_grp4_NA5;
bank_A5 = bank_grp1_A5 + bank_grp2_A5 + bank_grp3_A5 + bank_grp4_A5;
bank_total = bank_NA5 + bank_A5;

emiss_NA5 = emiss_grp1_NA5 + emiss_grp2_NA5 + emiss_grp3_NA5 + emiss_grp4_NA5;
emiss_A5 = emiss_grp1_A5 + emiss_grp2_A5 + emiss_grp3_A5 + emiss_grp4_A5;
emiss_total = emiss_NA5 + emiss_A5;

disp('Emissions and Banks simulated')

%% Two QC checks
  
% Make sure mass is conserved the whole time (within one tonne)
for i = 1:34
    MB_total(:,i) = sum(cons_total(:,1:i),2) - bank_total(:,i)...
        - sum(emiss_total(:,1:i),2);
end

if max(abs(MB_total),[],"all") > 1
    mass_check = "Failed";
else
    mass_check = "Passed";
end

% Make sure nothing is ever negative
min_check_array = [min(cons_grp1_NA5,[],"all"), min(cons_grp2_NA5,[],"all"),...
    min(cons_grp3_NA5,[],"all"), min(cons_grp4_NA5,[],"all"),...
    min(cons_grp1_A5,[],"all"), min(cons_grp2_A5,[],"all"),...
    min(cons_grp3_A5,[],"all"), min(cons_grp4_A5,[],"all"),...
    min(bank_grp1_NA5,[],"all"), min(bank_grp2_NA5,[],"all"),...
    min(bank_grp3_NA5,[],"all"), min(bank_grp4_NA5,[],"all"),...
    min(bank_grp1_A5,[],"all"), min(bank_grp2_A5,[],"all"),...
    min(bank_grp3_A5,[],"all"), min(bank_grp4_A5,[],"all"),...
    min(emiss_grp1_NA5,[],"all"), min(emiss_grp2_NA5,[],"all"),...
    min(emiss_grp3_NA5,[],"all"), min(emiss_grp4_NA5,[],"all"),...
    min(emiss_grp1_A5,[],"all"), min(emiss_grp2_A5,[],"all"),...
    min(emiss_grp3_A5,[],"all"), min(emiss_grp4_A5,[],"all")];

if min(min_check_array) < 0
    neg_check = "Failed";
else
    neg_check = "Passed";
end

if mass_check == "Passed" && neg_check == "Passed"
    QC_check = "Passed";
else
    QC_check = "Failed";
end

%% Establish atmospheric residence time priors
% From SPARC

if gas == "HFC-134a"
    rt = 1./(normrnd((1/14), (1/14 * .18), N, 1));
elseif gas == "HFC-143a"
    rt = 1./(normrnd((1/51), (1/51 * .19), N, 1));
end

if uncertainty_analysis == 3 % No uncertainty in atmospheric residence time
    if gas == "HFC-134a"
        rt = 14 * ones(N,1);
    elseif gas == "HFC-143a"
        rt = 51 * ones(N,1);
    end
end

% Read AGAGE data for 1990 to initialize the model
% AGAGE data is in ppt
AGAGE_yrs = 1990;
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

disp('AGAGE Year 1 read')

% Year one mole fractions
MF_total = zeros(N,35); % we assume MFs were 0 in 1990
MF_total(:,1) = normrnd(AGAGE_annual_means(1),AGAGE_annual_sd(1),N,1);
% Project mole fractions through 2024
for yr = 2:35
    MF_total(:,yr) = exp(-1./rt) .* MF_total(:,yr-1) + (1/ppt_to_Mg) .* emiss_total(:,yr-1) .* rt .* (1-exp(-1./rt));
end

disp('Atmospheric mole fraction projections complete')

save(fileName)