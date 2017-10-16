function [decisions, plotdata] = ParseDecisionLogs(varargin)
% ParseDecisionLogs extracts ViewRay gating log information from a
% delivered treatment using the VrSvcDPWinService logs stored on the TPDS.
% Either one or three variables can be provided, as detailed below.  The 
% data is processed to estimate the "duty cycle" for the treatment
% delivery and number of beam on/off/on transitions, or beam shutters that
% would occur (assuming a zero second wait time) due to the decision logs.
%
% The following variables are required for proper execution: 
%   varargin{1}: input string containing the directory which stores the 
%       VrSvcDPWinService logs
%   varargin{2} (optional): start date and time (as a string) for the
%       treatment delivery
%   varargin{3} (optional): end stop date and time for the treatment 
%
% The following variables are returned upon succesful completion:
% 	decisions: an n x 5 array where n is the number of decisions 
%       identified, column 1 is the timestamp, column 2 is a decision flag, 
%       column 3 is the number of voxels outside of the boundary, column 4 
%       is the total number of deformed voxels in the target, and column 5 
%       is the fraction of voxels out.  
%   plotdata: a 3 x 101 cumulative histogram, where the column 1 is the 
%       Percent ROI (as a fraction), column 2 are the decisions less than 
%       or equal to the Percent ROI, normalized to the number of decisions,
%       and column 3 is the number of beam shutter transitions that would
%       occur due to a a decision exceeding the Percent ROI.
%
% The following is an example of how to call this function:
%   [decisions, histogram] = ParseDecisionLogs('./Target Decision Logs', ...
%       '9/9/2014 11:06:12 AM', '9/9/2014 12:00:00 PM');
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2014 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

if nargin ~= 1 && nargin ~= 3 
    error('Incorrect number of input arguments.');
end

% Retrieve folder contents of input directory
folderList = dir(varargin{1});

% Initialize folder counter
i = 0;

% Initialize return variable
decisions = zeros(0,5);

%% Start recursive loop through each folder, subfolder
while i < size(folderList, 1)
    % Increment current folder being analyzed
    i = i + 1;
    
    % If the folder content is . or .., skip to next folder in list
    if strcmp(folderList(i).name,'.') || strcmp(folderList(i).name,'..')
        continue
        
    % Otherwise, if the folder content is a subfolder    
    elseif folderList(i).isdir == 1
        % Retrieve the subfolder contents
        subFolderList = dir(fullfile(varargin{1}, folderList(i).name));
        
        % Append the subfolder contents to the main folder list
        folderList = vertcat(folderList, subFolderList); %#ok<AGROW>
        
        % Clear temporary variable
        clear subFolderList;
        
    % Otherwise, if the folder content is a decision log
    elseif size(strfind(folderList(i).name, '.xmlLog'), 1) > 0
        % Open file handle to log
        fid = fopen(fullfile(varargin{1}, folderList(i).name), 'r');
        
        % Initialize line variable
        tline = '';
        
        % While the end of file has not been reached
        while ~feof(fid)
            % Store previous line
            pline = tline;
            
            % Get next line
            tline = fgetl(fid);
            
            % Match string to MRTC deformROI data
            [match, ~] = regexp(tline, ['MRTC deformROI target out decision = ', ...
                '([0-9]+): voxels out ([0-9]+), total = ([0-9]+), tgt ', ...
                'out fraction = ([0-9\.]+)'], 'tokens', 'match');
            
            % If the string was matched
            if ~isempty(match)
                % Retrieve current size of results array
                s = size(decisions, 1);
                
                % Retrieve the timestamp from the previous line
                [match2, ~] = regexp(pline, ...
                    '<LogEntryTime>(.+)</LogEntryTime>', 'tokens', 'match');
                
                if nargin == 1 || (nargin == 3 && datenum(varargin{2}) <= ...
                        datenum(match2{1}{1}(1:20)) && datenum(varargin{3}) > ...
                        datenum(match2{1}{1}(1:20)))
                    % Store the timestamp
                    decisions(s+1,1) = datenum(match2{1}{1}(1:20)) ...
                        + str2double(match2{1}{1}(22:24))/1000;

                    % Store the entry data
                    decisions(s+1,2) = str2double(match{1}{1});
                    decisions(s+1,3) = str2double(match{1}{2});
                    decisions(s+1,4) = str2double(match{1}{3});
                    decisions(s+1,5) = str2double(match{1}{4});
                end
            end
        end
        
        % Close file handle
        fclose(fid);
    end
end

% Clear temporary variables
clear i fid match match2 s tline pline;

%% Compute duty cycle
% Initialize return variable
plotdata = zeros(101, 3);

% Set bin entries
plotdata(:, 1) = 0:100;

% Store fraction open times
fractions = squeeze(decisions(:,5)) * 100;

% Loop through each histogram bin
for i = 1:size(plotdata, 1)
    plotdata(i, 2) = length(fractions(fractions <= plotdata(i, 1)));
end

% Normalize results
plotdata(:, 2) = plotdata(:, 2)/length(fractions) * 100;

%% Compute shutter transition rate
% Loop through each percent ROI
for i = 1:size(plotdata, 1)
    % Compute the number of times a passing decision is followed by a
    % failing decision
    plotdata(i, 3) = sum(max(zeros(length(fractions),1), ...
        double(fractions > plotdata(i,1)) - ...
        circshift(double(fractions > plotdata(i,1)), -1)));
end

% Convert the shutter transition count to a rate, assuming 4 Hz
plotdata(:,3) = plotdata(:,3) * 4 * 60 / length(fractions);

%% Plot results
% Initialize figure
figure('Color', 'white');

% Plot duty cycle and shutter transitions
[hAx, ~, ~] = ...
    plotyy(plotdata(:,1), plotdata(:,2), plotdata(:,1), plotdata(:,3));

% Set figure properties
title('Decision Log Analysis');
xlim(hAx(1), [0 max(fractions)]);
xlim(hAx(2), [0 max(fractions)]);
xlabel(hAx(1),'Percent ROI (%)');
ylabel(hAx(1),'Duty Cycle (%)'); % left y-axis
ylabel(hAx(2),'Beam Shutter Transition Rate (per min)'); % right y-axis

% Clear temporary variables 
clear i fractions hAx;
