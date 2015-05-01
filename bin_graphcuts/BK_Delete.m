function BK_Delete(Handle)
% BK_Delete    Delete a BK object.
%    BK_Delete(Handle) deletes the object corresponding to Handle 
%    and frees its memory.

bk_matlab('bk_delete',int32(Handle));
end
