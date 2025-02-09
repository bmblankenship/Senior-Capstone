%% Base Case NYI
function [base_case] = base_schedule_case(schedule)
    base_case = [height(schedule),2];

    for i = 1:height(schedule) % Index through branches
        base_case(i,2) = schedule(i);
    end
end