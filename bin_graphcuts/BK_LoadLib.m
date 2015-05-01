function BK_LoadLib()
% BK_LoadLib    Attempt to load the BK_MATLAB library.
%    BK_LoadLib is used internally by all other BK_MATLAB commands 
%    to compile (if necessary), load, and bind the wrapper library. 

if (isempty(getenv('BK_MATLAB'))) 
	BK_BuildLib(struct('Force',false));
	if (exist('bk_matlab') ~= 3)
	    error('Failed to load bk_matlab library');
	end
	warning on BK:int32;
	setenv('BK_MATLAB','LOADED'); % environment variables 10x faster than 'exists'
end

end
