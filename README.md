# grabcut
A MATLAB implementation of GrabCut (excluding border matting and user editing)

This project implements (in MATLAB)

@article{rother2004grabcut,
  title={Grabcut: Interactive foreground extraction using iterated graph cuts},
  author={Rother, Carsten and Kolmogorov, Vladimir and Blake, Andrew},
  journal={ACM Transactions on Graphics (TOG)},
  volume={23},
  number={3},
  pages={309--314},
  year={2004},
  publisher={ACM}
}

Note that this implememntation excludes border matting and user editing. That is, it implements everything up to "Iterative minimisation 4. Repeat from step1 until convergence" as in Figure 3 in the original paper.

Also notice, the implementation of the max-flow/min-cut algorithm used in this project is from Computer Vision Research Group at the University of Western Ontario (available [here](http://vision.csd.uwo.ca/wiki/vision/upload/d/d7/Bk_matlab.zip)).

## Results



## Example Usage

	GAMMA = 20;
	% Inputs and parameters
	im_in = imread('./grabcut/results/test4.jpg');
	% GrabCut
	im_out = grabcut(im_in, GAMMA);
	imwrite(im_out, './grabcut/results/test4_out.jpg');

