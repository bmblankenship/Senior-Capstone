function [branch_outages] = priority(sim_settings)
% priority - A function to prioritize outages based on given constraints
%   Returns
%       branch_outages => A strucutre of outages organized based on the 
%           priority score
%   Inputs
%       settings is the settings class object used to pass settings 
%           parameters. This input passes the branch outage data

    % Read Excel Required Outages Sheet 1 and converts to a structured array
    branch_outage_data = sim_settings.outage_sheet;
    branch_outages = table2struct(readtable(branch_outage_data,'Sheet', 1, ...
        'VariableNamingRule', 'preserve'));
    
    % Define time conversion factors (all lowercase for consistency)
    time_factors = struct('hour', 1, 'hours', 1, ...
                          'day', 24, 'days', 24, ...
                          'week', 168, 'weeks', 168);
    
    for i = 1:numel(branch_outages) % Loop for all outages
    
        % Convert Duration to hourly duration inputs
        d_properties = split(branch_outages(i).Duration);
        unit = string(lower(d_properties(2)));
        if isfield(time_factors, unit)
            branch_outages(i).Duration = str2double(d_properties(1))*time_factors.(unit);
        else
            warning("Unknown time unit: %s", unit);
            return % Ideally in GUI
        end
    
        % Convert Time Frame to hourly time frame inputs
        branch_outages(i).StartingTimeFrame = (day(branch_outages(i).StartingTimeFrame, "dayofyear")-1)*24+1;
        branch_outages(i).EndingTimeFrame = (day(branch_outages(i).EndingTimeFrame, "dayofyear"))*24;
    
        % Convert Overlap to hourly time frame inputs
        if ~isempty(branch_outages(i).OutageOverlap)
            o_properties = split(branch_outages(i).OutageOverlap);
            unit = string(lower(o_properties(2)));
            if isfield(time_factors, unit)
                branch_outages(i).OutageOverlap = str2double(o_properties(1))*time_factors.(unit);
            else
                warning("Unknown time unit: %s", unit);
                return % Ideally in GUI
            end
        end

        % Convert Split to hourly time frame
        if ~isempty(branch_outages(i).Splits)
            s_properties = split(branch_outages(i).Splits);
            unit = string(lower(s_properties(2)));
            if isfield(time_factors, unit)
                branch_outages(i).Splits = str2double(s_properties(1))*time_factors.(unit);
            else
                warning("Unknown time unit: %s", unit)
                return % Ideall in GUI
            end
        end
    
        % Assigning Priority Score to each outage
        priority_score = 0; % resets for next outage
        
        if ~isnan(branch_outages(i).Load_MW_) || ~isnan(branch_outages(i).LineUprate_MVA_)
            priority_score = priority_score + 50; % Power Flow Changes +50
        end
    
        if branch_outages(i).Duration <= 336
            priority_score = priority_score + 10; % Short Outage +10
        elseif branch_outages(i).Duration <= 672
            priority_score = priority_score + 20; % Medium Outage +20
        elseif branch_outages(i).Duration <= 1344
            priority_score = priority_score + 30; % Long Outage +30
        else
            priority_score = priority_score + 40; % Super Long Outage +40
        end
    
        if (branch_outages(i).EndingTimeFrame - branch_outages(i).StartingTimeFrame <= 2190)
            priority_score = priority_score + 40; % Time frame is 1/4 of a year +40 
        elseif (branch_outages(i).EndingTimeFrame - branch_outages(i).StartingTimeFrame <= 4380)
            priority_score = priority_score + 30; % Time frame is 1/2 of a year +30
        elseif (branch_outages(i).EndingTimeFrame - branch_outages(i).StartingTimeFrame <= 6570)
            priority_score = priority_score + 20; % Time frame is 3/4 of a year +20
        else
            priority_score = priority_score + 10; % Time frame is a full year +10
        end
    
        if branch_outages(i).BusStatus == "OFF"
            priority_score = priority_score + 30; % Bus Generation is turned off +30
        end
    
        if ~isnan(branch_outages(i).Dependency)
            priority_score = priority_score + 20; % Multiple outages together +20
        end
    
        if ~isnan(branch_outages(i).Independency)
            priority_score = priority_score + 10; % Outages cannot happen together +10
        end
        
        branch_outages(i).Priority = priority_score; % Assign final score to respective outage
    end
    
    % Check Dependency Priority Scores
    for i = 1:numel(branch_outages)
        for j = 1:numel(branch_outages)
            % Ensure each outage has a different score
            while i ~= j && (isequal(branch_outages(i).Priority,branch_outages(j).Priority))
                % If the outages have equal score, the one with longer duration receives a + 2 
                if branch_outages(i).Duration > branch_outages(j).Duration
                    branch_outages(i).Priority = branch_outages(i).Priority +2; 
                else
                    branch_outages(j).Priority = branch_outages(j).Priority +2;
                end
                % If the outages have equal score, the ones with a time frame less than a full year receive a + 1, not used often
                if (branch_outages(i).EndingTimeFrame - branch_outages(i).StartingTimeFrame < 8759)
                    branch_outages(i).Priority = branch_outages(i).Priority +1;
                elseif (branch_outages(j).EndingTimeFrame - branch_outages(j).StartingTimeFrame < 8759)
                    branch_outages(j).Priority = branch_outages(j).Priority +1;
                end
            end
            % If outage has a dependencey those are now allowed to be equal to each other
            priority_score = branch_outages(i).Priority;
            if ~isnan(branch_outages(i).Dependency)
                if i ~= j && (isequal(branch_outages(i).Dependency,branch_outages(j).BranchNum))
                    priority_score = max(priority_score, branch_outages(j).Priority);
                    branch_outages(j).Priority = priority_score;
                end
            end
            branch_outages(i).Priority = priority_score;
        end
    end
    
    % Sort
    [~,index] = sortrows([branch_outages.Priority].',"descend");
    branch_outages = branch_outages(index);
end