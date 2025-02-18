function scaled_generation = gen_scale_block(gen_mpc, gen_array)
% gen_scale_block: scales generation for block dispatch
%   scaled_generation = gen_scale_block(mpc, block_array)
%       returns scaled mpc based on hour and precalculated scaling_info from generate_block_dispatch
    scaled_generation = gen_mpc;
    selector = 0;

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
        for blk = 1:height(gen_array(block).capacity)
            switch block
                case 1
                    b1_actual = b1_actual + gen_array(block).capacity;
                case 2
                    b2_actual = b2_actual + gen_array(block).capacity;
                case 3
                    b3_actual = b3_actual + gen_array(block).capacity;
                case 4
                    b4_actual = b4_actual + gen_array(block).capacity;
                case 5
                    b5_actual = b5_actual + gen_array(block).capacity;
            end
        end
    end

    if()
    end

    for blk = 1:height(scaled_generation.gen)
        if(selector == 0)
            for a = 1:height(block_1.busses)
                if(scaled_generation.gen(blk,1) == block_1.busses(a) && gen_scaling(gen_hour, 1) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 1);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_1.busses(a) && gen_scaling(gen_hour, 1) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        if(selector == 0)
            for a = 1:height(block_2.busses)
                if(scaled_generation.gen(blk,1) == block_2.busses(a) && gen_scaling(gen_hour, 2) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 2);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_2.busses(a) && gen_scaling(gen_hour, 2) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        if(selector == 0)
            for a = 1:height(block_3.busses)
                if(scaled_generation.gen(blk,1) == block_3.busses(a) && gen_scaling(gen_hour, 3) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 3);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_3.busses(a) && gen_scaling(gen_hour, 3) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        if(selector == 0)
            for a = 1:height(block_4.busses)
                if(scaled_generation.gen(blk,1) == block_4.busses(a) && gen_scaling(gen_hour, 4) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 4);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_4.busses(a) && gen_scaling(gen_hour, 4) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        if(selector == 0)
            for a = 1:height(block_5.busses)
                if(scaled_generation.gen(blk,1) == block_5.busses(a) && gen_scaling(gen_hour, 5) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 5);
                elseif(scaled_generation.gen(blk,1) == block_5.busses(a) && gen_scaling(gen_hour, 5) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                end
            end
        end
        selector = 0;
    end
end