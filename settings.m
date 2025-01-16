classdef settings
    properties
        verbose
        outage_sheet
        load_sheet
        algorithm
        case_name
        simulation_hours
        start_hour
        case_sheet
        block_dispatch
    end

    methods
        function this = settings(verbose, outage, load, alg, cname, hours, start, csheet, dispatch)
            if nargin == 0
                this.verbose = 0;
                this.outage_sheet = 'RequiredOutages.xlsx';
                this.load_sheet = 'HourlyLoad.xlsx';
                this.algorithm = 'NR-SH';
                this.case_name = 'case118_CAPER_PeakLoad.m';
                this.simulation_hours = 5;
                this.start_hour = 1;
                this.case_sheet = 'InitialCaseData.xlsx';
                this.block_dispatch = false;
            else
                this.verbose = verbose;
                this.outage_sheet = outage;
                this.load_sheet = load;
                this.algorithm = alg;
                this.case_name = cname;
                this.simulation_hours = hours;
                this.start_hour = start;
                this.case_sheet = csheet;
                this.block_dispatch = dispatch;
            end
        end
    end
end

%{
    VERBOSE: integer value of 0, 1 or 2. Set to 0 for no output to console to increase simulation speed
    OUTAGE_SHEET: string for name of the outage sheet being used eg: 'RequiredOutages.xlsx'
    LOAD_SHEET: string for the name of the load sheet being used eg: 'HourlyLoad.xlsx'
    ALGORITHM_TYPE: string for which power flow algorithm will be used eg: 'NR'
    CASE_NAME: string for which case is being ran eg: 'case118_CAPER_PeakLoad.m'
    SIMULATION_HOURS: number of hours of the year to iterate over, maximum value 8760
    SIM_START_HOUR: hour index in year to start the simulation. Default should be 1 for most cases
    CASE_SHEET: The Excel sheet containing the original case data

    example function call:
    initialization(0, 'RequiredOutages.xlsx', 'HourlyLoad.xlsx', 'NR-SH', 'case118_CAPER_PeakLoad.m', 5, 1, 'InitialCaseData.xlsx');
%}
