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


    tic; % used to display runtime, can be disabled if not desired.

    % Get simulation settings from the settings.txt file
    sim_settings = local_settings();

    % Check that the end hour does not go past the end of the year.
    if(sim_settings.end_hour > 8760)
        warning('Simulation Hours Specified are out of range (>8760). Setting to 8760.');
        sim_settings.end_hour = 8760;
        logMessage('Warning: Simulation Hours Specified are out of range (>8760). Setting to 8760.');
    end

    % Options Initilization
    mpopt = mpoption('pf.alg', sim_settings.algorithm, 'verbose', sim_settings.verbose);

    % Load case data from existing file. case118_CAPER_PeakLoad.m was the file used for testing.
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

    % Block Dispatch Initilization
    % This was off by default for most of the testing. Block dispatch does not work well with this case study.
    gen_array = [];
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

    % Run schedule algorithm
    logMessage('Starting schedule algorithm...');
    [branch_outages] = priority(sim_settings);
    assignin('base', 'branch_outages', branch_outages);
    [schedule] = schedule_algorithm(sim_settings, branch_outages, ini_results, generation_outages, loaddata, mpc, gen_array, mpopt);
    assignin('base', 'schedule', schedule);

    % Excel Output and Calendar Generation
    dates = datetime(2023,1,1) + hours(0:8759);
    for j = 1:numel(ini_results)
        output_schedule(j).Date = dates(j);  % Assign the date
        output_schedule(j).Hour = j;         % Assign the hour count
    end

    for i = 1:numel(schedule)
        if schedule(i).end_hour ~= 1 
            for j = schedule(i).start_hour:schedule(i).end_hour
                output_schedule(j).Branch = schedule(i).branches;
            end 
        end            
    end

    for j = 1:numel(output_schedule)
        if ~isequal(iniresults{j}, 1)
            output_schedule(j).Fails = 1;
        end
    end

    % Output
    filename = "ScheduleOrder.xlsx";
    writetable(struct2table(output_schedule), filename)
    outageCalendarGUI(ini_results)
    
    % number of scheduling iterations to run
    counter = 0;
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
    
    % This plots the initial N-1 contingency on a line graph to show what hours of the year pass or failed.
    plot(sim_settings.start_hour:sim_settings.end_hour, cell2mat(ini_results));
    ylim([-0.2 1.2]);
    title('Gen Outage | No Q lim enforce | Peaker Disp on Outage');

    logMessage(sprintf('Iteration %d, schedule index: %d', counter, i));
    % Close the TCP client if it exists.
    if ~isempty(client)
        clear client;
    end


end