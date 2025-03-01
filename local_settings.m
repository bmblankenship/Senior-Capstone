classdef local_settings
    % See SETTINGS_TMPLATE.txt for proper formatting of settings document.
    properties
        verbose % Integer: value of 0, 1 or 2. Set to 0 for no output to console to increase simulation speed
        outage_sheet % String: Name of the outage sheet being used eg: 'RequiredOutages.xlsx'
        load_sheet % String: Name of the load sheet being used eg: 'HourlyLoad.xlsx'
        algorithm % String: The algorithm for which power flow algorithm will be used eg: 'NR-SH'
        case_name % String: The case which is being ran eg: 'case118_CAPER_PeakLoad.m'
        end_hour % Integer: number of hours of the year to iterate over, maximum value 8760
        start_hour % Integer: hour index in year to start the simulation. Default should be 1 for most cases
        case_sheet % String: The Excel sheet containing the original case data
        block_dispatch % Integer: value of 0 or 1. 1 = enable or 0 = disable block dispatch
        generation_outage % Integer: value of 0 or 1. 1 = enable or 0 = disable generation outages
    end

    methods
        function this = local_settings()
            fid = fopen('settings.txt');
            this.verbose = cell2mat(textscan(fid, '%d', 1, 'delimiter', '\n', 'headerlines', 3));
            this.outage_sheet = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.load_sheet = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.algorithm = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.case_name = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.end_hour = cell2mat(textscan(fid, '%d', 1, 'delimiter', '\n', 'headerlines', 2));
            this.start_hour = cell2mat(textscan(fid, '%d', 1, 'delimiter', '\n', 'headerlines', 2));
            this.case_sheet = string(textscan(fid, '%q', 1, 'delimiter', '\n', 'headerlines', 2));
            this.block_dispatch = cell2mat(textscan(fid, '%d', 1, 'delimiter', '\n', 'headerlines', 2));
            this.generation_outage = cell2mat(textscan(fid, '%d', 1, 'delimiter', '\n', 'headerlines', 2));
        end
    end
end
