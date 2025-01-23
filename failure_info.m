classdef failure_info
    properties
        hour
        branches_out
    end

    methods
        function this = failure_info(hour, branches_out)
            this.hour = hour;
            this.branches_out = branches_out;
        end
    end
end