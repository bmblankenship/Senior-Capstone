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
    standalone(0, 'RequiredOutages.xlsx', 'HourlyLoad.xlsx', 'NR-SH', 'case118_CAPER_PeakLoad.m', 5, 1, 'InitialCaseData.xlsx');
%}

%% Initialization
function standalone(VERBOSE, OUTAGE_SHEET, LOAD_SHEET, ALGORITHM_TYPE, CASE_NAME, SIMULATION_HOURS, SIM_START_HOUR, CASE_SHEET)
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
    block_dispatch = generate_block_dispatch();

    % MATLAB debugging Variables
    assignin('base', 'mpc', mpc);
    assignin('base', 'generation_outages', generation_outages);
    assignin('base', 'load_data', load_data);
    assignin('base', 'block_dispatch', block_dispatch);

    %initial N-1 contingency to verify health of the system with planned generator outages
    [initial_results_array] = n1_contingency(SIM_START_HOUR, SIMULATION_HOURS, -1);
    assignin('base', 'initial_results_array', initial_results_array);

    % Main Loop Framework Layout
    %{ 
        1) If the initial n-1 contingency is successful, go into scheduling algorithim
        2) With schedule generated, start into testing each outage case, testing n-1 contingency in their hourly scope
        3) If the schedule works, post to excel sheet and conclude simulation
        4) If schedule fails, regenerate schedule and make sure it is not the same schedule
    %}

    %
    % NOT YET IMPLEMENTED
    %
    %% Base Case Simulation
    function [base_case] = base_schedule_case(schedule)
        % Obtain the ranges that will be simulated from the schedule.
        % This avoids running hours again after the original N-1 contingency that do not need to be reran
        % Must be indexed to obtain the proper values later on.
        % Format:
        % Branch Number | Start Time | End Time

        base_case_branch_outages = schedule(branch_number);
        base_case_start_hours = schedule(start_time);
        base_case_end_hours = schedule(end_time);

        for i = 1:length(base_case_branch_outages) % Index through branches
        end
    end

    %% Block Dispatch Generator
    function [dispatch] = generate_block_dispatch()
        % generate_block_dispatch Generate 8760x5 array of block weightings
        % block 1 is highest priority
        % block 5 is lowest priority
        % Generates the dispatch for the entire year, meaning the array will need to be regenerated in the case that load changes
        
        % Import block references from proper excel sheet
        generation_blocks = table2array(readtable(CASE_SHEET, "sheet", "Gen"));

        % Return variable
        % Format is block 1 - 2 - 3 - 4 - 5 and will be percent utilization of that block
        dispatch = [zeros, 8760; zeros, 8760; zeros, 8760; zeros, 8760; zeros, 8760];

        gen_block_1 = [];
        gen_block_1_avail = 0;
        gen_block_2 = [];
        gen_block_2_avail = 0;
        gen_block_3 = [];
        gen_block_3_avail = 0;
        gen_block_4 = [];
        gen_block_4_avail = 0;
        gen_block_5 = [];
        gen_block_5_avail = 0;

        % Assign Generators to blocks
        %{
            gen_block_1->5 format:
            column 1: bus location
            column 2: dispatch block
            column 3: real power value of generator
        %}
        for k = 1:height(generation_blocks)
            switch generation_blocks(k,22)
            case 1
                gen_block_1(end+1,1) = generation_blocks(k,1);
                gen_block_1(end,2) = generation_blocks(k,22);
                gen_block_1(end,3) = generation_blocks(k,9);
                gen_block_1_avail = gen_block_1_avail + generation_blocks(k,9);
            case 2
                gen_block_2(end+1,1) = generation_blocks(k,1);
                gen_block_2(end,2) = generation_blocks(k,22);
                gen_block_2(end,3) = generation_blocks(k,9);
                gen_block_2_avail = gen_block_2_avail + generation_blocks(k,9);
            case 3
                gen_block_3(end+1,1) = generation_blocks(k,1);
                gen_block_3(end,2) = generation_blocks(k,22);
                gen_block_3(end,3) = generation_blocks(k,9);
                gen_block_3_avail = gen_block_3_avail + generation_blocks(k,9);
            case 4
                gen_block_4(end+1,1) = generation_blocks(k,1);
                gen_block_4(end,2) = generation_blocks(k,22);
                gen_block_4(end,3) = generation_blocks(k,9);
                gen_block_4_avail = gen_block_4_avail + generation_blocks(k,9);
            case 5
                gen_block_5(end+1,1) = generation_blocks(k,1);
                gen_block_5(end,2) = generation_blocks(k,22);
                gen_block_5(end,3) = generation_blocks(k,9);
                gen_block_5_avail = gen_block_5_avail + generation_blocks(k,9);
            end% End Switch
        end% End For Loop

        % Block debugging variables
        assignin('base', 'block_1', gen_block_1);
        assignin('base', 'block_2', gen_block_2);
        assignin('base', 'block_3', gen_block_3);
        assignin('base', 'block_4', gen_block_4);
        assignin('base', 'block_5', gen_block_5);
        assignin('base', 'gen_blocks', generation_blocks);
        
        % Iterate through all hours and assign dispatch values to each hour from 1 to 8760
        for k = 1:8760
            for j = 1:height(generation_outages)
                % Check if generation needs to be turned off for an outage
                if (generation_outages(j,2) == k)
                    block = generation_outages(j,4);
                    gen = generation_outages(j,1);

                    switch block
                    case 1
                        for b = 1:height(gen_block_1)
                            if(gen_block_1(b,1) == gen)
                                gen_block_1_avail = gen_block_1_avail - gen_block_1(b,3);
                            end
                        end
                    case 2
                        for b = 1:height(gen_block_2)
                            if(gen_block_2(b,1) == gen)
                                gen_block_2_avail = gen_block_2_avail - gen_block_2(b,3);
                            end
                        end
                    case 3
                        for b = 1:height(gen_block_3)
                            if(gen_block_3(b,1) == gen)
                                gen_block_3_avail = gen_block_3_avail - gen_block_3(b,3);
                            end
                        end
                    case 4
                        for b = 1:height(gen_block_4)
                            if(gen_block_4(b,1) == gen)
                                gen_block_4_avail = gen_block_4_avail - gen_block_4(b,3);
                            end
                        end
                    case 5
                        for b = 1:height(gen_block_5)
                            if(gen_block_5(b,1) == gen)
                                gen_block_5_avail = gen_block_5_avail - gen_block_5(b,3);
                            end
                        end
                    end% End Switch
                end % End if

                % Check if generation needs to be turned on after an outage
                if (generation_outages(j,2) + generation_outages(j,3) == k)
                    block = generation_outages(j,4);
                    gen = generation_outages(j,1);

                    switch block
                    case 1
                        for b = 1:height(gen_block_1)
                            if(gen_block_1(b,1) == gen)
                                gen_block_1_avail = gen_block_1_avail + gen_block_1(b,3);
                            end
                        end
                    case 2
                        for b = 1:height(gen_block_2)
                            if(gen_block_2(b,1) == gen)
                                gen_block_2_avail = gen_block_2_avail + gen_block_2(b,3);
                            end
                        end
                    case 3
                        for b = 1:height(gen_block_3)
                            if(gen_block_3(b,1) == gen)
                                gen_block_3_avail = gen_block_3_avail + gen_block_3(b,3);
                            end
                        end
                    case 4
                        for b = 1:height(gen_block_4)
                            if(gen_block_4(b,1) == gen)
                                gen_block_4_avail = gen_block_4_avail + gen_block_4(b,3);
                            end
                        end
                    case 5
                        for b = 1:height(gen_block_5)
                            if(gen_block_5(b,1) == gen)
                                gen_block_5_avail = gen_block_5_avail + gen_block_5(b,3);
                            end
                        end
                    end% End Switch
                end% End if
            end% End For

            % Compare load for this hour to the size of the availiable generation.
            % Assign a percentage of the block generation to each hour.

            current_load = load_data(k,1);
            extra_gen = 0;
            dispatch(k,1) = 0;
            dispatch(k,2) = 0;
            dispatch(k,3) = 0;
            dispatch(k,4) = 0;
            dispatch(k,5) = 0;

            % Dispatch Block 1
            if(current_load == 0)
                dispatch(k,1) = 0;
            elseif(current_load - gen_block_1_avail < 0)
                extra_gen = gen_block_1_avail - current_load;
                dispatch(k,1) = extra_gen / gen_block_1_avail;
                current_load = 0;
            elseif(current_load - gen_block_1_avail > 0)
                current_load = current_load - gen_block_1_avail;
                dispatch(k,1) = 1;
            end

            % Dispatch Block 2
            if(current_load == 0)
                dispatch(k,2) = 0;
            elseif(current_load - gen_block_2_avail < 0)
                extra_gen = gen_block_2_avail - current_load;
                dispatch(k,2) = extra_gen / gen_block_2_avail;
                current_load = 0;
            elseif(current_load - gen_block_2_avail > 0)
                current_load = current_load - gen_block_2_avail;
                dispatch(k,2) = 1;
            end

            % Dispatch Block 3
            if(current_load == 0)
                dispatch(k,3) = 0;
            elseif(current_load - gen_block_3_avail < 0)
                extra_gen = gen_block_3_avail - current_load;
                dispatch(k,3) = extra_gen / gen_block_3_avail;
                current_load = 0;
            elseif(current_load - gen_block_3_avail > 0)
                current_load = current_load - gen_block_3_avail;
                dispatch(k,3) = 1;
            end

            % Dispatch Block 4
            if(current_load == 0)
                dispatch(k,4) = 0;
            elseif(current_load - gen_block_4_avail < 0)
                extra_gen = gen_block_4_avail - current_load;
                dispatch(k,4) = extra_gen / gen_block_4_avail;
                current_load = 0;
            elseif(current_load - gen_block_4_avail > 0)
                current_load = current_load - gen_block_4_avail;
                dispatch(k,4) = 1;
            end

            % Dispatch Block 5
            if(current_load == 0)
                dispatch(k,5) = 0;
            elseif(current_load - gen_block_5_avail < 0)
                extra_gen = gen_block_5_avail - current_load;
                dispatch(k,5) = extra_gen / gen_block_5_avail;
                current_load = 0;
            elseif(current_load - gen_block_5_avail > 0)
                current_load = current_load - gen_block_5_avail;
                dispatch(k,5) = 1;
            end

            % Handle load being too high
            if(current_load > 0)
                warning('Load exceeds available generation for hour: %d', k);
            end
        end
    end

    %
    % NOT YET IMPLEMENTED
    %
    %% error_handler
    function error_handler()
    end

    %%generator outage
    function [generator_outage] = generator_outage(filename, tabname)
        generator_data = readtable(filename, "sheet", tabname);
        gen_block_data = table2array(readtable(CASE_SHEET, "sheet", "Gen"));
        
        bus = table2array(generator_data(:,1));
        gen_start_dates = table2array(generator_data(:,4));
        gen_outage_duration = table2array(generator_data(:,5));
        
        start_hours = [zeros, length(gen_start_dates)];
        end_hours = [zeros, length(gen_outage_duration)];

        for k = 1:length(gen_start_dates)
            d = day(gen_start_dates(k), 'dayofyear');
            start_hours(k) = d * 24;
        end
        
        for k = 1:length(gen_outage_duration)
            end_hours(k) = gen_outage_duration(k) * 168;
        end

        generator_outage = table2array(table(bus, transpose(start_hours), transpose(end_hours)));

        for k = 1:height(generator_outage)
            for j = 1:height(gen_block_data)
                if(gen_block_data(j,1) == generator_outage(k,1))
                    generator_outage(k,4) = gen_block_data(j,22);
                end
            end
        end
        %generator_outage = table2array (generator_outage);
    end
    
    %%n-1 contingency
    function [results_array] = n1_contingency(starthour,endhour,lineout) 
        results_array = [zeros,8760;zeros,height(mpc.branch)];

        for k = starthour:endhour
            if(mod(k, 10) == 0)
                disp(k);
            end
            %temporary variables for parallel functionality 
            tempmpc = mpc;
            temp_generation_outages = generation_outages;
            temp_load_data = load_data;

            for gens = 1: height(temp_generation_outages(:,1))
                gen_temp = temp_generation_outages(gens,1);
                gen_temp_start = temp_generation_outages(gens,2);
                gen_temp_end = temp_generation_outages(gens,3);
                
                switch gen_temp_start
                    case k
                        for i = 1: height(tempmpc.gen)
                            if tempmpc.gen(i,1) == gen_temp
                                tempmpc.gen(i,8) = 0;
                            end
                        end
                    case k + gen_temp_end + 1
                        for i = 1: height(tempmpc.gen)
                            if tempmpc.gen(i,1) == gen_temp
                                tempmpc.gen(i,8) = 1;
                            end
                        end
                end
            end%for loop

            for n = 1:height(tempmpc.branch)
                if(lineout ~= -1)%case where no line is selected
                    tempmpc.branch(lineout, 11) = 0;
                end
                tempmpc.branch(n,11) = 0;

                temp_isl_mpc = extract_islands(tempmpc, 1);

                % Need to replace with block dispatch
                temp_isl_mpc.gen(:,2) = temp_isl_mpc.gen(:,2) * temp_load_data(k,2); %generation scaling

                temp_isl_mpc.bus(:,3) = temp_isl_mpc.bus(:,3) * temp_load_data(k,2); %Real Power scaling
                temp_isl_mpc.bus(:,4) = temp_isl_mpc.bus(:,4) * temp_load_data(k,2); %Reactive power scaling

                results = runpf_wcu(temp_isl_mpc, mpopt);
                results_array(k,n) = limits_check(results);
                
                if(results_array(k,n) == 0)
                    assignin('base', 'global_success', 0);
                end
                tempmpc.branch(n,11) = 1;

            end %for loop
        end %parfor loop
        assignin('base', 'results_array', results_array);
    end 

    %%Load data Loader
    function [load_data_return] = import_load_data(LOAD_SHEET)
        load_data_table = readtable(LOAD_SHEET);
        load_data_return = [table2array(load_data_table(:,3)) , table2array(load_data_table(:,5))];
    end
toc;
end

%%limits calculation
function limit_check_return = limits_check(mpc_case)
    limit_check_return = 1;

    MVA_success_flag = true;
    for n = 1:height(mpc_case.branch)
        if(~MVA_success_flag)
            limit_check_return = 0;
            break;
        elseif(MVA_success_flag)
            s1 = sqrt(mpc_case.branch(n,14)^2 + mpc_case.branch(n,15)^2);
            s2 = sqrt(mpc_case.branch(n,16)^2 + mpc_case.branch(n,17)^2);
            if(s1 > s2)
                apparent_power = s1;
            else
                apparent_power = s2;
            end

            if(apparent_power > mpc_case.branch(n,6))
                MVA_success_flag = false;
            end
        end
    end
    assignin('base', 'MVA_SUCCESS_FLAG', MVA_success_flag);

    voltage_success_flag = true;
    for n = 1:height(mpc_case.gen)
        if(~voltage_success_flag)
            limit_check_return = 0;
            break;
        elseif(mpc_case.bus(n,8) >= 1.1 && mpc_case.bus(n,8) <= 0.9)
            voltage_success_flag = false;
        end
    end
    assignin('base', 'VOLTAGE_SUCCESS_FLAG', voltage_success_flag);
end