function [results_array, mpc_array] = n1_contingency(settings, lineout, generation_outages, load_data, mpc, gen_array, block_dispatch, mpopt) 
    for k = settings.start_hour:settings.simulation_hours
        if(mod(k,10) == 0)
            disp("N-1 Contingency Hour: " + k);
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

        parfor n = 1:height(tempmpc.branch)
            partempmpc = tempmpc;
            par_temp_load_data = temp_load_data;
            if(lineout ~= -1)%case where no line is selected
                partempmpc.branch(lineout, 11) = 0;
            end
            partempmpc.branch(n,11) = 0;

            temp_isl_mpc = extract_islands(partempmpc, 1);

            %block dispatch
            if(settings.block_dispatch == true)
                temp_isl_mpc = gen_scale(temp_isl_mpc, block_dispatch, k, gen_array(1), gen_array(2), gen_array(3), gen_array(4), gen_array(5));
            else
                temp_isl_mpc.gen(:,2) = temp_isl_mpc.gen(:,2) * par_temp_load_data.weighted_load(k);
                temp_isl_mpc.gen(:,3) = temp_isl_mpc.gen(:,3) * par_temp_load_data.weighted_load(k);
            end
            
            %load scaling
            temp_isl_mpc.bus(:,3) = temp_isl_mpc.bus(:,3) * par_temp_load_data.weighted_load(k); %Real Power scaling
            temp_isl_mpc.bus(:,4) = temp_isl_mpc.bus(:,4) * par_temp_load_data.weighted_load(k); %Reactive power scaling

            results = runpf_wcu(temp_isl_mpc, mpopt);
            results_array{k,n} = limits_check(results);
            mpc_array(k,n) = results;
            
            partempmpc.branch(n,11) = 1;

        end %for loop
    end %parfor loop
end