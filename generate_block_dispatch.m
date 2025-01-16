%% Block Dispatch Generator
function [dispatch] = generate_block_dispatch(settings, gen_block_1, gen_block_2, gen_block_3, gen_block_4, gen_block_5, load_data, generation_outages)
    % generate_block_dispatch Generate 8760x5 array of block weightings
    % block 1 is highest priority
    % block 5 is lowest priority
    % Generates the dispatch for the entire year, meaning the array will need to be regenerated in the case that load changes
    % Regenerate by recalling the function with the new load added in
    
    % Import block references from proper excel sheet
    generation_blocks = table2array(readtable(settings.case_sheet, "sheet", "Gen"));

    % Return variable
    % Format is block 1 - 2 - 3 - 4 - 5 and will be percent utilization of that block
    dispatch = [zeros, settings.simulation_hours; zeros, settings.simulation_hours; zeros, settings.simulation_hours; zeros, settings.simulation_hours; zeros, settings.simulation_hours];

    % Block debugging variables
    assignin('base', 'gen_block_1', gen_block_1);
    assignin('base', 'gen_block_2', gen_block_2);
    assignin('base', 'gen_block_3', gen_block_3);
    assignin('base', 'gen_block_4', gen_block_4);
    assignin('base', 'gen_block_5', gen_block_5);
    assignin('base', 'generation_blocks', generation_blocks);
    
    % Iterate through all hours and assign dispatch values to each hour from 1 to 8760
    for k = 1:settings.simulation_hours
        for j = 1:height(generation_outages)
            % Check if generation needs to be turned off for an outage
            if (generation_outages(j,2) == k)
                block = generation_outages(j,4);
                gen = generation_outages(j,1);

                switch block
                case 1
                    for b = 1:height(gen_block_1.busses)
                        if(gen_block_1.busess(b) == gen)
                            lower_cap(gen_block_1, gen_block_1.capacity(b));
                        end
                    end
                case 2
                    for b = 1:height(gen_block_2.busses)
                        if(gen_block_2.busses(b) == gen)
                            lower_cap(gen_block_2, gen_block_2.capacity(b));
                        end
                    end
                case 3
                    for b = 1:height(gen_block_3.busses)
                        if(gen_block_3.busses(b) == gen)
                            lower_cap(gen_block_3, gen_block_3.capacity(b));
                        end
                    end
                case 4
                    for b = 1:height(gen_block_4.busses)
                        if(gen_block_4.busses(b) == gen)
                            lower_cap(gen_block_4, gen_block_4.capacity(b));
                        end
                    end
                case 5
                    for b = 1:height(gen_block_5.busses)
                        if(gen_block_5.busses(b) == gen)
                            lower_cap(gen_block_5, gen_block_5.capacity(b));
                        end
                    end
                end% End Switch
            end % End if

            %%REFACTOR COMPLETE UP TO THIS POINT
            %probably lmao

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