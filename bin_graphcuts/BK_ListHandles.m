function Handles = BK_ListHandles()
% BK_ListHandles     Retrieve handles to all current BK instances
%    Useful for cleaning up BK instances that are using memory,
%    particularly when a script was interrupted.
%    Example:
%        BK_Delete(BK_ListHandles);  % delete all BK instances

BK_LoadLib();
Handles = bk_matlab('bk_listhandles');
end
