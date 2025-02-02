function [results_array, failure_array] = n1_contingency(settings, scheduled_outage, generation_outages, load_data, mpc, gen_array, block_dispatch, mpopt, start_hour, end_hour)
    % n1_contingency - A function to simulate n-1 contingency for power systems.
    %   Returns
    %       results_array => Returns the results of the limits_check function, detailing the health of the system in terms of MVA and Voltage Magnitude limits
    %       failure_array => Returns hours, branch outage and powerflow results from any cases that failed the limit checks
    %   Inputs
    %       settings is the settings class object used to pass settings parameters.
    %       LINEOUT NEEDS TO BE CHANGED TO TRANSMISSION OUTAGE OBJECT FOR THE CASES THAT MULTIPLE LINES ARE OUT.
    %       generation_outages is the generation outages that are pre-scheduled for the system.
    %       load_data is a class object containing the actual and scaling factors for the load on a per hour basis.
    %       mpc is the system without any outages that the outages cases is built off of.
    %       gen_array is the collection of generation blocks 1-5 for the case that block_dispatch is on.
    %       block_dispatch is a boolean input for block_dispatch being enabled. Set in settings.txt
    %       mpopt is the options for the powerflow including algorithm type.
    %       start_hour is the start hour of the simulation. Settings.start_hour is used for the initial case and is set in settings.txt
    %       end_hour is the end hour of the simulation. Settings.end_hour is used for the initial case and is set in settings.txt
    block_disp = settings.block_dispatch;
    for k = start_hour:end_hour
        if(mod(k,10) == 0)
            disp("N-1 Contingency Hour: " + k);
        end
        %temporary variables for parallel functionality 
        tempmpc = mpc;
        temp_generation_outages = generation_outages;
        temp_load_data = load_data;

        for gens = 1:height(temp_generation_outages(:,1))
            gen_temp = temp_generation_outages(gens,1);
            gen_temp_start = temp_generation_outages(gens,2);
            gen_temp_end = temp_generation_outages(gens,3);
            
            if(k >= gen_temp_start && k <= gen_temp_start + gen_temp_end)
                for i = 1: height(tempmpc.gen)
                    if tempmpc.gen(i,1) == gen_temp
                        tempmpc.gen(i,8) = 0;
                    end
                end
            end
        end%for loop

        if(scheduled_outage.occuring == true) %where an outage is occuring
            for i = 1:height(scheduled_outage.branches)
                tempmpc.branch(scheduled_outage.branches(i), 11) = 0;
            end
        end
        temp_outage_branches = scheduled_outage.branches;

        parfor n = 1:height(tempmpc.branch)
            temp_gen_array = gen_array;
            partempmpc = tempmpc;
            par_temp_load_data = temp_load_data;
            partempmpc.branch(n,11) = 0;

            temp_isl_mpc = extract_islands(partempmpc, 1);
            
            %load scaling
            temp_isl_mpc.bus(:,3) = temp_isl_mpc.bus(:,3) * par_temp_load_data.weighted_load(k); %Real Power scaling
            temp_isl_mpc.bus(:,4) = temp_isl_mpc.bus(:,4) * par_temp_load_data.weighted_load(k); %Reactive power scaling

            %block dispatch
            if(block_disp == true)
                temp_isl_mpc = gen_scale_block(temp_isl_mpc, block_dispatch, k, temp_gen_array(1), temp_gen_array(2), temp_gen_array(3), temp_gen_array(4), temp_gen_array(5));
            else
                temp_isl_mpc = gen_scale_linear(temp_isl_mpc);
            end

            results = runpf_wcu(temp_isl_mpc, mpopt);
            [limit_results, failure_params] = limits_check(results);
            results_array{k,n} = limit_results;

            if(~failure_params.status)
                failure = struct;
                failure.hour = k;
                failure.branch_out = n;
                failure.branch = results.branch;
                failure.bus = results.bus;
                failure.gen = results.gen;
                failure.vmag = failure_params.vmag;
                failure.mva = failure_params.MVA;
                failure.load = par_temp_load_data.actual_load(k);
                failure_array{k,n} = failure;
            else
                failure_array{k,n} = 0;
            end

            if(~ismember(n,temp_outage_branches))
                partempmpc.branch(n,11) = 1;
            end

        end %for loop
    end %parfor loop
end