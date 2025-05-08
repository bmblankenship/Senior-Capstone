function [schedule] = schedule_algorithm(settings, branch_outages, initial_results_array, generation_outages, load_data, mpc, gen_array, mpopt)
% schedule_agorithm - A function to set up outage data based on initial conditions
%   Returns
%       schedule => A class storing outage data
%   Inputs
%       branch outages => A strucutre of outages organized based on the 
%           priority score

    availability = ones(numel(initial_results_array),1);
    s_num = 1;
    skip = false;
    splits = false;
    for i = 1:numel(branch_outages)

        % flags
        start_hour = 0;
        slots = 0;
        set = 0;
        overlap = false;
        stack = 0;
        splits = false;
        if skip == true
            skip = false;
            continue
        end
        if ~isnan(branch_outages(i).Independency)
            stack = false;
        else
            stack = true;
        end

        % Branches for outage
        if ~isnan(branch_outages(i).Dependency) && branch_outages(i).OutageOverlap == branch_outages(i).Duration
            k = [branch_outages(i).BranchNum, branch_outages(i).Dependency];
            skip = true; % Double with a full overlap
        elseif ~isnan(branch_outages(i).Dependency) && branch_outages(i).OutageOverlap ~= branch_outages(i).Duration
            k = [branch_outages(i).BranchNum, branch_outages(i).Dependency];
            overlap = true; % Double with some overlap
            skip = true;
        else
            k = branch_outages(i).BranchNum; % Single
        end
        
        % Solutions
        for j = branch_outages(i).StartingTimeFrame:(branch_outages(i).EndingTimeFrame)
            if j>numel(initial_results_array) %fails
                start_hour = 1;
                end_hour = 1;
                branches = (k);
                schedule(s_num,1) = scheduled_outage(start_hour, end_hour, branches);
                s_num = s_num+1;
                break
            else
                if overlap == false && splits == false
                    if availability(j) == 1 && start_hour == 0 && initial_results_array{j} == 1 && slots < branch_outages(i).Duration
                        slots = slots + 1;
                    elseif (0 < slots) && (slots < branch_outages(i).Duration)
                        slots = 0;
                    elseif slots == branch_outages(i).Duration% Potential spot for single
                        start_hour = j-branch_outages(i).Duration;
                        end_hour = j-1;
                        branches = k;
                        schedule(s_num,1) = scheduled_outage(start_hour, end_hour, branches);
                        [results_array, ~] = n1_contingency(settings, schedule(s_num), generation_outages, load_data, mpc, gen_array, mpopt, start_hour, end_hour);
                        
                        if all([cellfun(@(x) isequal(x, 1), results_array)])
                            s_num = s_num+1;
                            availability(start_hour:end_hour) = 0;
                            break
                        else
                            slots = 0;
                        end
                    else
                        if branch_outages(i).Splits > 0
                            splits = true; % if split value is available then it could be allowed to split
                        end
                    end
                elseif overlap == true && splits == false && stack == true
                    if availability(j) == 1 && start_hour == 0 && initial_results_array{j} == 1 && slots < (branch_outages(i).Duration + branch_outages(i+1).Duration - branch_outages(i).OutageOverlap) && overlap == true
                        slots = slots + 1;
                    elseif (0 < slots) && (slots < branch_outages(i).Duration) && overlap == true
                        slots = 0;
                    elseif slots == (branch_outages(i).Duration + branch_outages(i+1).Duration - branch_outages(i).OutageOverlap) && overlap == true % Potential spot for double
                        start_hour = j - (branch_outages(i).Duration + branch_outages(i+1).Duration - branch_outages(i).OutageOverlap);
                        end_hour = j-(branch_outages(i+1).Duration)-1;
                        branches = k(1);
                        schedule(s_num,1) = scheduled_outage(start_hour, end_hour, branches);
                        [results_array, ~] = n1_contingency(settings, schedule(s_num), generation_outages, load_data, mpc, gen_array, mpopt, start_hour, end_hour);
                        
                        if all([cellfun(@(x) isequal(x, 1), results_array)])
                            s_num = s_num+1;
                            start_hour = end_hour + 1;
                            end_hour = end_hour + branch_outages(i).OutageOverlap;
                            branches = k;
                            schedule(s_num,1) = scheduled_outage(start_hour, end_hour, branches);
                            [results_array, ~] = n1_contingency(settings, schedule(s_num), generation_outages, load_data, mpc, gen_array, mpopt, start_hour, end_hour);
                            if all([cellfun(@(x) isequal(x, 1), results_array)])
                                s_num = s_num+1;
                                start_hour = end_hour + 1;
                                end_hour = j-1;
                                branches = k(2);
                                schedule(s_num,1) = scheduled_outage(start_hour, end_hour, branches);
                                [results_array, ~] = n1_contingency(settings, schedule(s_num), generation_outages, load_data, mpc, gen_array, mpopt, start_hour, end_hour);
                                if all([cellfun(@(x) isequal(x, 1), results_array)])
                                    s_num = s_num+1;
                                    availability(j - (branch_outages(i).Duration + branch_outages(i+1).Duration - branch_outages(i).OutageOverlap):end_hour) = 0; % do this after n-1
                                    break
                                end
                            end
                        else
                            slots = 0;
                        end
                    end
                end
                if overlap == false && splits == true && stack == true
                    if set > 0
                        j = j-set;
                    end
                    if availability(j) == 1 && start_hour == 0 && initial_results_array{j} == 1 && slots < branch_outages(i).Splits
                        slots = slots + 1;
                    elseif (0 < slots) && (slots < branch_outages(i).Splits)
                        slots = 0;
                    elseif slots == branch_outages(i).Splits %Potential spot for a split of an outage
                        start_hour = j-branch_outages(i).Splits;
                        end_hour = j-1;
                        branches = k;
                        schedule(s_num,1) = scheduled_outage(start_hour, end_hour, branches);
                        [results_array, ~] = n1_contingency(settings, schedule(s_num), generation_outages, load_data, mpc, gen_array, mpopt, start_hour, end_hour);
                        
                        if all([cellfun(@(x) isequal(x, 1), results_array)])
                            availability(start_hour:end_hour) = 0;
                            s_num = s_num+1;
                            set = set + 1;
                            slots = 0;
                            start_hour = 0;
                            if set == (branch_outages(i).Duration/branch_outages(i).Splits)
                            break
                            end
                        else
                            slots = 0;
                        end
                    end
                end
            end
            if j >= (branch_outages(i).EndingTimeFrame-branch_outages(i).Duration+1) && slots == 0 % fails
                start_hour = 1;
                end_hour = 1;
                branches = (k);
                schedule(s_num,1) = scheduled_outage(start_hour, end_hour, branches);
                s_num = s_num+1;
                break
            end
        end
    end
end