function [scaled_generation, total_generation, gen_scale_factor] = gen_scale_linear(mpc, load_data, hour)
    % gen_scale_linear: scales generation for linear scaling when block dispatch is disabled
    %   scaled_generation = gen_scale_block(mpc)
    %       returns scaled mpc based on the mpc that is passed in.
    %       this must occur after the case has been split due to islands, and load has been scaled.
    scaled_generation = mpc;
    total_load = 0;
    total_generation = 0;

    for i = 1:height(scaled_generation.bus)
        total_load = total_load + scaled_generation.bus(i,3);
    end

    for i = 1:height(scaled_generation.gen)
        if(scaled_generation.gen(i,8) == 1)
            total_generation = total_generation + scaled_generation.gen(i,9);
        end
    end

    extra_generation = total_generation - total_load;
    gen_scale_factor = double((total_generation - extra_generation) / total_generation);

    for i = 1:height(scaled_generation.gen)
        if(scaled_generation.gen(i,8) == 1)
            scaled_generation.gen(i,2) = scaled_generation.gen(i,9) * gen_scale_factor;
            %scaled_generation.gen(i,2) = scaled_generation.gen(i,9) * load_data.weighted_load(hour);
        end
    end
end