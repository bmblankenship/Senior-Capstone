function initialization()
    tic; 
        sim_settings = local_settings();

    if(sim_settings.simulation_hours > 8760)
        warning('Simulation Hours Specified are out of range (>8760). Setting to 8760.');
        sim_settings.simulation_hours = 8760;
    end
        
    % mpc.gen(:,2)=mpc.gen(:,2); %generation scaling
    % mpc.bus(:,3)=mpc.bus(:,3); %Real Power scaling
    % mpc.bus(:,4)=mpc.bus(:,4); %Reactive power scaling
        
    % Options Initilization
    mpopt = mpoption('pf.alg', sim_settings.algorithm, 'verbose', sim_settings.verbose);
    mpc = runpf_wcu(sim_settings.case_name, mpopt);
    
    % Load Data Initilization
    load_data = import_load_data(sim_settings);
    
    % Generation Initilization
    generation_outages = generator_outage(sim_settings);
    if(sim_settings.block_dispatch == true)
        gen_block_1 = generation_block(sim_settings, 1);
        gen_block_2 = generation_block(sim_settings, 2);
        gen_block_3 = generation_block(sim_settings, 3);
        gen_block_4 = generation_block(sim_settings, 4);
        gen_block_5 = generation_block(sim_settings, 5);
        gen_array = [gen_block_1; gen_block_2; gen_block_3; gen_block_4; gen_block_5];
        block_dispatch = generate_block_dispatch(sim_settings, gen_block_1, gen_block_2, gen_block_3, gen_block_4, gen_block_5, load_data, generation_outages);
        assignin('base', 'block_dispatch', block_dispatch);
    else
        gen_array = 0;
        block_dispatch = 0;
    end
    
    % MATLAB debugging Variables
    assignin('base', 'mpc', mpc);
    assignin('base', 'generation_outages', generation_outages);
    assignin('base', 'load_data', load_data);
    
    %initial N-1 contingency to verify health of the system with planned generator outages
    [initial_results_array, initial_mpc_array] = n1_contingency(sim_settings, -1, generation_outages, load_data, mpc, gen_array, block_dispatch, mpopt);
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
