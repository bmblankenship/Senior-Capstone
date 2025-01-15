%% Base Case NYI
function [base_case] = base_schedule_case(schedule)
    % Obtain the ranges that will be simulated from the schedule.
    % This avoids running hours again after the original N-1 contingency that do not need to be reran
    % Must be indexed to obtain the proper values later on.
    % Format:
    % Branch Number | Start Time | End Time

    base_case_branch_outages = schedule(branch_number);
    base_case_start_hours = schedule(start_time);
    base_case_end_hours = schedule(end_time);

    for i = 1:length(base_case_branch_outages) % Index through branches
    end
end