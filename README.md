# volumetric_scan_with_autofocus
During fast image acquisitions, either 2D or 3D, users can add an offset to the focal distance values in the look-up table to deal with instrument drifts. This program monitors image qualities in the background and if it sees image quality goes down due to blurry, it will modify the offset value and try to get images back to focus.
