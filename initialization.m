function initialization()
    tic;
    sim_settings = local_settings();

    if(sim_settings.simulation_hours > 8760)
        warning('Simulation Hours Specified are out of range (>8760). Setting to 8760.');
        sim_settings.simulation_hours = 8760;
    end
    
    % Options Initilization
    mpopt = mpoption('pf.alg', sim_settings.algorithm, 'verbose', sim_settings.verbose);
    mpc = runpf_wcu(sim_settings.case_name, mpopt);
    
    % Load Data Initilization 
    load_data_obj = load_data(sim_settings);
    
    % Generation Initilization
    generation_outages = generator_outage(sim_settings);
    if(sim_settings.block_dispatch == true)
        gen_block_1 = generation_block(sim_settings, 1);
        gen_block_2 = generation_block(sim_settings, 2);
        gen_block_3 = generation_block(sim_settings, 3);
        gen_block_4 = generation_block(sim_settings, 4);
        gen_block_5 = generation_block(sim_settings, 5);
        gen_array = [gen_block_1; gen_block_2; gen_block_3; gen_block_4; gen_block_5];
        [block_dispatch, generation_blocks] = generate_block_dispatch(sim_settings, gen_block_1, gen_block_2, gen_block_3, gen_block_4, gen_block_5, load_data_obj, generation_outages);
        
        % Block debugging variables
        assignin('base', 'block_dispatch', block_dispatch);
        assignin('base', 'gen_block_1', gen_block_1);
        assignin('base', 'gen_block_2', gen_block_2);
        assignin('base', 'gen_block_3', gen_block_3);
        assignin('base', 'gen_block_4', gen_block_4);
        assignin('base', 'gen_block_5', gen_block_5);
        assignin('base', 'generation_blocks', generation_blocks);
    else
        gen_array = [];
        block_dispatch = 0.0;
    end
    
    % MATLAB debugging Variables
    assignin('base', 'mpc', mpc);
    assignin('base', 'generation_outages', generation_outages);
    assignin('base', 'load_data', load_data_obj);
    
    % initial N-1 contingency to verify health of the system with planned generator outages
    disp("Starting N-1 Contingency Analysis");
    initial_n1_outage =  scheduled_outage(false, 0, 0, []);
    [ini_results, ini_failure] = n1_contingency(sim_settings, initial_n1_outage, generation_outages, load_data_obj, mpc, gen_array, block_dispatch, mpopt, sim_settings.start_hour, sim_settings.simulation_hours);
    assignin('base', 'initial_results_array', ini_results);
    assignin('base', 'initial_failure_array', ini_failure);

    % run schedule algorithm

    % Test schedule
    schedule(1) = scheduled_outage(true, 1, 121, 17);
    schedule(2) = scheduled_outage(true, 500, 547, 102);
    schedule(3) = scheduled_outage(true, 900, 923, 131);
    % number of scheduling iterations to run
    counter = 1;
    base_case = {height(schedule), counter};

    while(counter > 0)
        for i = 1:width(schedule)
            [base_res, base_fail] = n1_contingency(sim_settings, schedule(i), generation_outages, load_data_obj, mpc, gen_array, block_dispatch, mpopt, schedule(i).start_hour, schedule(i).end_hour);
            
            for j = 1:height(base_res)
                if(~base_res{j,1})
                    schedule(i).set_state(false);
                end
            end

            base_case{i,counter} = schedule(i);
        end
        counter = counter - 1;
    end
    
    assignin('base', 'base_case', base_case);
    toc;
end