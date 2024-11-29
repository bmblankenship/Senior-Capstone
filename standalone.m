%{
    NUM_BRANCHES: integer value for the number of branches present on the system
    VERBOSE: integer value of 0, 1 or 2. Set to 0 for no output to console to increase simulation speed
    OUTAGE_SHEET: string for name of the outage sheet being used eg: 'RequiredOutages.xlsx'
    LOAD_SHEET: string for the name of the load sheet being used eg: 'HourlyLoad.xlsx'
    ALGORITHM_TYPE: string for which power flow algorithm will be used eg: 'NR'
    CASE_NAME: string for which case is being ran eg: 'case118_CAPER_PeakLoad.m'
    SIMULATION_HOURS: number of hours of the year to iterate over, maximum value 8760

    example function call:
    standalone(186, 0, 'RequiredOutages.xlsx', 'HourlyLoad.xlsx', 'NR', 'case118_CAPER_PeakLoad.m', 5, 1);
%}

function standalone(NUM_BRANCHES, VERBOSE, OUTAGE_SHEET, LOAD_SHEET, ALGORITHM_TYPE, CASE_NAME, SIMULATION_HOURS, SIM_START_HOUR)
tic;
    if(SIMULATION_HOURS > 8760)
        warning('Simulation Hours Specified are out of range (>8760). Setting to 8760.');
        SIMULATION_HOURS = 8760;
    end

    % mpc.gen(:,2)=mpc.gen(:,2); %generation scaling
    % mpc.bus(:,3)=mpc.bus(:,3); %Real Power scaling
    % mpc.bus(:,4)=mpc.bus(:,4); %Reactive power scaling
    
    %initialize system
    mpopt = mpoption('pf.alg', ALGORITHM_TYPE, 'verbose', VERBOSE);
    mpc = runpf_wcu(CASE_NAME, mpopt);
    generation_outages = generator_outage(OUTAGE_SHEET, 'Generation');
    load_data = import_load_data(LOAD_SHEET);
    assignin('base', 'mpc', mpc);
    assignin('base', 'generation_outages', generation_outages);
    assignin('base', 'load_data', load_data);
    %initial N-1 contingency to verify health of the system with planned generator outages
    [initial_n1, initial_line, initial_results_array] = n1_contingency(SIM_START_HOUR, SIMULATION_HOURS, -1);
    assignin('base', 'initial_n1', initial_n1);
    assignin('base', 'initial_line', initial_line);
    assignin('base', 'initial_results_array', initial_results_array);

    % Main Loop Framework Layout
    %{ 
        1) If the initial n-1 contingency is successful, go into scheduling algorithim
        2) With schedule generated, start into testing each outage case, testing n-1 contingency in their hourly scope
        3) If the schedule works, post to excel sheet and conclude simulation
        4) If schedule fails, regenerate schedule and make sure it is not the same schedule
    %}

    %generator outage
    function [generator_outage] = generator_outage(filename, tabname)
        generator_data = readtable(filename, "sheet", tabname);
        
        bus = table2array(generator_data(:,1));
        gen_start_dates = table2array(generator_data(:,4));
        gen_outage_duration = table2array(generator_data(:,5));
        
        start_hours = [zeros,length(gen_start_dates)];
        end_hours = [zeros, length(gen_outage_duration)];

        for k = 1:length(gen_start_dates)
            d = day(gen_start_dates(k), 'dayofyear');
            start_hours(k) = d * 24;
        end
        
        for k = 1:length(gen_outage_duration)
            end_hours(k) = gen_outage_duration(k) * 168;
        end

        generator_outage = table(bus, transpose(start_hours), transpose(end_hours));
        generator_outage = table2array (generator_outage);
    end
    
    %n-1 contingency
    function [n1, line, results_array] = n1_contingency(starthour,endhour,lineout) 
        %default values for return variables
        n1 = 1;
        line = 0;
        results_array = [zeros,NUM_BRANCHES;zeros,NUM_BRANCHES];

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

            for n = 1:NUM_BRANCHES  
                if(lineout ~= -1)%case where no line is selected
                    tempmpc.branch(lineout, 11) = 0;
                end
                tempmpc.branch(n,11) = 0;

                tempislmpc = extract_islands(tempmpc, 1);
                tempislmpc.gen(:,2) = tempislmpc.gen(:,2) * temp_load_data(n); %generation scaling
                tempislmpc.bus(:,3) = tempislmpc.bus(:,3) * temp_load_data(n); %Real Power scaling
                tempislmpc.bus(:,4) = tempislmpc.bus(:,4) * temp_load_data(n); %Reactive power scaling
                results = runpf_wcu(tempislmpc, mpopt);
                
                results_array(k,n) = limits_check(results, n);

            end %for loop
        end %parfor loop
        assignin('base', 'n1', n1);
        assignin('base', 'line', line);
        assignin('base', 'results_array', results_array);
    end 

    %Load data Loader
    function [load_data_return] = import_load_data(LOAD_SHEET)
        load_data_table = readtable(LOAD_SHEET);
        load_data_return = table2array(load_data_table(:,5));
    end

    %limits calculation
    function [limit_check_return] = limits_check(mpc_case, n)
        if(mpc_case.branch(n,14) > mpc_case.branch(n, 16))
            real_power = mpc_case.branch(n, 14);
        else
            real_power = mpc_case.branch(n, 16);
        end
        if(mpc_case.branch(n,15) > mpc_case.branch(n, 17))
            reactive_power = mpc_case.branch(n, 15);
        else
            reactive_power = mpc_case.branch(n, 17);
        end

        apparent_power = sqrt(real_power^2 + reactive_power^2);

        if(apparent_power > mpc_case.branch(n, 6))
            limit_check_return = 0;
        else
            limit_check_return = 1;
        end
    end
toc;
end