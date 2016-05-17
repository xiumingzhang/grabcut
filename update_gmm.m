function [gmm_U, gmm_B] = update_gmm(im_1d, pix_U, k_U, pix_B, k_B)
%UPDATE_GMM Part of GrabCut. Update the GMM parameters with newly assigned
%data
%
% Inputs:
%   - im_1d: 1D RGB image
%   - pix_U: Logical indices for foreground
%   - k_U: their Gaussian memberships in the GMM
%   - pix_B: Logical indices for background
%   - k_B: their Gaussian memberships in the GMM
%
% Output:
%   - gmm_U: updated GMM for T_U pixels
%   - gmm_B: updated GMM for T_B pixels
%
% Author:
%   Xiuming Zhang
%   GitHub: xiumingzhang
%   Dept. of ECE, National University of Singapore
%   April 2015
%

%----------- T_U

rgb_pts = im_1d(pix_U, :);

no_gauss = numel(unique(k_U));

gmm_U = cell(no_gauss, 3);

% For each Gaussian
for idx = 1:no_gauss
    pts = rgb_pts(k_U==idx, :);
    gmm_U{idx, 1} = size(pts, 1)/size(rgb_pts, 1); % pi
    gmm_U{idx, 2} = mean(pts, 1);
    gmm_U{idx, 3} = cov(pts);
end

%----------- T_B

rgb_pts = im_1d(pix_B, :);

no_gauss = numel(unique(k_B));

gmm_B = cell(no_gauss, 3);

% For each Gaussian
for idx = 1:no_gauss
    pts = rgb_pts(k_B==idx, :);
    gmm_B{idx, 1} = size(pts, 1)/size(rgb_pts, 1); % pi
    gmm_B{idx, 2} = mean(pts, 1);
    gmm_B{idx, 3} = cov(pts);
end

