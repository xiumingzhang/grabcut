function BK_SetUnary(Handle,Costs)
% BK_SetUnary   Set the unary cost of individual variables.
%    BK_SetUnary(Handle,Costs) accepts a 2-by-NumVars 
%    int32 matrix where Costs(k,i) is the cost of assigning
%    label k to site i. In this case, the MATLAB matrix is pointed to 
%    by the C++ code, and so a DataCost array is not copied.
%
%    TODO: document behaviour for dynamic graph cuts
%

BK_LoadLib();
if (nargin ~= 2), error('Expected 2 arguments'); end
if (~isnumeric(Costs)), error('Costs must be numeric'); end
if (~isreal(Costs)), error('Costs cannot be complex'); end
NumSites = bk_matlab('bk_getnumsites', Handle);
if (any(size(Costs) ~= [ 2 NumSites ]))
    error('Costs size must be [ 2 NumSites ]');
end
if (~isa(Costs,'int32') && strcmp(bk_matlab('bk_getcosttype'),'int32'))
    if (NumSites*2 > 200 || any(any(floor(Costs) ~= Costs)))
        warning('BK:int32','Costs converted to int32');
    end
    Costs = int32(Costs);
end
bk_matlab('bk_setunary',Handle,Costs);
end
