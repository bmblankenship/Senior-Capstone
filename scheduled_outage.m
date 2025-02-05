classdef scheduled_outage
    % scheduled_outage - A class to store outage data
    %   this.occuring   => Returns boolean value for if an outage is occuring
    %   this.start_hour => Returns integer value for the start hour of the year for the outage
    %   this.end_hour   => Returns integer value for the end out of the year for the outage
    %   this.branches   => Returns branch value(s) for the outages as a list
    %
    %   this = schedule_outage(occuring, start_hour, end_hour, branches)
    %       adds outage to the system with the input arguements for conditions
    properties
        occuring = false
        start_hour = 0
        end_hour = 0
        branches = []
    end
    methods
        function this = scheduled_outage(occuring, start_hour, end_hour, branches)
            this.occuring = occuring;
            this.start_hour = start_hour;
            this.end_hour = end_hour;
            this.branches = branches;
        end
    end
end