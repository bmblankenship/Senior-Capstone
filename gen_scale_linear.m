function scaled_generation = gen_scale_linear(mpc)
    % gen_scale_linear: scales generation for linear scaling when block dispatch is disabled
    %   scaled_generation = gen_scale_block(mpc)
    %       returns scaled mpc based on the mpc that is fed.
    %       this must occur as the case has been split due to islands, and load has been scaled.
    scaled_generation = mpc;
end

% gen scaling
%temp_isl_mpc.gen(:,2) = temp_isl_mpc.gen(:,2) * par_temp_load_data.weighted_load(k);

% load scaling
%temp_isl_mpc.bus(:,3) = temp_isl_mpc.bus(:,3) * par_temp_load_data.weighted_load(k); %Real Power scaling
%temp_isl_mpc.bus(:,4) = temp_isl_mpc.bus(:,4) * par_temp_load_data.weighted_load(k); %Reactive power scaling