%%Load data Loader
function [load_data_return] = import_load_data(LOAD_SHEET)
    load_data_table = readtable(LOAD_SHEET);
    load_data_return = [table2array(load_data_table(:,3)) , table2array(load_data_table(:,5))];
end