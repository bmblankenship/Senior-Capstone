%%generator outage
function [generator_outage] = generator_outage(filename, tabname)
    generator_data = readtable(filename, "sheet", tabname);
    gen_block_data = table2array(readtable(CASE_SHEET, "sheet", "Gen"));
    
    bus = table2array(generator_data(:,1));
    gen_start_dates = table2array(generator_data(:,4));
    gen_outage_duration = table2array(generator_data(:,5));
    
    start_hours = [zeros, length(gen_start_dates)];
    end_hours = [zeros, length(gen_outage_duration)];

    for k = 1:length(gen_start_dates)
        d = day(gen_start_dates(k), 'dayofyear');
        start_hours(k) = d * 24;
    end
    
    for k = 1:length(gen_outage_duration)
        end_hours(k) = gen_outage_duration(k) * 168;
    end

    generator_outage = table2array(table(bus, transpose(start_hours), transpose(end_hours)));

    for k = 1:height(generator_outage)
        for j = 1:height(gen_block_data)
            if(gen_block_data(j,1) == generator_outage(k,1))
                generator_outage(k,4) = gen_block_data(j,22);
            end
        end
    end
end