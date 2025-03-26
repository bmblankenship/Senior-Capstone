function initialization()
    % --- Set up TCP connection to Python logging server ---
    serverHost = '127.0.0.1';
    serverPort = 12345;
    try
        % Create a TCP client (requires MATLAB R2019b or later)
        client = tcpclient(serverHost, serverPort);
        disp('Connected to Python logging server.');
    catch ME
        disp('Could not connect to Python logging server. Logging locally only.');
        client = [];
    end

    % Define a local logging function that both displays messages and sends them over TCP.
    function logMessage(msg)
        % Display message in MATLAB command window.
        disp(msg);
        % Send message over TCP if connection is available.
        if ~isempty(client)
            % Use sprintf to format msg with a newline and convert to uint8.
            data = uint8(sprintf('%s\n', msg));
            try
                write(client, data);
            catch err
                disp(['Error sending log message: ' err.message]);
            end
        end
        drawnow;  % Force immediate output update.
    end
    % --- End TCP logging setup ---

%------------------------------------------------------------------------------------------------------------------


    tic;
    sim_settings = local_settings();

    if(sim_settings.end_hour > 8760)
        warning('Simulation Hours Specified are out of range (>8760). Setting to 8760.');
        sim_settings.end_hour = 8760;
        logMessage('Warning: Simulation Hours Specified are out of range (>8760). Setting to 8760.');
    end

    % Options Initilization
    mpopt = mpoption('pf.alg', sim_settings.algorithm, 'verbose', sim_settings.verbose);
    mpc = loadcase(sim_settings.case_name);
    logMessage('Case Loaded.');
    
    % Load Data Initilization 
    loaddata = load_data(sim_settings);
    logMessage('Data loading complete.');
    logMessage('Power flow run completed.');
    
    % Generation Outage Initilization
    w = warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    generator_outage_data = table2cell(readtable(sim_settings.outage_sheet, "sheet", "Generation"));
    warning(w);
    
    for i = 1:height(generator_outage_data)
        % Assumes MM/DD/YYYY format
        start_time = day(generator_outage_data{i,4}, 'dayofyear') * 24;
        % Assumes duration is listed in weeks
        end_time = generator_outage_data{i,5} * 168;
        generation_outages(i,1) = generation_outage(start_time, end_time, generator_outage_data{i,1}, generator_outage_data{i,2}); 
    end

    gen_array = [];
    % Block Dispatch Initilization
    if(sim_settings.block_dispatch == 1)
        gen_block_1 = generation_block(sim_settings, 1);
        gen_block_2 = generation_block(sim_settings, 2);
        gen_block_3 = generation_block(sim_settings, 3);
        gen_block_4 = generation_block(sim_settings, 4);
        gen_block_5 = generation_block(sim_settings, 5);
        gen_array = [gen_block_1; gen_block_2; gen_block_3; gen_block_4; gen_block_5];
        logMessage('Generation blocks computed.');
    end
    
    % initial N-1 contingency to verify health of the system with planned generator outages
    disp("Starting N-1 Contingency Analysis");
    initial_n1_outage =  scheduled_outage(-1, 0, []);
    [ini_results, ini_failure] = n1_contingency(sim_settings, initial_n1_outage, generation_outages, loaddata, mpc, gen_array, mpopt, sim_settings.start_hour, sim_settings.end_hour);
    assignin('base', 'initial_results_array', ini_results);
    assignin('base', 'initial_failure_array', ini_failure);
    logMessage(['Initial N-1 Contingency Analysis complete. Start Hour: ' num2str(sim_settings.start_hour) ', End Hour: ' num2str(sim_settings.end_hour)]);
    
    % run schedule algorithm

    % Test schedule
    logMessage('Starting schedule algorithm...');
    schedule(1) = scheduled_outage(1, 10, 17);
    %schedule(2) = scheduled_outage(500, 547, 102);
    %schedule(3) = scheduled_outage(900, 923, 131);
    % number of scheduling iterations to run
    counter = 1;
    base_case = {height(schedule), counter};

    while(counter > 0)
        for i = 1:width(schedule)
            [base_res, base_fail] = n1_contingency(sim_settings, schedule(i), generation_outages, loaddata, mpc, gen_array, mpopt, schedule(i).start_hour, schedule(i).end_hour);
            
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
    
    plot(sim_settings.start_hour:sim_settings.end_hour, cell2mat(ini_results));
    ylim([-0.2 1.2]);
    title('Gen Outage | No Q lim enforce | Peaker Disp on Outage');

    logMessage(sprintf('Iteration %d, schedule index: %d', counter, i));
    % Close the TCP client if it exists.
    if ~isempty(client)
        clear client;
    end


end