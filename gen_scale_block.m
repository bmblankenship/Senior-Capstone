function scaled_generation = gen_scale_block(gen_mpc, gen_array)
% gen_scale_block: scales generation for block dispatch
%   scaled_generation = gen_scale_block(mpc, block_array)
%       returns scaled mpc based on hour and precalculated scaling_info from generate_block_dispatch
    scaled_generation = gen_mpc;

    b1_actual = 0;
    b2_actual = 0;
    b3_actual = 0;
    b4_actual = 0;
    b5_actual = 0;

    b1_disp = 0;
    b2_disp = 0;
    b3_disp = 0;
    b4_disp = 0;
    b5_disp = 0;

    total_load = 0;

    for i = 1:height(scaled_generation.bus)
        total_load = total_load + scaled_generation.bus(i,3);
    end

    for block = 1:5
        for blk = 1:height(gen_array(block, 1).capacity)
            for check_exists = 1:height(scaled_generation.gen)
                if(scaled_generation.gen(check_exists, 1) == gen_array(block, 1).busses(blk, 1) && scaled_generation.gen(check_exists, 8) == 1)
                    switch block
                        case 1
                            b1_actual = b1_actual + gen_array(block, 1).capacity(blk);
                        case 2
                            b2_actual = b2_actual + gen_array(block, 1).capacity(blk);
                        case 3
                            b3_actual = b3_actual + gen_array(block, 1).capacity(blk);
                        case 4
                            b4_actual = b4_actual + gen_array(block, 1).capacity(blk);
                        case 5
                            b5_actual = b5_actual + gen_array(block, 1).capacity(blk);
                    end
                end
            end
        end
    end

    % check each block versus load and apply 0-1 value to b#_disp variable
    if total_load > 0 && total_load > b1_actual
        b1_disp = 1;
        total_load = total_load - b1_actual;
    else
        b1_disp = double((b1_actual - total_load) / b1_actual);
        total_load = 0;
    end

    if total_load > 0 && total_load > b2_actual
        b2_disp = 1;
        total_load = total_load - b2_actual;
    else
        b2_disp = double((b2_actual - total_load) / b2_actual);
        total_load = 0;
    end

    if total_load > 0 && total_load > b3_actual
        b3_disp = 1;
        total_load = total_load - b3_actual;
    else
        b3_disp = double((b3_actual - total_load) / b3_actual);
        total_load = 0;
    end

    if total_load > 0 && total_load > b4_actual
        b4_disp = 1;
        total_load = total_load - b4_actual;
    else
        b4_disp = double((b4_actual - total_load) / b4_actual);
        total_load = 0;
    end

    if total_load > 0 && total_load > b5_actual
        b5_disp = 1;
        total_load = total_load - b5_actual;
    else
        b5_disp = double((b5_actual - total_load) / b5_actual);
        total_load = 0;
    end

    % iterate through each block and apply disp variable to all generation
    for block = 1:5
        for blk = 1:height(gen_array(block, 1).busses)
            for check_exists = 1:height(scaled_generation.gen)
                if(scaled_generation.gen(check_exists, 1) == gen_array(block, 1).busses(blk, 1))
                    switch block
                        case 1
                            scaled_generation.gen(check_exists, 2) = scaled_generation.gen(check_exists, 9) * b1_disp;
                        case 2
                            scaled_generation.gen(check_exists, 2) = scaled_generation.gen(check_exists, 9) * b2_disp;
                        case 3
                            scaled_generation.gen(check_exists, 2) = scaled_generation.gen(check_exists, 9) * b3_disp;
                        case 4
                            scaled_generation.gen(check_exists, 2) = scaled_generation.gen(check_exists, 9) * b4_disp;
                        case 5
                            scaled_generation.gen(check_exists, 2) = scaled_generation.gen(check_exists, 9) * b5_disp;
                    end
                end
            end
        end
    end
end