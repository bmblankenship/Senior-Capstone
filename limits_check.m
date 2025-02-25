function [limit_check_return, failure_params] = limits_check(mpc_case)
    % limits_check - A function to verify health of the system under different outage cases
    %   Returns
    %       limit_check_return => Returns formatted strings to indicate either a full pass:
        %       Pass: 11 PP
        %       Otherwise indicates the failure mode and branches or busses the failure was located at.
        %       Failure: 00 106||109
    %       failure_params => returns structure with information pertaining to failure conditions
    %   Inputs
    %       mpc_case is the result of a powerflow from runpf.
    failure_params = struct;
    failure_params.vmag = [];
    failure_params.MVA = [];
    failure_params.vmag_val = [];
    failure_params.MVA_val = [];
    i = 1;

    MVA_success_flag = true;
    %{
    for n = 1:height(mpc_case.branch)
        s1 = sqrt(mpc_case.branch(n,14)^2 + mpc_case.branch(n,15)^2);
        s2 = sqrt(mpc_case.branch(n,16)^2 + mpc_case.branch(n,17)^2);
        if(s1 > s2)
            apparent_power = s1;
        else
            apparent_power = s2;
        end

        if((apparent_power > mpc_case.branch(n,6)))
            failure_params.MVA(i) = n;
            failure_params.MVA_val(i) = apparent_power;
            MVA_success_flag = false;
            i = i + 1;
        end
    end
    %}

    voltage_success_flag = true;
    
    i = 1;
    for n = 1:height(mpc_case.bus)
        if((mpc_case.bus(n,8) >= 1.1 || mpc_case.bus(n,8) <= 0.9))
            failure_params.vmag(i) = n;
            failure_params.vmag_val(i) = mpc_case.bus(n,8);
            voltage_success_flag = false;
            i = i + 1;
        end
    end
    
    % Return format
    % VMag MVAMag Bus Branch
    if(~voltage_success_flag || ~MVA_success_flag)
        limit_check_return = false;
    else
        limit_check_return = true;
    end
end