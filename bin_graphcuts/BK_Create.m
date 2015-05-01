function Handle = BK_Create(NumVars,MaxEdges)
% BK_Create    Create a BK object.
%    Handle = BK_Create() creates a new BK object and returns a 'handle' 
%    to uniquely identify it. Use BK_AddVars to add variables.
%
%    Handle = BK_Create(NumVars) creates a new BK object with NumVars 
%    variables already created.
%
%    Handle = BK_Create(NumVars,MaxEdges) pre-allocates memory for up to m edges.
%
%    Call BK_Delete(Handle) to delete the object and free its memory.
%    Call BK_Delete(BK_ListHandles) to delete all BK objects.

BK_LoadLib();
if (nargin < 1), NumVars = 0; end
if (nargin < 2), MaxEdges = 0; end
Handle = bk_matlab('bk_create',int32(NumVars),int32(MaxEdges));
end
