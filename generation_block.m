classdef generation_block
    properties
        busses
        capacity
        total_capacity
        block_table
    end
    methods (Access = public)
        function this = generation_block(settings, block)
            this.block_table = table2array(readtable(settings.case_sheet, "sheet", "Gen"));
            this.busses = index_busses(block, this.block_table);
            this.capacity = index_capacity(block, this.block_table);
            this.total_capacity = calc_total_capacity(block, this.block_table);
        end
        function total_capacity = lower_cap(this, val)
            total_capacity = this.total_capacity - val;
        end
        function total_capacity = inc_cap(this, val)
            total_capacity = this.total_capacity + val;
        end
    end

    methods (Access = private)
        function val = index_busses(block, block_arr)
            val = [];

            for k = 1:height(block_arr)
                if(block_arr(k,22) == block)
                    val(end+1,1) = block_array(k,1);
                end
            end
        end

        function val = index_capacity(block, block_arr)
            val = [];

            for k = 1:height(block_arr)
                if(block_arr(k,22) == block)
                    val(end+1,1) = block_array(k,9);
                end
            end
        end

        function val = calc_total_capacity(block, block_arr)
            val = 0;

            for k = 1:height(block_arr)
                if(block_arr(k,22) == block)
                    val = val + block_array(k,9);
                end
            end
        end
    end
end
