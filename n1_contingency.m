function [results_array, failure_array] = n1_contingency(settings, scheduled_outage, generation_outages, load_data, mpc, gen_array, mpopt, start_hour, end_hour)
    % n1_contingency - A function to simulate n-1 contingency for power systems.
    %   Returns
    %       results_array => Returns the results of the limits_check function, detailing the health of the system in terms of MVA and Voltage Magnitude limits
    %       failure_array => Returns hours, branch outage and powerflow results from any cases that failed the limit checks
    %   Inputs
    %       settings is the settings class object used to pass settings parameters.
    %       scheduled_outage is an outage class object used to pass outage information.
    %       generation_outages is the generation outages that are pre-scheduled for the system.
    %       load_data is a class object containing the actual and scaling factors for the load on a per hour basis.
    %       mpc is the system without any outages that the outages cases is built off of.
    %       gen_array is the collection of generation blocks 1-5 for the case that block_dispatch is on.
    %       mpopt is the options for the powerflow including algorithm type.
    %       start_hour is the start hour of the simulation. Settings.start_hour is used for the initial case and is set in settings.txt
    %       end_hour is the end hour of the simulation. Settings.end_hour is used for the initial case and is set in settings.txt
    block_disp = settings.block_dispatch;
    gen_outage = settings.generation_outage;
    for k = start_hour:end_hour
        if(mod(k,10) == 0)
            disp("N-1 Contingency Hour: " + k);
        end
        % temporary mpc to prevent overwriting base case
        tempmpc = mpc;

        % Turn generation off in the case of an outage
        if(gen_outage == 1)
            generation_out = 0;
            for i = 1:height(generation_outages)
                if(k >= generation_outages(i).start_hour && k < generation_outages(i).end_hour)
                    for gens = 1:height(tempmpc.gen)
                        if tempmpc.gen(gens,1) == generation_outages(i).bus
                            generation_out = generation_out + generation_outages(i).real_power;
                            tempmpc.gen(gens,8) = 0;
                        end
                    end
                end
            end

            % Dispatch peakers to cover outages in generation
            if(generation_out > 0)
                for i = 1:height(tempmpc.gen)
                    if(tempmpc.gen(i,2) == 0 && generation_out > 0)
                        tempmpc.gen(i,2) = tempmpc.gen(i,9);
                        generation_out = generation_out - tempmpc.gen(i,9);
                    end
                end
               
            end
        end

        % turn off branches from scheduled outage
        if(scheduled_outage.start_hour ~= -1)
            for i = 1:height(scheduled_outage.branches)
                tempmpc.branch(scheduled_outage.branches(i), 11) = 0;
            end
        end
        temp_outage_branches = scheduled_outage.branches;
        
        parfor n = 1:height(tempmpc.branch)
            % temporary parallel variables
            temp_gen_array = gen_array;
            partempmpc = tempmpc;
            par_temp_load_data = load_data;

            % turn off branch for n-1 contingency
            partempmpc.branch(n,11) = 0;

            % Load scaling
            partempmpc.bus(:,3) = partempmpc.bus(:,3) * par_temp_load_data.weighted_load(k); %Real Power scaling
            partempmpc.bus(:,4) = partempmpc.bus(:,4) * par_temp_load_data.weighted_load(k); %Reactive power scaling

            % Generation Scaling
            if(block_disp == 1)
                % Block Dispatch
                partempmpc = gen_scale_block(partempmpc, temp_gen_array);
            else
                % Linear Scaling
                partempmpc.gen(:,2) = partempmpc.gen(:,2) * par_temp_load_data.weighted_load(k);
            end

            % remove islands except the largest from the system
            temp_isl_mpc = extract_islands(partempmpc, 1);            

            % run powerflow on modified system
            results = runpf_wcu(temp_isl_mpc, mpopt);
            [limit_results, failure_params] = limits_check(results);
            temp_results_array{k,n} = limit_results;

            % Store data on the failure of the contingency in the case that voltage magnitude or MVA limits are violated
            if(~limit_results)
                failure = struct;
                failure.hour = k;
                failure.branch_out = n;
                failure.vmag = failure_params.vmag;
                failure.mva = failure_params.MVA;
                failure.vmag_val = failure_params.vmag_val;
                failure.MVA_val = failure_params.MVA_val;
                failure.load = par_temp_load_data.actual_load(k);
                
                failure_array{k,n} = failure;
            else
                failure_array{k,n} = 0;
            end

            % turn branch back on if not a member of the outage currently being ran
            if(~ismember(n,temp_outage_branches))
                partempmpc.branch(n,11) = 1;
            end

        end %parfor loop

        % parse through all branches for the hour and mark hour as a failure if at least one branch failed.
        failure_checker = true;
        for n = 1:width(temp_results_array)
            if(temp_results_array{k,n} == false)
                failure_checker = false;
            end
        end
        results_array{k,1} = failure_checker;

    end %for loop
end