classdef load_data
    % Load_data - A class to store load data
    %   this.weighted_load(index) => Returns a double between 0 and 1 to indicate the percentage of the maximum load present at the indexed hour.
    %   this.actual_load(index)   => Returns the actual load in megawatts at the indexed hour.
    %
    %   actual_load = add_load(this, hour, extra_load)
    %   Adds load to the system, argument extra_load must be at peak value. Will add the load from the hour passed in onwards.
    %
    %   actual_load = remove_load(this, hour, lesser_load)
    %   Removes load from the system, argument lesser_load must be at peak value. Will remove the load from the hour passed in onwards.
    properties
        weighted_load
        actual_load
    end
    methods
        function this = load_data(settings)
            load_data_table = readtable(settings.load_sheet);
            this.weighted_load = table2array(load_data_table(:,5));
            this.actual_load = table2array(load_data_table(:,3));
        end

        function actual_load = add_load(this, hour, extra_load)
            for i = hour:height(this.actual_load)
                actual_load(i) = (max(actual_load) + extra_load) * weighted_load(i);
            end
        end

        function actual_load = remove_load(this, hour, lesser_load)
            for i = hour:height(this.actual_load)
                actual_load(i) = (max(actual_load) - lesser_load) * weighted_load(i);
            end
        end
    end
end