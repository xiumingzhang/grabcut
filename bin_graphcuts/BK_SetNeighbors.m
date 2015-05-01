function BK_SetNeighbor(Handle,Weights)
% BK_SetNeighbors   Set sparse pairwise connectivity of all sites.
%     BK_SetNeighbors(Handle,Weights) determines which sites are 
%     neighbors and thereby have a weighted Potts interaction. 
%     Weights is a sparse NumSites-by-NumSites matrix of doubles, where 
%     Weights(i,j) > 0  indicates that sites i and j are neighbors
%     with a Sparse potential of the given strength. 
%     IMPORTANT: only the upper-triangular area of Weights is consulted 
%     because the connectivity is undirected. 
%     SetNeighbors cannot currently be called after Minimize. 

BK_LoadLib();
NumSites = bk_matlab('bk_getnumsites',Handle);
if (any(size(Weights) ~= [ NumSites NumSites ]))
    error('Neighbors must be of size [ NumSites NumSites ]');
end
if (~issparse(Weights))
    if (NumSites > 100)
        warning('Sparsifying the Neighbors matrix (performance warning)');
    end
    if (~isa(Weights,'double'))
        error('Neighbors matrix must be of type double, but with integral values');
    end
    Weights = sparse(Weights);
end
bk_matlab('bk_setneighbors',Handle,Weights);
end
