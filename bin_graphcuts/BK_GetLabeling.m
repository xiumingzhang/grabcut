function Labeling = BK_GetLabeling(Handle)
% BK_GetLabeling     Retrieve the current labeling
%     BK_GetLabeling(Handle) returns a column vector of all labels.

BK_LoadLib();
Labeling = bk_matlab('bk_getlabeling',Handle);
end
