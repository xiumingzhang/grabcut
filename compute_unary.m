function D_min = compute_unary(rgb_pt, gmm_params)
%COMPUTE_UNARY Part of GrabCut. Compute unary (data) term
%
% Inputs:
%   - rgb_pt: a RGB point
%   - gmm_params: GMM parameters
%
% Output:
%   - D_min: minimum D
%
% Author:
%   Xiuming Zhang
%   GitHub: xiumingzhang
%   Dept. of ECE, National University of Singapore
%   April 2015
%

% The pixel's D to all Gaussians in this GMM
pix_D = zeros(size(gmm_params, 1), 1);

% For every Gaussian
for idx = 1:size(gmm_params, 1)
    pi_coeff = gmm_params{idx, 1};
    mu = gmm_params{idx, 2};
    sigma = gmm_params{idx, 3};
    
    val = -log(mvnpdf(rgb_pt, mu, sigma))-log(pi_coeff)-1.5*log(2*pi);
    pix_D(idx) = val;
end

D_min = min(pix_D);
