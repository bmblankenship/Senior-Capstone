classdef local_settings
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
        function this = local_settings()
            fid = fopen('settings.txt');
            this.verbose = cell2mat(textscan(fid, '%d', 1, 'delimiter', '\n', 'headerlines', 3));
            this.outage_sheet = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.load_sheet = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.algorithm = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.case_name = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.simulation_hours = cell2mat(textscan(fid, '%d', 1, 'delimiter', '\n', 'headerlines', 2));
            this.start_hour = cell2mat(textscan(fid, '%d', 1, 'delimiter', '\n', 'headerlines', 2));
            this.case_sheet = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            temp = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            if (temp == "false")
                this.block_dispatch = false;
            else
                this.block_dispatch = true;
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
    block_dispatch: enable or disable block dispatch

    example function call:
    initialization(0, 'RequiredOutages.xlsx', 'HourlyLoad.xlsx', 'NR-SH', 'case118_CAPER_PeakLoad.m', 5, 1, 'InitialCaseData.xlsx');
%}
