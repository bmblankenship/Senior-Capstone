function scaled_generation = gen_scale(gen_mpc, gen_scaling, gen_hour, block_1, block_2, block_3, block_4, block_5)
    scaled_generation = gen_mpc;
    selector = 0;

    for blk = 1:height(scaled_generation.gen)
        if(selector == 0)
            for a = 1:height(block_1.busses)
                if(scaled_generation.gen(blk,1) == block_1.busses(a) && gen_scaling(gen_hour, 1) > 0)
                    scaled_generation.gen(blk,2) = scaled_generation.gen(blk,2) * gen_scaling(gen_hour, 1);
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 1);
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
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 2);
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
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 3);
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
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 4);
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
                    scaled_generation.gen(blk,3) = scaled_generation.gen(blk,3) * gen_scaling(gen_hour, 5);
                    selector = 1;
                elseif(scaled_generation.gen(blk,1) == block_5.busses(a) && gen_scaling(gen_hour, 5) <= 0)
                    scaled_generation.gen(blk,8) = 0;
                    selector = 1;
                end
            end
        end
        selector = 0;
    end
end