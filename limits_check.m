function [limit_check_return, failure_params] = limits_check(mpc_case)
    % limits_check - A function to verify health of the system under different outage cases
    %   Returns
    %       limit_check_return => boolean value for state of limit check
    %           True = passed
    %           False = failed
    %       failure_params => returns structure with information pertaining to failure conditions
    %   Inputs
    %       mpc_case is the result of a powerflow from runpf.
    
    % Structure format for return information
    failure_params = struct;
    failure_params.vmag = [];
    failure_params.MVA = [];
    failure_params.vmag_val = [];
    failure_params.MVA_val = [];
    i = 1;
    limit_check_return = true;

    % MVA limit check
    for n = 1:height(mpc_case.branch)
        s1 = sqrt(mpc_case.branch(n,14)^2 + mpc_case.branch(n,15)^2);
        s2 = sqrt(mpc_case.branch(n,16)^2 + mpc_case.branch(n,17)^2);
        % Use whichever apparent power is higher
        if(s1 > s2)
            apparent_power = s1;
        else
            apparent_power = s2;
        end

        if((apparent_power > mpc_case.branch(n,6)))
            failure_params.MVA(i) = n;
            failure_params.MVA_val(i) = apparent_power;
            limit_check_return = false;
            i = i + 1;
        end
    end

    % Voltage Magnitude limit check
    i = 1;
    for n = 1:height(mpc_case.bus)
        % Note that these are hard coded values as discussed earlier in the project
        if((mpc_case.bus(n,8) >= 1.1 || mpc_case.bus(n,8) <= 0.9))
            failure_params.vmag(i) = n;
            failure_params.vmag_val(i) = mpc_case.bus(n,8);
            limit_check_return = false;
            i = i + 1;
        end
    end
end