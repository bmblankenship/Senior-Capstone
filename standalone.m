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

    %% Base Case NYI
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

    %% Generation Block Creator
    function [g_block, g_avail] = generate_block(block)
        g_blocks = table2array(readtable(CASE_SHEET, "sheet", "Gen"));
        g_block = [];
        g_avail = 0;

        for k = 1:height(g_blocks)
            if (g_blocks(k,22) == block)
                g_block(end+1,1) = g_blocks(k,1);
                g_block(end,2) = g_blocks(k,22);
                g_block(end,3) = g_blocks(k,9);
                g_avail = g_avail + g_blocks(k,9);
            end
        end
    end

    %% Block Dispatch Generator
    function [dispatch] = generate_block_dispatch()
        % generate_block_dispatch Generate 8760x5 array of block weightings
        % block 1 is highest priority
        % block 5 is lowest priority
        % Generates the dispatch for the entire year, meaning the array will need to be regenerated in the case that load changes
        % Regenerate by recalling the function with the new load added in
        
        % Import block references from proper excel sheet
        generation_blocks = table2array(readtable(CASE_SHEET, "sheet", "Gen"));

        % Return variable
        % Format is block 1 - 2 - 3 - 4 - 5 and will be percent utilization of that block
        dispatch = [zeros, 8760; zeros, 8760; zeros, 8760; zeros, 8760; zeros, 8760];

        % Block debugging variables
        assignin('base', 'gen_block_1', gen_block_1);
        assignin('base', 'gen_block_2', gen_block_2);
        assignin('base', 'gen_block_3', gen_block_3);
        assignin('base', 'gen_block_4', gen_block_4);
        assignin('base', 'gen_block_5', gen_block_5);
        assignin('base', 'generation_blocks', generation_blocks);
        
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
            if(current_load <= 0)
                dispatch(k,1) = 0;
            elseif(current_load - gen_block_1_avail < 0)
                extra_gen = gen_block_1_avail - current_load;
                dispatch(k,1) = (gen_block_1_avail - extra_gen) / gen_block_1_avail;
                current_load = 0;
            elseif(current_load - gen_block_1_avail > 0)
                current_load = current_load - gen_block_1_avail;
                dispatch(k,1) = 1;
            end

            % Dispatch Block 2
            if(current_load <= 0)
                dispatch(k,2) = 0;
            elseif(current_load - gen_block_2_avail < 0)
                extra_gen = gen_block_2_avail - current_load;
                dispatch(k,2) = (gen_block_2_avail - extra_gen) / gen_block_2_avail;
                current_load = 0;
            elseif(current_load - gen_block_2_avail > 0)
                current_load = current_load - gen_block_2_avail;
                dispatch(k,2) = 1;
            end

            % Dispatch Block 3
            if(current_load <= 0)
                dispatch(k,3) = 0;
            elseif(current_load - gen_block_3_avail < 0)
                extra_gen = gen_block_3_avail - current_load;
                dispatch(k,3) = (gen_block_3_avail - extra_gen) / gen_block_3_avail;
                current_load = 0;
            elseif(current_load - gen_block_3_avail > 0)
                current_load = current_load - gen_block_3_avail;
                dispatch(k,3) = 1;
            end

            % Dispatch Block 4
            if(current_load <= 0)
                dispatch(k,4) = 0;
            elseif(current_load - gen_block_4_avail < 0)
                extra_gen = gen_block_4_avail - current_load;
                dispatch(k,4) = (gen_block_4_avail - extra_gen) / gen_block_4_avail;
                current_load = 0;
            elseif(current_load - gen_block_4_avail > 0)
                current_load = current_load - gen_block_4_avail;
                dispatch(k,4) = 1;
            end

            % Dispatch Block 5
            if(current_load <= 0)
                dispatch(k,5) = 0;
            elseif(current_load - gen_block_5_avail < 0)
                extra_gen = gen_block_5_avail - current_load;
                dispatch(k,5) = (gen_block_5_avail - extra_gen) / gen_block_5_avail;
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

    %% error_handler NYI
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
    end
    
    %%n-1 contingency
    function [results_array, mpc_array] = n1_contingency(starthour,endhour,lineout) 
        results_array = [zeros,8760;zeros,height(mpc.branch)];

        for k = starthour:endhour
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

                %block dispatch
                temp_isl_mpc = gen_scale(temp_isl_mpc, block_dispatch, k, gen_block_1, gen_block_2, gen_block_3, gen_block_4, gen_block_5);
                
                %load scaling
                temp_isl_mpc.bus(:,3) = temp_isl_mpc.bus(:,3) * temp_load_data(k,2); %Real Power scaling
                temp_isl_mpc.bus(:,4) = temp_isl_mpc.bus(:,4) * temp_load_data(k,2); %Reactive power scaling

                results = runpf_wcu(temp_isl_mpc, mpopt);
                results_array(k,n) = limits_check(results);
                mpc_array(k,n) = temp_isl_mpc;
                
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
function [limit_check_return] = limits_check(mpc_case)

    MVA_success_flag = true;
    MVA_failure_branch = 'P';
    for n = 1:height(mpc_case.branch)
        if(~MVA_success_flag)
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
                MVA_failure_branch = int2str(n);
                MVA_success_flag = false;
            end
        end
    end

    voltage_success_flag = true;
    voltage_failure_bus = 'P';
    for n = 1:height(mpc_case.bus)
        if(~voltage_success_flag)
            break;
        elseif(mpc_case.bus(n,8) >= 1.1 && mpc_case.bus(n,8) <= 0.9)
            voltage_failure_bus = int2str(n);
            voltage_success_flag = false;
        end
    end
    failures = strcat(voltage_failure_bus, MVA_failure_branch);
    % Return format
    % MSB = Voltage Magnitude
    % LSB = MVA Magnitude
    if(~voltage_success_flag && ~MVA_success_flag)
        limit_check_return = strcat("00", failures);
    elseif(voltage_success_flag && ~MVA_success_flag)
        limit_check_return = strcat("10", failures);
    elseif(~voltage_success_flag && MVA_success_flag)
        limit_check_return = strcat("01", failures);
    else
        limit_check_return = strcat("11", failures);
    end

    assignin('base', 'VOLTAGE_SUCCESS_FLAG', voltage_success_flag);
    assignin('base', 'MVA_SUCCESS_FLAG', MVA_success_flag);
end

%% Generation Scaling
function scaled_generation = gen_scale(gen_mpc, gen_scaling, gen_hour, block_1, block_2, block_3, block_4, block_5)
    scaled_generation = gen_mpc;
    selector = 0;

    for blk = 1:height(scaled_generation.gen)
        if(selector == 0)
            for a = 1:height(block_1)
                if(scaled_generation.gen(blk,1) == block_1(a,1) && gen_scaling(gen_hour, 1) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 1);
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 1);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_1(a,1) && gen_scaling(gen_hour, 1) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        if(selector == 0)
            for a = 1:height(block_2)
                if(scaled_generation.gen(blk,1) == block_2(a,1) && gen_scaling(gen_hour, 2) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 2);
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 2);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_2(a,1) && gen_scaling(gen_hour, 2) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        if(selector == 0)
            for a = 1:height(block_3)
                if(scaled_generation.gen(blk,1) == block_3(a,1) && gen_scaling(gen_hour, 3) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 3);
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 3);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_3(a,1) && gen_scaling(gen_hour, 3) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        if(selector == 0)
            for a = 1:height(block_4)
                if(scaled_generation.gen(blk,1) == block_4(a,1) && gen_scaling(gen_hour, 4) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 4);
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 4);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_4(a,1) && gen_scaling(gen_hour, 4) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        if(selector == 0)
            for a = 1:height(block_5)
                if(scaled_generation.gen(blk,1) == block_5(a,1) && gen_scaling(gen_hour, 5) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 5);
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 5);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_5(a,1) && gen_scaling(gen_hour, 5) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        selector = 0;
    end
end