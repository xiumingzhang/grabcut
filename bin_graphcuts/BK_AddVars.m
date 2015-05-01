function id = BK_AddVars(Handle,Count)
% BK_AddVars
%    id = BK_AddVars(Handle,Count) adds Count variables to the
%    binary energy with consecutive ids, returning the first id.

if (nargin < 2), error('expected two input arguments'); end

BK_LoadLib();
id = bk_matlab('bk_addvars',Handle,int32(Count));
end
