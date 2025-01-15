%{
    VERBOSE: integer value of 0, 1 or 2. Set to 0 for no output to console to increase simulation speed
    OUTAGE_SHEET: string for name of the outage sheet being used eg: 'RequiredOutages.xlsx'
    LOAD_SHEET: string for the name of the load sheet being used eg: 'HourlyLoad.xlsx'
    ALGORITHM_TYPE: string for which power flow algorithm will be used eg: 'NR'
    CASE_NAME: string for which case is being ran eg: 'case118_CAPER_PeakLoad.m'
    SIMULATION_HOURS: number of hours of the year to iterate over, maximum value 8760
    SIM_START_HOUR: hour index in year to start the simulation. Default should be 1 for most cases
    CASE_SHEET: The Excel sheet containing the original case data

    example function call:
    initialization(0, 'RequiredOutages.xlsx', 'HourlyLoad.xlsx', 'NR-SH', 'case118_CAPER_PeakLoad.m', 5, 1, 'InitialCaseData.xlsx');
%}

function initialization(VERBOSE, OUTAGE_SHEET, LOAD_SHEET, ALGORITHM_TYPE, CASE_NAME, SIMULATION_HOURS, SIM_START_HOUR, CASE_SHEET)
    tic;
        if(SIMULATION_HOURS > 8760)
            warning('Simulation Hours Specified are out of range (>8760). Setting to 8760.');
            SIMULATION_HOURS = 8760;
        end
        
        % mpc.gen(:,2)=mpc.gen(:,2); %generation scaling
        % mpc.bus(:,3)=mpc.bus(:,3); %Real Power scaling
        % mpc.bus(:,4)=mpc.bus(:,4); %Reactive power scaling
        
        % Options Initilization
        mpopt = mpoption('pf.alg', ALGORITHM_TYPE, 'verbose', VERBOSE);
        mpc = runpf_wcu(CASE_NAME, mpopt);
    
        % Load Data Initilization
        load_data = import_load_data(LOAD_SHEET);
    
        % Generation Initilization
        generation_outages = generator_outage(OUTAGE_SHEET, 'Generation');
        [gen_block_1, gen_block_1_avail] = generate_block(1);
        [gen_block_2, gen_block_2_avail] = generate_block(2);
        [gen_block_3, gen_block_3_avail] = generate_block(3);
        [gen_block_4, gen_block_4_avail] = generate_block(4);
        [gen_block_5, gen_block_5_avail] = generate_block(5);
        block_dispatch = generate_block_dispatch();
    
        % MATLAB debugging Variables
        assignin('base', 'mpc', mpc);
        assignin('base', 'generation_outages', generation_outages);
        assignin('base', 'load_data', load_data);
        assignin('base', 'block_dispatch', block_dispatch);
    
        %initial N-1 contingency to verify health of the system with planned generator outages
        [initial_results_array, initial_mpc_array] = n1_contingency(SIM_START_HOUR, SIMULATION_HOURS, -1);
        assignin('base', 'initial_results_array', initial_results_array);
        assignin('base', 'initial_mpc_array', initial_mpc_array);
    
        % Main Loop Framework Layout
        %{ 
            1) If the initial n-1 contingency is successful, go into scheduling algorithim
            2) With schedule generated, start into testing each outage case, testing n-1 contingency in their hourly scope
            3) If the schedule works, post to excel sheet and conclude simulation
            4) If schedule fails, regenerate schedule and make sure it is not the same schedule
        %}
    toc;
end
