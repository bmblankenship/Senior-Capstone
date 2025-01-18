classdef generation_block
    properties
        busses
        capacity
        total_capacity
        block_table
    end
    methods
        function this = generation_block(settings, block)
            w=warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            this.block_table = table2array(readtable(settings.case_sheet, "sheet", "Gen"));
            warning(w);
            
            this.busses = index_busses(this, block, this.block_table);
            this.capacity = index_capacity(this, block, this.block_table);
            this.total_capacity = calc_total_capacity(this, block, this.block_table);
        end

        function total_capacity = lower_cap(this, val)
            total_capacity = this.total_capacity - val;
        end

        function total_capacity = inc_cap(this, val)
            total_capacity = this.total_capacity + val;
        end
        
        function busses = index_busses(this, block, block_arr)
            busses = [];
            for k = 1:height(block_arr)
                if(block_arr(k,22) == block)
                    busses(end+1,1) = block_arr(k,1);
                end
            end
        end

        function capacity = index_capacity(this, block, block_arr)
            capacity = [];
            for k = 1:height(block_arr)
                if(block_arr(k,22) == block)
                    capacity(end+1,1) = block_arr(k,9);
                end
            end
        end

        function total_capacity = calc_total_capacity(this, block, block_arr)
            total_capacity = 0;
            for k = 1:height(block_arr)
                if(block_arr(k,22) == block)
                    total_capacity = total_capacity + block_arr(k,9);
                end
            end
        end
    end
end
