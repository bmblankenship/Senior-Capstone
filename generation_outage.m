classdef generation_outage
    % generator_outage - A class to store outage data
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
        start_hour = 0
        end_hour = 0
        bus = 0
        real_power = 0
    end
    methods
        function this = generation_outage(start_hour, duration, bus, real_power)
            this.start_hour = start_hour;
            this.end_hour = duration + start_hour;
            this.bus = bus;
            this.real_power = real_power;
        end
    end
end