function [limit_check_return] = limits_check(mpc_case)

    MVA_success_flag = true;
    MVA_failure_branch = 'P';
    for n = 1:height(mpc_case.branch)
        s1 = sqrt(mpc_case.branch(n,14)^2 + mpc_case.branch(n,15)^2);
        s2 = sqrt(mpc_case.branch(n,16)^2 + mpc_case.branch(n,17)^2);
        if(s1 > s2)
            apparent_power = s1;
        else
            apparent_power = s2;
        end

        if((apparent_power > mpc_case.branch(n,6)) && MVA_success_flag)
            MVA_failure_branch = int2str(n);
            MVA_success_flag = false;
        elseif(apparent_power > mpc_case.branch(n,6))
            MVA_failure_branch = append('/', int2str(n));
        end
    end

    voltage_success_flag = true;
    voltage_failure_bus = 'P';
    for n = 1:height(mpc_case.bus)
        if((mpc_case.bus(n,8) >= 1.1 || mpc_case.bus(n,8) <= 0.9) && voltage_success_flag)
            voltage_failure_bus = int2str(n);
            voltage_success_flag = false;
        elseif(mpc_case.bus(n,8) >= 1.1 || mpc_case.bus(n,8) <= 0.9)
            voltage_failure_bus = append('/', int2str(n));
        end
    end
    
    % Return format
    % VMag MVAMag Bus Branch
    if(~voltage_success_flag && ~MVA_success_flag)
        limit_check_return = append('00 ', voltage_failure_bus, ' ', MVA_failure_branch);
    elseif(voltage_success_flag && ~MVA_success_flag)
        limit_check_return = append('10 ', voltage_failure_bus, ' ', MVA_failure_branch);
    elseif(~voltage_success_flag && MVA_success_flag)
        limit_check_return = append('01 ', voltage_failure_bus, ' ', MVA_failure_branch);
    else
        limit_check_return = append('11 ', voltage_failure_bus, ' ', MVA_failure_branch);
    end
end