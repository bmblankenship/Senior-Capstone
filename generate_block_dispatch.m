function [dispatch, generation_blocks] = generate_block_dispatch(settings, gen_block_1, gen_block_2, gen_block_3, gen_block_4, gen_block_5, load_data, generation_outages)
    % generate_block_dispatch Generate 8760x5 array of block weightings
    % block 1 is highest priority
    % block 5 is lowest priority
    % Generates the dispatch for the entire year, meaning the array will need to be regenerated in the case that load changes
    % Regenerate by recalling the function with the new load added in
    
    % Import block references from proper excel sheet
    w=warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    generation_blocks = table2array(readtable(settings.case_sheet, "sheet", "Gen"));
    warning(w);

    % Return variable
    % Format is block 1 - 2 - 3 - 4 - 5 and will be percent utilization of that block
    dispatch = [];
    
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

            % Check if generation needs to be turned on after an outage
            if (generation_outages(j,2) + generation_outages(j,3) == k)
                block = generation_outages(j,4);
                gen = generation_outages(j,1);

                switch block
                case 1
                    for b = 1:height(gen_block_1.busses)
                        if(gen_block_1.busses(b) == gen)
                            inc_cap(gen_block_1, gen_block_1.capacity(b));
                        end
                    end
                case 2
                    for b = 1:height(gen_block_2.busses)
                        if(gen_block_2.busses(b) == gen)
                            inc_cap(gen_block_2, gen_block_2.capacity(b));
                        end
                    end
                case 3
                    for b = 1:height(gen_block_3.busses)
                        if(gen_block_3.busses(b) == gen)
                            inc_cap(gen_block_3, gen_block_3.capacity(b));
                        end
                    end
                case 4
                    for b = 1:height(gen_block_4.busses)
                        if(gen_block_4.busses(b) == gen)
                            inc_cap(gen_block_4, gen_block_4.capacity(b));
                        end
                    end
                case 5
                    for b = 1:height(gen_block_5.busses)
                        if(gen_block_5.busses(b) == gen)
                            inc_cap(gen_block_5, gen_block_5.capacity(b));
                        end
                    end
                end% End Switch
            end% End if
        end% End For

        % Compare load for this hour to the size of the availiable generation.
        % Assign a percentage of the block generation to each hour.

        current_load = load_data.actual_load(k);
        extra_gen = 0;
        dispatch(k,1) = double(0);
        dispatch(k,2) = double(0);
        dispatch(k,3) = double(0);
        dispatch(k,4) = double(0);
        dispatch(k,5) = double(0);

        % Dispatch Block 1
        if(current_load <= 0)
            dispatch(k,1) = 0;
        elseif(current_load - gen_block_1.total_capacity < 0)
            extra_gen = gen_block_1.total_capacity - current_load;
            dispatch(k,1) = double((gen_block_1.total_capacity - extra_gen) / gen_block_1.total_capacity);
            current_load = 0;
        elseif(current_load - gen_block_1.total_capacity > 0)
            current_load = current_load - gen_block_1.total_capacity;
            dispatch(k,1) = 1;
        end

        % Dispatch Block 2
        if(current_load <= 0)
            dispatch(k,2) = 0;
        elseif(current_load - gen_block_2.total_capacity < 0)
            extra_gen = gen_block_2.total_capacity - current_load;
            dispatch(k,2) = double((gen_block_2.total_capacity - extra_gen) / gen_block_2.total_capacity);
            current_load = 0;
        elseif(current_load - gen_block_2.total_capacity > 0)
            current_load = current_load - gen_block_2.total_capacity;
            dispatch(k,2) = 1;
        end

        % Dispatch Block 3
        if(current_load <= 0)
            dispatch(k,3) = 0;
        elseif(current_load - gen_block_3.total_capacity < 0)
            extra_gen = gen_block_3.total_capacity - current_load;
            dispatch(k,3) = double((gen_block_3.total_capacity - extra_gen) / gen_block_3.total_capacity);
            current_load = 0;
        elseif(current_load - gen_block_3.total_capacity > 0)
            current_load = current_load - gen_block_3.total_capacity;
            dispatch(k,3) = 1;
        end

        % Dispatch Block 4
        if(current_load <= 0)
            dispatch(k,4) = 0;
        elseif(current_load - gen_block_4.total_capacity < 0)
            extra_gen = gen_block_4.total_capacity - current_load;
            dispatch(k,4) = double((gen_block_4.total_capacity - extra_gen) / gen_block_4.total_capacity);
            current_load = 0;
        elseif(current_load - gen_block_4.total_capacity > 0)
            current_load = current_load - gen_block_4.total_capacity;
            dispatch(k,4) = 1;
        end

        % Dispatch Block 5
        if(current_load <= 0)
            dispatch(k,5) = 0;
        elseif(current_load - gen_block_5.total_capacity < 0)
            extra_gen = gen_block_5.total_capacity - current_load;
            dispatch(k,5) = double((gen_block_5.total_capacity - extra_gen) / gen_block_5.total_capacity);
            current_load = 0;
        elseif(current_load - gen_block_5.total_capacity > 0)
            current_load = current_load - gen_block_5.total_capacity;
            dispatch(k,5) = 1;
        end

        % Handle load being too high
        if(current_load > 0)
            warning('Load exceeds available generation for hour: %d', k);
        end
    end
end