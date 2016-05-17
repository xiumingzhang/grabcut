function [k_U, k_B] = assign_gauss(im_1d, pix_U, gmm_U, pix_B, gmm_B)
%ASSIGN_GAUSS Assign pixels in T_U and T_B to the most probable Gaussians
%in gmm_U and gmm_B, repspectively.
%
% Inputs:
%   - im_1d: Nx3 RGB points
%   - pix_U: Logical indices for foreground
%   - gmm_U: GMM for foreground
%   - pix_B: Logical indices for background
%   - gmm_B: GMM for background
%
% Output:
%   - k_U: new label assignments for the T_U pixels
%   - k_B: new label assignments for the T_B pixels
%
% Author:
%   Xiuming Zhang
%   GitHub: xiumingzhang
%   Dept. of ECE, National University of Singapore
%   April 2015
%

%-------------- T_U

% Each row holds a T_U pixel's D to all Gaussians in the T_U GMM
pix_D = zeros(sum(pix_U), size(gmm_U, 1));

rgb_pts = im_1d(pix_U, :);

% For every Gaussian
for idx = 1:size(gmm_U, 1)
    pi_coeff = gmm_U{idx, 1};
    mu = gmm_U{idx, 2};
    sigma = gmm_U{idx, 3};
    
    col = -log(mvnpdf(rgb_pts, mu, sigma))-log(pi_coeff)-1.5*log(2*pi);
    pix_D(:, idx) = col;
end

[~, k_U] = min(pix_D, [], 2);

%-------------- T_B

% Each row holds a T_U pixel's D to all Gaussians in the T_U GMM
pix_D = zeros(sum(pix_B), size(gmm_B, 1));

rgb_pts = im_1d(pix_B, :);

% For every Gaussian
for idx = 1:size(gmm_B, 1)
    pi_coeff = gmm_B{idx, 1};
    mu = gmm_B{idx, 2};
    sigma = gmm_B{idx, 3};
    
    col = -log(mvnpdf(rgb_pts, mu, sigma))-log(pi_coeff)-1.5*log(2*pi);
    pix_D(:, idx) = col;
end

[~, k_B] = min(pix_D, [], 2);

