%%  KA Compliance and Non-Compliance Scenarios  %%

%%*****OPEN *BPE_output.mat* for desired gas (generated with BPE_HFCs) before running this script*****

% Upload KA phasedown trajectories by subgroup and country subgroup
% consumption proportions (calculated based on 2023 UNEP-reported
% consumption)
phasedown_dat = readtable("Input_data/KA_phasedowns.csv");

% Extract phasedown proportions for NA5 Group 1 2019-2074 and interpolate
NA5_1_phasedown_proportions = table2array(phasedown_dat(2,3:end));
NA5_1_phasedown_proportions = fillmissing(NA5_1_phasedown_proportions,"linear",2);

% Extract phasedown proportions for NA5 Group 2 2020-2074 and interpolate
NA5_2_phasedown_proportions = table2array(phasedown_dat(3,4:end));
NA5_2_phasedown_proportions = fillmissing(NA5_2_phasedown_proportions,"linear",2);

% Constrain both trajectories to 2023-2074
NA5_1_phasedown_proportions = NA5_1_phasedown_proportions(5:end);
NA5_2_phasedown_proportions = NA5_2_phasedown_proportions(4:end);

% Take weighted average of interpolated trajectories to define NA5 overall
% phasedown
NA5_phasedown_proportions = NA5_1_phasedown_proportions .* table2array(phasedown_dat(2,2))...
    + NA5_2_phasedown_proportions .* table2array(phasedown_dat(3,2));

% Extract phasedown proportions for A5 Group 1 2024-2074 and interpolate
A5_1_phasedown_proportions = table2array(phasedown_dat(4,8:end));
A5_1_phasedown_proportions = fillmissing(A5_1_phasedown_proportions,"linear",2);

% Extract phasedown proportions for A5 Group 2 2024-2074 and interpolate
A5_2_phasedown_proportions = table2array(phasedown_dat(5,8:end));
A5_2_phasedown_proportions = fillmissing(A5_2_phasedown_proportions,"linear",2);

% Take weighted average of interpolated trajectories to define A5 overall
% phasedown
A5_phasedown_proportions = A5_1_phasedown_proportions .* table2array(phasedown_dat(4,2))...
    + A5_2_phasedown_proportions .* table2array(phasedown_dat(5,2));

% Since the NA5 phasedown has already begun, we adjust 2023 consumption to
% a hypothetical "baseline" amount by dividing by the 2023 phasedown
% proportion.
NA5_phasedown_proportion_2023 = NA5_phasedown_proportions(1);

cons_NA5_grp1_baseline = cons_NA5_grp1(34) / NA5_phasedown_proportion_2023;
cons_NA5_grp2_baseline = cons_NA5_grp2(34) / NA5_phasedown_proportion_2023;
cons_NA5_grp3_baseline = cons_NA5_grp3(34) / NA5_phasedown_proportion_2023;
cons_NA5_grp4_baseline = cons_NA5_grp4(34) / NA5_phasedown_proportion_2023;

% Now constrain NA5 phasedown proportion vector to only 2024-2075
NA5_phasedown_proportions = NA5_phasedown_proportions(2:end);

% For A5, the freeze starts in 2024, so the "baseline" is the 2023
% consumption
cons_A5_grp1_baseline = cons_A5_grp1(34);
cons_A5_grp2_baseline = cons_A5_grp2(34);
cons_A5_grp3_baseline = cons_A5_grp3(34);
cons_A5_grp4_baseline = cons_A5_grp4(34);

if sensitivity_analysis == 1
    % Sensitivity test does not affect future consumption scenarios
    cons_A5_grp1_baseline = cons_A5_grp1_2023_original;
    cons_A5_grp2_baseline = cons_A5_grp2_2023_original;
    cons_A5_grp3_baseline = cons_A5_grp3_2023_original;
    cons_A5_grp4_baseline = cons_A5_grp4_2023_original;
end

if sensitivity_analysis == 2

    % Phasedown is based on 1.27x 2023 consumption, which is never achieved
    cons_A5_grp1_baseline = cons_A5_grp1(34)*1.27;
    cons_A5_grp2_baseline = cons_A5_grp2(34)*1.27;
    cons_A5_grp3_baseline = cons_A5_grp3(34)*1.27;
    cons_A5_grp4_baseline = cons_A5_grp4(34)*1.27;
    
end

% Set first 34 years of banks and emissions to historical posteriors
    % NA5 countries
    KA_bank_grp1_NA5 = bank_grp1_NA5(ResampleIndex,:);
    KA_bank_grp2_NA5 = bank_grp2_NA5(ResampleIndex,:);
    KA_bank_grp3_NA5 = bank_grp3_NA5(ResampleIndex,:);
    KA_bank_grp4_NA5 = bank_grp4_NA5(ResampleIndex,:);
    
    % A5 countries
    KA_bank_grp1_A5 = bank_grp1_A5(ResampleIndex,:);
    KA_bank_grp2_A5 = bank_grp2_A5(ResampleIndex,:);
    KA_bank_grp3_A5 = bank_grp3_A5(ResampleIndex,:);
    KA_bank_grp4_A5 = bank_grp4_A5(ResampleIndex,:);
    
    % Set first 34 years of emissions to historical posteriors
    % NA5 countries
    KA_emiss_grp1_NA5 = emiss_grp1_NA5(ResampleIndex,:);
    KA_emiss_grp2_NA5 = emiss_grp2_NA5(ResampleIndex,:);
    KA_emiss_grp3_NA5 = emiss_grp3_NA5(ResampleIndex,:);
    KA_emiss_grp4_NA5 = emiss_grp4_NA5(ResampleIndex,:);
    
    % A5 countries
    KA_emiss_grp1_A5 = emiss_grp1_A5(ResampleIndex,:);
    KA_emiss_grp2_A5 = emiss_grp2_A5(ResampleIndex,:);
    KA_emiss_grp3_A5 = emiss_grp3_A5(ResampleIndex,:);
    KA_emiss_grp4_A5 = emiss_grp4_A5(ResampleIndex,:);

% MCW: need to clear up memory for the remaining analysis, so I clear unused
% variables
% save resampled MF_total before deleting
MF_total_resamp = MF_total(ResampleIndex,:);
% clear out large arrays unused beyond this point in code
clear emiss_grp1_A5 emiss_grp2_A5 emiss_grp3_A5 emiss_grp4_A5
clear emiss_grp1_NA5 emiss_grp2_NA5 emiss_grp3_NA5 emiss_grp4_NA5
clear bank_grp1_A5 bank_grp2_A5 bank_grp3_A5 bank_grp4_A5
clear bank_grp1_NA5 bank_grp2_NA5 bank_grp3_NA5 bank_grp4_NA5
clear bank_NA5 bank_A5 bank_total emiss_NA5 emiss_A5 emiss_total
clear rho1_grp1 rho1_grp2 rho1_grp3 rho1_grp4
clear rho2_grp1 rho2_grp2 rho2_grp3 rho2_grp4
clear rho3_grp1 rho3_grp2 rho3_grp3 rho3_grp4
clear rho4 Rhom MF_total MF_sd_prior likelihood IR_vec1
clear cons_A5_prior cons_NA5_prior cons_total

%% Scenarios

yrs = 2024:2074;

% parameter arrays to set up breach scenarios
if uncertainty_analysis > 0 || sensitivity_analysis > 0
    numRuns = [20]; % number of non-compliant scenarios to test between 0 and 100%, setting granularity of analysis
    period = [2024 2074];
    scenario = [0]; % 0: proportional, 1: Business-as-usual, 2: Growth
else
    numRuns = [20, 20, 20, 20, 20]; % number of non-compliant scenarios to test between 0 and 100%, setting granularity of analysis
    period = [2024 2074; 2024 2074; 2024 2074; 2030 2039; 2050 2059;];
    scenario = [0, 1, 2, 0, 0]; % 0: proportional, 1: Business-as-usual, 2: Growth
end

growth_rate = 0.05; % annual growth rate as percentage of 2024 consumption for fraction of market under growth

numRuns = numRuns + 1; % add one for compliant scenario

growth_years = 0:(length(NA5_phasedown_proportions)-1);

for ii = 1:length(scenario)
    switch scenario(ii)
        case 0
            scenName = 'Proportional';
        case 1
            scenName = 'Business-as-usual';
        case 2
            scenName = 'Growth';
    end
    for i = 1:numRuns(ii) % Steady; some percentage of global consumption remains constant  projection, i.e. "business-as-usual"
        
        % MCW: coefficients for altering consumption relative to KA-compliant
        % magnitudes. MUST UPDATE 5 TO GENERALIZE FOR ANY GRANULARITY
        switch scenario(ii)
            case 0
                c1 = 0;
                c2 = (1+(i*5-5)/100);
            case 1
                c1 = (i*5-5)/100;
                c2 = (1-(i*5-5)/100);
            case 2
                c1 = (i*5-5)/100.*(1+growth_rate*growth_years);
                c2 = (1-(i*5-5)/100);
        end

        % Multiply the "baselines" by the proportional phasedowns to get
        % consumption projections (Needs to get reset for each loop)
        KA_cons_grp1_NA5_tmp = cons_NA5_grp1_baseline .* NA5_phasedown_proportions;
        KA_cons_grp2_NA5_tmp = cons_NA5_grp2_baseline .* NA5_phasedown_proportions;
        KA_cons_grp3_NA5_tmp = cons_NA5_grp3_baseline .* NA5_phasedown_proportions;
        KA_cons_grp4_NA5_tmp = cons_NA5_grp4_baseline .* NA5_phasedown_proportions;
        
        KA_cons_grp1_A5_tmp = cons_A5_grp1_baseline .* A5_phasedown_proportions;
        KA_cons_grp2_A5_tmp = cons_A5_grp2_baseline .* A5_phasedown_proportions;
        KA_cons_grp3_A5_tmp = cons_A5_grp3_baseline .* A5_phasedown_proportions;
        KA_cons_grp4_A5_tmp = cons_A5_grp4_baseline .* A5_phasedown_proportions;

        if sensitivity_analysis == 2
        
            % Add 2023 consumption at the beginning of the vector for interpolation
            % purposes
            KA_cons_grp1_A5_tmp_w2023 = [cons_A5_grp1(34) KA_cons_grp1_A5_tmp];
            KA_cons_grp2_A5_tmp_w2023 = [cons_A5_grp2(34) KA_cons_grp2_A5_tmp];
            KA_cons_grp3_A5_tmp_w2023 = [cons_A5_grp3(34) KA_cons_grp3_A5_tmp];
            KA_cons_grp4_A5_tmp_w2023 = [cons_A5_grp4(34) KA_cons_grp4_A5_tmp];
        
            % Clear 2024-2028 consumption
            KA_cons_grp1_A5_tmp_w2023(2:6) = NaN;
            KA_cons_grp2_A5_tmp_w2023(2:6) = NaN;
            KA_cons_grp3_A5_tmp_w2023(2:6) = NaN;
            KA_cons_grp4_A5_tmp_w2023(2:6) = NaN;
        
            % Interpolate 2023-2029
            KA_cons_grp1_A5_tmp_w2023 = fillmissing(KA_cons_grp1_A5_tmp_w2023,"linear",2);
            KA_cons_grp2_A5_tmp_w2023 = fillmissing(KA_cons_grp2_A5_tmp_w2023,"linear",2);
            KA_cons_grp3_A5_tmp_w2023 = fillmissing(KA_cons_grp3_A5_tmp_w2023,"linear",2);
            KA_cons_grp4_A5_tmp_w2023 = fillmissing(KA_cons_grp4_A5_tmp_w2023,"linear",2);
        
            % Get rid of 2023 consumption at the beginning of vector
            KA_cons_grp1_A5_tmp = KA_cons_grp1_A5_tmp_w2023(2:end);
            KA_cons_grp2_A5_tmp = KA_cons_grp2_A5_tmp_w2023(2:end);
            KA_cons_grp3_A5_tmp = KA_cons_grp3_A5_tmp_w2023(2:end);
            KA_cons_grp4_A5_tmp = KA_cons_grp4_A5_tmp_w2023(2:end);
        
            clear KA_cons_grp1_A5_tmp_w2023 KA_cons_grp2_A5_tmp_w2023...
                KA_cons_grp3_A5_tmp_w2023 KA_cons_grp4_A5_tmp_w2023
        
        end
        
        breach_period = find((yrs >= period(ii,1)).*(yrs <= period(ii,2)));
        % modify the projections based on the non-compliance scenario
        KA_cons_grp1_NA5_tmp(breach_period) = c1.*KA_cons_grp1_NA5_tmp(breach_period(1)) + c2.*KA_cons_grp1_NA5_tmp(breach_period);
        KA_cons_grp2_NA5_tmp(breach_period) = c1.*KA_cons_grp2_NA5_tmp(breach_period(1)) + c2.*KA_cons_grp2_NA5_tmp(breach_period);
        KA_cons_grp3_NA5_tmp(breach_period) = c1.*KA_cons_grp3_NA5_tmp(breach_period(1)) + c2.*KA_cons_grp3_NA5_tmp(breach_period);
        KA_cons_grp4_NA5_tmp(breach_period) = c1.*KA_cons_grp4_NA5_tmp(breach_period(1)) + c2.*KA_cons_grp4_NA5_tmp(breach_period);
        
        KA_cons_grp1_A5_tmp(breach_period) = c1.*KA_cons_grp1_A5_tmp(breach_period(1)) + c2.*KA_cons_grp1_A5_tmp(breach_period);
        KA_cons_grp2_A5_tmp(breach_period) = c1.*KA_cons_grp2_A5_tmp(breach_period(1)) + c2.*KA_cons_grp2_A5_tmp(breach_period);
        KA_cons_grp3_A5_tmp(breach_period) = c1.*KA_cons_grp3_A5_tmp(breach_period(1)) + c2.*KA_cons_grp3_A5_tmp(breach_period);
        KA_cons_grp4_A5_tmp(breach_period) = c1.*KA_cons_grp4_A5_tmp(breach_period(1)) + c2.*KA_cons_grp4_A5_tmp(breach_period);
        
        % Combine first 34 years with final 52 years, NA5 countries
        KA_cons_grp1_NA5 = [cons_grp1_NA5 repmat(KA_cons_grp1_NA5_tmp,N,1)];
        KA_cons_grp2_NA5 = [cons_grp2_NA5 repmat(KA_cons_grp2_NA5_tmp,N,1)];
        KA_cons_grp3_NA5 = [cons_grp3_NA5 repmat(KA_cons_grp3_NA5_tmp,N,1)];
        KA_cons_grp4_NA5 = [cons_grp4_NA5 repmat(KA_cons_grp4_NA5_tmp,N,1)];
        
        % Constrain to posterior
        KA_cons_grp1_NA5 = KA_cons_grp1_NA5(ResampleIndex,:);
        KA_cons_grp2_NA5 = KA_cons_grp2_NA5(ResampleIndex,:);
        KA_cons_grp3_NA5 = KA_cons_grp3_NA5(ResampleIndex,:);
        KA_cons_grp4_NA5 = KA_cons_grp4_NA5(ResampleIndex,:);
        
        % Combine first 34 years with final 52 years, A5 countries
        KA_cons_grp1_A5 = [cons_grp1_A5 repmat(KA_cons_grp1_A5_tmp,N,1)];
        KA_cons_grp2_A5 = [cons_grp2_A5 repmat(KA_cons_grp2_A5_tmp,N,1)];
        KA_cons_grp3_A5 = [cons_grp3_A5 repmat(KA_cons_grp3_A5_tmp,N,1)];
        KA_cons_grp4_A5 = [cons_grp4_A5 repmat(KA_cons_grp4_A5_tmp,N,1)];
        
        % Constrain to posterior
        KA_cons_grp1_A5 = KA_cons_grp1_A5(ResampleIndex,:);
        KA_cons_grp2_A5 = KA_cons_grp2_A5(ResampleIndex,:);
        KA_cons_grp3_A5 = KA_cons_grp3_A5(ResampleIndex,:);
        KA_cons_grp4_A5 = KA_cons_grp4_A5(ResampleIndex,:);
        
        %% Model emissions and banks
        
        % Projecting emissions and banks forward (2024 - 2075)
        for yr = 35:width(KA_cons_grp1_NA5)
        
            KA_emiss_grp1_NA5(:,yr) =   DE_grp1(ResampleIndex) .* KA_cons_grp1_NA5(:,yr) + RF_grp1(ResampleIndex) .* KA_bank_grp1_NA5(:,yr-1);
            KA_emiss_grp2_NA5(:,yr) =   DE_grp2(ResampleIndex) .* KA_cons_grp2_NA5(:,yr) + RF_grp2(ResampleIndex) .* KA_bank_grp2_NA5(:,yr-1);
            KA_emiss_grp3_NA5(:,yr) =   DE_grp3(ResampleIndex) .* KA_cons_grp3_NA5(:,yr) + RF_grp3(ResampleIndex) .* KA_bank_grp3_NA5(:,yr-1);
            KA_emiss_grp4_NA5(:,yr) =   DE_grp4(ResampleIndex) .* KA_cons_grp4_NA5(:,yr) + RF_grp4(ResampleIndex) .* KA_bank_grp4_NA5(:,yr-1);
        
            KA_emiss_grp1_A5(:,yr) =   DE_grp1(ResampleIndex) .* KA_cons_grp1_A5(:,yr) + RF_grp1(ResampleIndex) .* KA_bank_grp1_A5(:,yr-1);
            KA_emiss_grp2_A5(:,yr) =   DE_grp2(ResampleIndex) .* KA_cons_grp2_A5(:,yr) + RF_grp2(ResampleIndex) .* KA_bank_grp2_A5(:,yr-1);
            KA_emiss_grp3_A5(:,yr) =   DE_grp3(ResampleIndex) .* KA_cons_grp3_A5(:,yr) + RF_grp3(ResampleIndex) .* KA_bank_grp3_A5(:,yr-1);
            KA_emiss_grp4_A5(:,yr) =   DE_grp4(ResampleIndex) .* KA_cons_grp4_A5(:,yr) + RF_grp4(ResampleIndex) .* KA_bank_grp4_A5(:,yr-1);
        
            KA_bank_grp1_NA5(:,yr) = (1-DE_grp1(ResampleIndex)) .* KA_cons_grp1_NA5(:,yr) + (1-RF_grp1(ResampleIndex)) .* KA_bank_grp1_NA5(:,yr-1);
            KA_bank_grp2_NA5(:,yr) = (1-DE_grp2(ResampleIndex)) .* KA_cons_grp2_NA5(:,yr) + (1-RF_grp2(ResampleIndex)) .* KA_bank_grp2_NA5(:,yr-1);
            KA_bank_grp3_NA5(:,yr) = (1-DE_grp3(ResampleIndex)) .* KA_cons_grp3_NA5(:,yr) + (1-RF_grp3(ResampleIndex)) .* KA_bank_grp3_NA5(:,yr-1);
            KA_bank_grp4_NA5(:,yr) = (1-DE_grp4(ResampleIndex)) .* KA_cons_grp4_NA5(:,yr) + (1-RF_grp4(ResampleIndex)) .* KA_bank_grp4_NA5(:,yr-1);
        
            KA_bank_grp1_A5(:,yr) = (1-DE_grp1(ResampleIndex)) .* KA_cons_grp1_A5(:,yr) + (1-RF_grp1(ResampleIndex)) .* KA_bank_grp1_A5(:,yr-1);
            KA_bank_grp2_A5(:,yr) = (1-DE_grp2(ResampleIndex)) .* KA_cons_grp2_A5(:,yr) + (1-RF_grp2(ResampleIndex)) .* KA_bank_grp2_A5(:,yr-1);
            KA_bank_grp3_A5(:,yr) = (1-DE_grp3(ResampleIndex)) .* KA_cons_grp3_A5(:,yr) + (1-RF_grp3(ResampleIndex)) .* KA_bank_grp3_A5(:,yr-1);
            KA_bank_grp4_A5(:,yr) = (1-DE_grp4(ResampleIndex)) .* KA_cons_grp4_A5(:,yr) + (1-RF_grp4(ResampleIndex)) .* KA_bank_grp4_A5(:,yr-1);
        
        end
        
        %% Total consumption, banks, and emissions
        
        KA_cons_NA5 = KA_cons_grp1_NA5 + KA_cons_grp2_NA5 + KA_cons_grp3_NA5 + KA_cons_grp4_NA5;
        KA_cons_A5 = KA_cons_grp1_A5 + KA_cons_grp2_A5 + KA_cons_grp3_A5 + KA_cons_grp4_A5;
        KA_cons_total = KA_cons_NA5 + KA_cons_A5;
        
        KA_bank_NA5 = KA_bank_grp1_NA5 + KA_bank_grp2_NA5 + KA_bank_grp3_NA5 + KA_bank_grp4_NA5;
        KA_bank_A5 = KA_bank_grp1_A5 + KA_bank_grp2_A5 + KA_bank_grp3_A5 + KA_bank_grp4_A5;
        KA_bank_total = KA_bank_NA5 + KA_bank_A5;
        
        KA_emiss_NA5 = KA_emiss_grp1_NA5 + KA_emiss_grp2_NA5 + KA_emiss_grp3_NA5 + KA_emiss_grp4_NA5;
        KA_emiss_A5 = KA_emiss_grp1_A5 + KA_emiss_grp2_A5 + KA_emiss_grp3_A5 + KA_emiss_grp4_A5;
        KA_emiss_total = KA_emiss_NA5 + KA_emiss_A5;
        
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%% Mole fraction simulation %%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Set first 35 years to historical MF posterior calculated previously 
        KA_MF_total = MF_total_resamp;
        
        % Years 2025 to 2075
        for yr = 36:width(KA_cons_grp1_NA5)+1
            KA_MF_total(:,yr) = exp(-1./rt(ResampleIndex)) .* KA_MF_total(:,yr-1)...
                + (1/ppt_to_Mg) .* KA_emiss_total(:,yr-1) .* rt(ResampleIndex) .* (1-exp(-1./rt(ResampleIndex)));
        end
        
        % when i==1, compliance
        projections.numRuns = numRuns(ii); % includes compliant scenario
        projections.period = period(ii,:);
        projections.scenario = scenName;
        projections.cons(i,:,:) = KA_cons_total;
        projections.emiss(i,:,:) = KA_emiss_total;
        projections.bank(i,:,:) = KA_bank_total;
        projections.MF(i,:,:) = KA_MF_total;
    
        disp(['Projections for ' scenName ' ' num2str(period(ii,1)) '-' num2str(period(ii,2)) ' ' num2str(5*i-5) '% completed'])
    
    end % of the loop through spectrum of noncompliance magnitudes
    disp('Saving results...')
    filename = [save_directory 'KA_projections/' 'projections_' char(gas) '_' scenName '_' num2str(period(ii,1)) '-' num2str(period(ii,2)) '_UA-' char(UA_setting) '_SA-' char(sens_setting) '.mat']
    save(filename,'projections','N','N_resamps','rho1_min','rho2_min','rho3_min','NA5_cons_adder','A5_cons_adder','MF_sd_max','gas','ResampleIndex','ppt_to_Mg','uncertainty_analysis','sensitivity_analysis','rt','-v7.3')
    disp('Save complete')
    clear projections
end % of loop through different scenarios

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compliance detection scheme %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

UB_percentile = 95;

if uncertainty_analysis > 0 || sensitivity_analysis > 0
    numRuns = [20]; % number of non-compliant scenarios to test between 0 and 100%, setting granularity of analysis
    period = [2024 2074];
    scenario = [0]; % 0: proportional, 1: Business-as-usual, 2: Growth
else
    numRuns = [20, 20, 20, 20, 20]; % number of non-compliant scenarios to test between 0 and 100%, setting granularity of analysis
    period = [2024 2074; 2024 2074; 2024 2074; 2030 2039; 2050 2059;];
    scenario = [0, 1, 2, 0, 0]; % 0: proportional, 1: Business-as-usual, 2: Growth
end

numRuns = numRuns + 1;

for ii = 1:length(scenario)
    switch scenario(ii)
        case 0
            scenName = 'Proportional';
        case 1
            scenName = 'Business-as-usual';
        case 2
            scenName = 'Growth';
    end

    filename = [save_directory 'KA_projections/' 'projections_' char(gas) '_' scenName '_' num2str(period(ii,1)) '-' num2str(period(ii,2)) '_UA-' char(UA_setting) '_SA-' char(sens_setting) '.mat'];
    load(filename)
    
    % first invert emissions from "observations"
    
    % Breach is defined based on UB_percentile of emissions (set at beginning
    % of code)
    compliant_emiss_thresh = prctile(squeeze(projections.emiss(1,:,:)),UB_percentile,1);
    
    % Calculate 1-sigma upper bound of atmsopheric lifetime
    if gas == "HFC-134a"
        %rt_1sigma = 14*1.18; % MCW: This is wrong! SPARC says 18% 1-sigma for 1/rt, not rt!
        rt_infer = 1/(1/14*0.82); % MCW: THIS is the correct 1-sigma upper-bound for rt
    elseif gas == "HFC-143a"
        %rt_1sigma = 51*1.19; % MCW: wrong for same reason as above
        rt_infer = 1/(1/51*0.81); % MCW: similar correction to above
    end
    
    if uncertainty_analysis == 3 % No uncertainty in atmospheric residence time
        if gas == "HFC-134a"
            rt_infer = 14;
        elseif gas == "HFC-143a"
            rt_infer = 51;
        end
    end

    if gas == "HFC-125"
        %rt_1sigma = 14*1.18; % MCW: This is wrong! SPARC says 18% 1-sigma for 1/rt, not rt!
        rt_infer = 1/(1/31*0.82); % MCW: THIS is the correct 1-sigma upper-bound for rt
    elseif gas == "HFC-32"
        %rt_1sigma = 51*1.19; % MCW: wrong for same reason as above
        rt_infer = 1/(1/5.4*0.83); % MCW: similar correction to above
    end
    
    if uncertainty_analysis == 3 % No uncertainty in atmospheric residence time
        if gas == "HFC-125"
            rt_infer = 31;
        elseif gas == "HFC-32"
            rt_infer = 5.4;
        end
    end
    
    % MCW: test detection scheme using various lifetimes
    rt_infer = prctile(rt(ResampleIndex),95);
    
    % In the scenario where A5 consumption is lower due to double counting and
    % researchers do not know this, the compliant upper bound is taken from a
    % previous run where A5 consumption is not assumed lower
    if sensitivity_analysis == 1
        if gas == "HFC-134a"
            tmp = load("Results/results_HFC-134a_2025716172851.mat");
            compliant_emiss_thresh = tmp.results.compliant_emiss_thresh;
        elseif gas == "HFC-143a"
            tmp = load("Results/results_HFC-143a_20257211183.mat");
            compliant_emiss_thresh = tmp.results.compliant_emiss_thresh;
        end
    end

    MF_obs = projections.MF;

    % set up storage matrices
    inferred_emiss_min = NaN(size(MF_obs,1),length(MF_obs(1)),width(MF_obs(1))-1);
        
    % Infer emissions for 1990–2074 (E = MF(t+1) - MF(t)*decay for emissions in year t)
    inferred_emiss_min = ppt_to_Mg*(MF_obs(:,:,2:end) - MF_obs(:,:,1:end-1)*exp(-1/rt_infer))/(rt_infer*(1-exp(-1/rt_infer)));
    
    % Detection sequence
    detect_frac_new_cumulative = NaN(size(MF_obs,1),width(2024:2074));
    detect_frac = NaN(size(MF_obs,1),width(2024:2074));
    for i = 1:numRuns(ii)
        
        % Identify years where emissions under noncompliance exceeds the 95th
        % percentile of emissions under compliance
        for iii = 1:size(inferred_emiss_min,3)
            detection_grid(i,:,iii) = inferred_emiss_min(i,:,iii)...
                > compliant_emiss_thresh(:,iii);
        end
    
        % Calculate cumulative proportion of ensemble members that have ever been considered in breach, 2024-2074
        % MCW: Alternatively, the probability of detecting a breach by year YYYY
        for t = 35:size(detection_grid,3)
            detect_frac_new_cumulative(i,t-34) = sum(sum(squeeze(detection_grid(i,:,34:t)),2)>0)/N_resamps;
            detect_frac(i,t-34) = squeeze(sum(detection_grid(i,:,t),2))/N_resamps;
        end
    
        detect_frac_new(i,1) = detect_frac_new_cumulative(i,1);
        detect_frac_new(i,2:51) = detect_frac_new_cumulative(i,2:end)-detect_frac_new_cumulative(i,1:end-1);
        detection_total(i) = sum(detect_frac_new(i,:));
    
    end
    
    disp('Saving detection results...')
    filename = [save_directory 'KA_detections/' 'detections_' char(gas) '_' scenName '_' num2str(period(ii,1)) '-' num2str(period(ii,2)) '_UA-' char(UA_setting) '_SA-' char(sens_setting) '.mat']
    save(filename,'compliant_emiss_thresh','rt_infer','inferred_emiss_min','detect_frac','detect_frac_new','detect_frac_new_cumulative','detection_total','detection_grid','-v7.3')
    disp('Save complete')
    clear projections
end

return % stop run before results and figures