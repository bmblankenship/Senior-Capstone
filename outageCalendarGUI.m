function outageCalendarGUI(initial_results_array)
    % Load Data
    filename = 'ScheduleOrder.xlsx'; % Update with actual filename
    data = readtable(filename);

    % Convert first column to datetime
    dates = datetime(data{:,1}, 'InputFormat', 'dd/MM/yyyy HH:mm');
    hours = data{:,2}; % 1 to 8760
    outages = data{:,3:end}; % Outage data (branches)

    % Create GUI Window with larger size
    fig = uifigure('Name', 'Outage Calendar', 'Position', [100 100 1200 700]);
    
    % Year Navigation (initially visible) - Updated positions
    yearLabel = uilabel(fig, 'Position', [500 650 200 30], 'FontSize', 14, 'FontWeight', 'bold');
    prevYearButton = uibutton(fig, 'Text', '<< Prev Year', 'Position', [250 650 100 30], 'ButtonPushedFcn', @(~,~) updateYearView(-1));
    nextYearButton = uibutton(fig, 'Text', 'Next Year >>', 'Position', [650 650 100 30], 'ButtonPushedFcn', @(~,~) updateYearView(1));
    
    % Month Navigation (initially invisible) - Updated positions
    monthLabel = uilabel(fig, 'Position', [500 650 200 30], 'FontSize', 14, 'FontWeight', 'bold', 'Visible', 'off');
    prevButton = uibutton(fig, 'Text', '<< Prev', 'Position', [250 650 80 30], 'ButtonPushedFcn', @(~,~) updateCalendar(-1), 'Visible', 'off');
    nextButton = uibutton(fig, 'Text', 'Next >>', 'Position', [650 650 80 30], 'ButtonPushedFcn', @(~,~) updateCalendar(1), 'Visible', 'off');
    backButton = uibutton(fig, 'Text', 'Back to Year View', 'Position', [400 650 100 30], 'ButtonPushedFcn', @(~,~) showYearView(), 'Visible', 'off');
    
    % Legend Panel - Updated position and size
    legendPanel = uipanel(fig, 'Title', 'Legend', 'Position', [800 560 350 90]);
    createLegendItem(legendPanel, [0.5 1 0.5], 'Normal Operation', [10 45 200 20]);
    createLegendItem(legendPanel, [0.4 0.6 1], 'Scheduled Outage', [10 25 200 20]);
    createLegendItem(legendPanel, [1 0.4 0.4], 'System Failure', [10 5 200 20]);
    createLegendItem(legendPanel, [0.7 0.7 0.7], 'Mixed Conditions', [10 65 200 20]);
    
    % Outage Details Panel - Updated position and size
    detailsPanel = uipanel(fig, 'Title', 'Scheduled Outage Details', 'Position', [800 100 350 450]);
    
    % Label for selected day
    selectedDayLabel = uilabel(detailsPanel, 'Position', [10 370 200 30], 'FontSize', 12, 'FontWeight', 'bold');
    
    % Table to display outage details
    detailsTable = uitable(detailsPanel, 'Position', [10 10 330 350], 'ColumnName', {'Hour', 'Branches Out'}, 'RowName', [], 'ColumnWidth', {80 230});

    % Set Initial Year and Month
    currentMonth = month(dates(1));
    currentYear = year(dates(1));
    
    % Grid Panel for Calendar - Updated position and size
    panel = uipanel(fig, 'Position', [50 100 700 550]);

    % Initialize Year View
    showYearView();
    
    function createLegendItem(parent, color, text, position)
        p = uipanel(parent, 'Position', position);
        box = uipanel(p, 'Position', [5 5 15 15], 'BackgroundColor', color);
        label = uilabel(p, 'Position', [25 0 170 20], 'Text', text);
    end
    
    function showYearView()
        % Update visibility
        yearLabel.Visible = 'on';
        prevYearButton.Visible = 'on';
        nextYearButton.Visible = 'on';
        monthLabel.Visible = 'off';
        prevButton.Visible = 'off';
        nextButton.Visible = 'off';
        backButton.Visible = 'off';
        
        % Update year label
        yearLabel.Text = sprintf('%d', currentYear);
        
        % Clear previous view
        delete(panel.Children);
        
        % Create grid for months with improved spacing
        grid = uigridlayout(panel, [4, 3]);
        grid.Padding = [10 10 10 10];
        grid.RowSpacing = 10;
        grid.ColumnSpacing = 10;
        grid.RowHeight = {'1x', '1x', '1x', '1x'};
        grid.ColumnWidth = {'1x', '1x', '1x'};
        
        % Create month buttons without coloring
        for m = 1:12
            monthBtn = uibutton(grid, 'Text', datestr(datetime(currentYear, m, 1), 'mmmm'));
            monthBtn.UserData = m;
            monthBtn.ButtonPushedFcn = @(src, ~) showMonthView(src.UserData);
            monthBtn.FontSize = 12;
            monthBtn.FontWeight = 'bold';
        end
    end
    
    function showMonthView(month)
        currentMonth = month;
        
        % Update visibility
        yearLabel.Visible = 'off';
        prevYearButton.Visible = 'off';
        nextYearButton.Visible = 'off';
        monthLabel.Visible = 'on';
        prevButton.Visible = 'on';
        nextButton.Visible = 'on';
        backButton.Visible = 'on';
        
        updateCalendar(0);
    end
    
    function updateYearView(direction)
        currentYear = currentYear + direction;
        showYearView();
    end

    function updateCalendar(direction)
        % Change Month
        currentMonth = currentMonth + direction;
        if currentMonth < 1
            currentMonth = 12;
            currentYear = currentYear - 1;
        elseif currentMonth > 12
            currentMonth = 1;
            currentYear = currentYear + 1;
        end
        
        % Update Label
        monthLabel.Text = datestr(datetime(currentYear, currentMonth, 1), 'mmmm yyyy');
        
        % Clear previous calendar
        delete(panel.Children);
        
        % Create a grid layout with improved spacing
        grid = uigridlayout(panel, [7, 7]);
        grid.Padding = [10 10 10 10];
        grid.RowSpacing = 10;
        grid.ColumnSpacing = 10;
        grid.RowHeight = {'fit', '1x', '1x', '1x', '1x', '1x', '1x'};
        grid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};

        % Weekday Labels
        dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        for i = 1:7
            label = uilabel(grid);
            label.Text = dayNames(i);
            label.FontWeight = 'bold';
            label.FontSize = 11;
            label.HorizontalAlignment = 'center';
            label.Layout.Row = 1;
            label.Layout.Column = i;
        end
        
        % Get First Day and Number of Days in Month
        first_of_month = datetime(currentYear, currentMonth, 1);
        firstDay = weekday(first_of_month);
        numDays = eomday(currentYear, currentMonth);
        
        % Fill in the calendar days
        dayCount = 1;
        for week = 1:6
            for wday = 1:7
                row = week + 1;
                col = wday;
                
                if week == 1 && wday < firstDay
                    continue;
                end
                
                if dayCount > numDays
                    break;
                end
                
                thisDate = datetime(currentYear, currentMonth, dayCount);

                dayMask = (year(dates) == year(thisDate)) & ...
                          (month(dates) == month(thisDate)) & ...
                          (day(dates) == day(thisDate));

                hasFailure = false;
                hasOutage = false;
                hasNormal = false;

                for j = 1:length(dayMask)
                    if dayMask(j)
                        if isequal(initial_results_array{j}, 0)
                            hasFailure = true;
                        else
                            dailyOutages = outages(j, :);
                            if any(~isnan(dailyOutages) & ~ismissing(dailyOutages))
                                hasOutage = true;
                            else
                                hasNormal = true;
                            end
                        end
                    end
                end

                if (hasFailure && hasOutage) || (hasFailure && hasNormal) || (hasOutage && hasNormal)
                    bgColor = [0.7 0.7 0.7];
                else
                    if hasFailure
                        bgColor = [1 0.4 0.4];
                    elseif hasOutage
                        bgColor = [0.4 0.6 1];
                    else
                        bgColor = [0.5 1 0.5];
                    end
                end
                
                btn = uibutton(grid, 'Text', num2str(dayCount));
                btn.HorizontalAlignment = 'center';
                btn.FontWeight = 'bold';
                btn.FontSize = 11;
                btn.BackgroundColor = bgColor;
                btn.Layout.Row = row;
                btn.Layout.Column = col;
                btn.UserData = thisDate;
                btn.ButtonPushedFcn = @(src, ~) showDetails(src.UserData);
                
                dayCount = dayCount + 1;
            end
            
            if dayCount > numDays
                break;
            end
        end
    end

    function showDetails(selectedDate)
        selectedDayLabel.Text = sprintf('Scheduled Outages for %s', datestr(selectedDate, 'mmmm dd, yyyy'));
        detailsTable.Data = cell(24, 2);
        
        for h = 0:23
            hourTimestamp = datetime(year(selectedDate), month(selectedDate), day(selectedDate), h, 0, 0);
            hourMask = (year(dates) == year(hourTimestamp)) & ...
                       (month(dates) == month(hourTimestamp)) & ...
                       (day(dates) == day(hourTimestamp)) & ...
                       (hour(dates) == hour(hourTimestamp));

            if any(hourMask)
                if any(cellfun(@(x) isequal(x, 0), initial_results_array(hourMask)))
                    branchStr = 'SYSTEM FAILURE';
                else
                    branchesOut = outages(hourMask, :);
                    branchesOut = branchesOut(~ismissing(branchesOut) & ~isnan(branchesOut));
                    branchStr = "None";
                    if ~isempty(branchesOut)
                        branchStr = strjoin(string(branchesOut), ', ');
                    end
                end
            else
                branchStr = "None";
            end
            
            detailsTable.Data{h+1, 1} = sprintf('%02d:00', h);
            detailsTable.Data{h+1, 2} = char(branchStr);
        end
    end
end
