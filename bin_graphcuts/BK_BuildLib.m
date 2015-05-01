function BK_BuildLib(Options)
% BK_BuildLib    Attempt to compile and link the BK_MATLAB library.
%    BK_BuildLib is used internally by all other BK_MATLAB commands 
%    to recompile the wrapper library if it is not yet built. 
%
%    YOU DO NOT NEED TO EXPLICITLY CALL THIS FUNCTION, unless you want to
%    customise the build settings via BK_BuildLib(Options).
%    Default options:
%      Options.Debug=0            % optimised, detailed checking disabled
%      Options.CostType='double'  % type of energy terms
%
%    Example:
%      % Enable detailed assertions (e.g. than energy does not go up
%      % during expansion) and use 32-bit energy counters (slightly faster)
%      BK_BuildLib(struct('Debug',1,'CostType','int32'));
%

if (nargin < 1)
    Options = struct();
end
if (~isfield(Options,'Debug')), Options.Debug = 0; end
if (~isfield(Options,'CostType')), Options.CostType = 'double'; end
if (~isfield(Options,'Force')), Options.Force = 1; end

MEXFLAGS = '';
if (strcmp(computer(),'GLNXA64') || strcmp(computer(),'PCWIN64') || strcmp(computer(),'MACI64'))
    MEXFLAGS = [MEXFLAGS ' -largeArrayDims -DA64BITS'];
end
if (Options.Debug)
    MEXFLAGS = [MEXFLAGS ' -g'];
end
if (strcmp(Options.CostType,'double'))
    MEXFLAGS = [MEXFLAGS ' -DBK_COSTTYPE=0'];
elseif (strcmp(Options.CostType,'int32'))
    MEXFLAGS = [MEXFLAGS ' -DBK_COSTTYPE=1'];
end
if (strcmp(computer(),'PCWIN')) % link with libut for user interruptibility
    MEXFLAGS = [MEXFLAGS ' -D_WIN32 "' matlabroot() '\extern\lib\win32\microsoft\libut.lib"' ];
elseif (strcmp(computer(),'PCWIN64'))
    MEXFLAGS = [MEXFLAGS ' -D_WIN64 "' matlabroot() '\extern\lib\win64\microsoft\libut.lib"' ];
else
    MEXFLAGS = [MEXFLAGS ' -lut' ];
end

LIB_NAME = 'bk_matlab';
BKDIR = fileparts(mfilename('fullpath'));
OUTDIR = [ BKDIR filesep 'bin' ];
[status msg msgid] = mkdir(BKDIR, 'bin'); % Create bin directory
addpath(OUTDIR);                              % and add it to search path
if (~Options.Force && exist('bk_matlab')==3)
    return;
end
clear bk_matlab;

mexcmd = ['mex ' MEXFLAGS ' -outdir ''' OUTDIR ''' -output ' LIB_NAME ' ' ];

% Append all source file names to the MEX command string
SRCCPP = { 
    [BKDIR filesep 'bk_matlab.cpp']
    };
for f=1:length(SRCCPP)
    mexcmd = [mexcmd ' ''' SRCCPP{f} ''' '];
end

eval(mexcmd);  % compile and link in one step

end
