function [pix_U_new, E] = cut_Tu(pix_U, im_sub, alpha, gmm_U, gmm_B, pairwise)
%CUT_TU Part of GrabCut. Relabel with Graph Cut the pixels in T_U as
%either still T_U (1) or T_B (0)
%
% Inputs:
%   - pix_U: logical indices for forground
%   - im_sub: 2D subimage, on which Graph Cut is performed
%   - alpha: initial foreground indices
%   - gmm_U: parameters of the T_U GMM
%   - gmm_B: parameters of the T_B GMM
%   - pairwise: pairwise term computed beforehand
%
% Output:
%   - pix_U: IDs of pixels who are still in T_U after Graph Cut
%   - E: energy after Graph Cut
%
% Author:
%   Xiuming Zhang
%   GitHub: xiumingzhang
%   Dept. of ECE, National University of Singapore
%   April 2015
%

% Get image dimensions
[im_h, im_w, ~] = size(im_sub);
% Compute #. nodes (pixels)
no_nodes = im_h*im_w;

%------------------- Compute MRF edge values

unary = zeros(2, no_nodes);

% Loop through all the pixels (nodes) and set pairwise and label_costs 
fprintf('Computing unary terms...\n');
for y = 1:im_h
    fprintf('%d/%d ', y, im_h);
    for x = 1:im_w
        % Current node
        color = get_rgb_double(im_sub, x, y);
        node = (x-1)*im_h+y;
        
        %------ Compute data term
        % 1 for foreground
        % 2 for backround
        unary(1, node) = compute_unary(color, gmm_U);
        unary(2, node) = compute_unary(color, gmm_B);
    end
end

%------------------- Create MRF

mrf = BK_Create(no_nodes);
% Nodes are arranged in 1-D, following this order
% (1, 1), (2, 1), ..., (573, 1), (1, 2), (2, 2), ...

%------------------- Set unary

BK_SetUnary(mrf, unary);

%------------------- Set pairwise

BK_SetPairwise(mrf, pairwise);

%------------------- Graphcuts

E = BK_Minimize(mrf);
gc_labels = BK_GetLabeling(mrf);

BK_Delete(mrf);

%------------------- Kick out T_B pixels from T_U

pix_U_new = pix_U;

% Replace initial labels with Graph Cut labels
alpha(alpha==1) = gc_labels;

% Remove background pixels from T_U
pix_U_new(alpha==2) = 0;
