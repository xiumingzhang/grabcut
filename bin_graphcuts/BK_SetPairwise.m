function BK_SetPairwise(Handle,Edges)
% BK_SetPairwise   Set full pairwise potentials of all sites.
%     BK_SetPairwise(Handle,Edges) determines which sites are neighbors
%     and what their specific interaction potential is. 
%     Edges is a dense NumEdges-by-6 matrix of doubles 
%     (or int32 of CostType is 'int32'; see BK_BuildLib). 
%     Each row is of the format [i,j,e00,e01,e10,e11] where i and j 
%     are neighbours and the four coefficients define the interaction 
%     potential.
%     SetNeighbors cannot currently be called after Minimize. 

BK_LoadLib();
if (size(Edges,2) ~= 6)   % Check [i,j,e00,e01,e10,e11] format
    error('Edges must be of size [ NumEdges 6 ]');
end
bk_matlab('bk_setpairwise',Handle,Edges);
end
