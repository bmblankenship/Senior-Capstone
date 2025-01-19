classdef generation_block
    % generation_block - A class to store generation block data for block dispatch use
    %   this.busses => array of busses in the dispatch block.
    %   this.capacity => array of the capacity located at each of the busses in this.busses
    %   this.total_capacity => the sum total of generation capacity present in the block
    %   this.block_table
    %
    %   this = generation_block(settings, block)
    %       Constructor for new block object
    %       Settings is the class referance to the settings file for the simulation
    %       block is the integer value of the block currently being generated (1-5)
    %
    %   total_capacity = lower_cap(this, val)
    %       lowers the capacity of the block by the amount passed in by val
    %
    %   total_capacity = inc_cap(this, val)
    %       increases the capacity of the block by the amount passed in by val
    %
    %   busses = index_busses(this, block, block_arr)
    %       indexes busses present in the block based on the block_arr table
    %
    %   capacity = index_capacity(this, block, block_arr)
    %       indexes capacity present in the block based on the block_arr table
    %
    %   total_capacity = calc_total_capacity(this, block, block_arr)
    %       calculates the total capacity available in the block
    properties
        busses
        capacity
        total_capacity
    end
    methods
        function this = generation_block(settings, block)
            w=warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            block_table = table2array(readtable(settings.case_sheet, "sheet", "Gen"));
            warning(w);
            
            this.busses = index_busses(this, block, block_table);
            this.capacity = index_capacity(this, block, block_table);
            this.total_capacity = calc_total_capacity(this, block, block_table);
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
