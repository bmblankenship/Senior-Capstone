classdef scheduled_outage
    % scheduled_outage - A class to store outage data
    %   this.occuring   => Returns boolean value for if an outage is occuring
    %   this.start_hour => Returns integer value for the start hour of the year for the outage
    %   this.end_hour   => Returns integer value for the end out of the year for the outage
    %   this.branches   => Returns branch value(s) for the outages as a list
    %   this.success    => indicates if the simulated outage was successful
    %
    %   this = schedule_outage(occuring, start_hour, end_hour, branches)
    %       adds outage to the system with the input arguements for conditions
    %
    %   success = set_statue(state)
    %       sets success flag to true or false based on the state input
    properties
        occuring = false
        start_hour = 0
        end_hour = 0
        branches = []
        success = false
    end
    methods
        function this = scheduled_outage(occuring, start_hour, end_hour, branches)
            this.occuring = occuring;
            this.start_hour = start_hour;
            this.end_hour = end_hour;
            this.branches = branches;
            this.success = false;
        end

        function success = set_state(state)
            success = state;
        end
    end
end