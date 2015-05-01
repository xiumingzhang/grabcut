function Energy = BK_Minimize(Handle)
% BK_Minimize   Compute optimal labeling via graph cut
%    Returns the energy of the computed labeling.
%    The labeling itself can be retrieved via GCO_GetLabeling.
%

BK_LoadLib();
Energy = bk_matlab('bk_minimize',Handle);
end
