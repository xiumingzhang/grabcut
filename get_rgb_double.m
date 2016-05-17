function rgb = get_rgb_double(im, x, y)
%GET_RGB_DOUBLE Part of GrabCut. Obtain a RGB tuple in double
%
% Inputs:
%   - im: 2D image
%   - x: horizontal position
%   - y: vertical position
%
% Output:
%   - rgb: double 3-vector
%
% Author:
%   Xiuming Zhang
%   GitHub: xiumingzhang
%   Dept. of ECE, National University of Singapore
%   April 2015
%

r = im(y, x, 1);
g = im(y, x, 2);
b = im(y, x, 3);

rgb = double([r g b]);
