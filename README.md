# Gating Decision Log Parser for ViewRay

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2015, University of Wisconsin Board of Regents

## Description

ParseDecisionLogs extracts ViewRay<sup>&reg;</sup> gating log information from a delivered treatment using the VrSvcDPWinService logs stored on the TPDS. Either one or three variables can be provided, as detailed below.  The data is processed to estimate the "duty cycle" for the treatment delivery and number of beam on/off/on transitions, or beam shutters that would occur (assuming a zero second wait time) due to the decision logs. ViewRay is a registered trademark of ViewRay Incorporated.

## Installation

To install this function, copy `ParseDecisionLogs.m` from this repository into your MATLAB path. 

## Usage and Documentation

This function can be executed with one or three arguments. The first contains an input string containing the directory which stores the VrSvcDPWinService logs. The second and third can contain the start and end date/time (as a string) for the treatment delivery. If not provided, the entire log range is analyzed.

```matlab
[decisions, histogram] = ParseDecisionLogs('./Target Decision Logs', ...
     '9/9/2014 11:06:12 AM', '9/9/2014 12:00:00 PM');
```

Upon completion, two variables are returned: decisions and `histogram`. `decisions` contains an n x 5 array where n is the number of decisions identified, column 1 is the timestamp, column 2 is a decision flag, column 3 is the number of voxels outside of the boundary, column 4 is the total number of deformed voxels in the target, and column 5 is the fraction of voxels out. `histogram` a 3 x 101 cumulative histogram, where the column 1 is the Percent ROI (as a fraction), column 2 are the decisions less than or equal to the Percent ROI, normalized to the number of decisions, and column 3 is the number of beam shutter transitions that would occur due to a a decision exceeding the Percent ROI.

## License

Released under the GNU GPL v3.0 License.  See the [LICENSE](LICENSE) file for further details.



This is a works in progress. Check back for more changes soon!

ParseDecisionLogs extracts ViewRay gating log information from a
% delivered treatment using the VrSvcDPWinService logs stored on the TPDS.
% Either one or three variables can be provided, as detailed below.  The 
% data is processed to estimate the "duty cycle" for the treatment
% delivery and number of beam on/off/on transitions, or beam shutters that
% would occur (assuming a zero second wait time) due to the decision logs.
%
% The following variables are required for proper execution: 
% 	varargin{1}: input string containing the directory which stores the 
%       VrSvcDPWinService logs
%   varargin{2} (optional): start date and time (as a string) for the
%       treatment delivery
%   varargin{3} (optional): end stop date and time for the treatment 
%
% The following variables are returned upon succesful completion:
% 	
%
% The following is an example of how to call this function:
%   [decisions, histogram] = ParseDecisionLogs('./Target Decision Logs', ...
%       '9/9/2014 11:06:12 AM', '9/9/2014 12:00:00 PM');
