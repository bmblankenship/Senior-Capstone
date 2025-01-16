%%n-1 contingency
function [results_array, mpc_array] = n1_contingency(settings, lineout, generation_outages, load_data, mpc, gen_array, block_dispatch, mpopt) 

    for k = settings.start_hour:settings.simulation_hours
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
            if(settings.block_dispatch == true)
                temp_isl_mpc = gen_scale(temp_isl_mpc, block_dispatch, k, gen_array(1), gen_array(2), gen_array(3), gen_array(4), gen_array(5));
            else
                temp_isl_mpc.gen(:,2) = temp_isl_mpc.gen(:,2) * temp_load_data(k,2);
                temp_isl_mpc.gen(:,3) = temp_isl_mpc.gen(:,3) * temp_load_data(k,2);
            end
            
            %load scaling
            temp_isl_mpc.bus(:,3) = temp_isl_mpc.bus(:,3) * temp_load_data(k,2); %Real Power scaling
            temp_isl_mpc.bus(:,4) = temp_isl_mpc.bus(:,4) * temp_load_data(k,2); %Reactive power scaling

            results = runpf_wcu(temp_isl_mpc, mpopt);
            results_array{k,n} = limits_check(results);
            mpc_array(k,n) = results;
            
            tempmpc.branch(n,11) = 1;

        end %for loop
    end %parfor loop
    assignin('base', 'results_array', results_array);
end