classdef load_data
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
    end
end