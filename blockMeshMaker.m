% This function will accept the following input variables:
% nAngles = number of angular partitions. There will always be a
% vertical "pie slice" but the number of horizontal slices vary
% radialExpansion = vector for expansion ratios [radial angular] (z = 1)
% Lf = fore distance (measured in cylinder diameters)
% Lw = wake distance (measured in cylinder diameters)
% R = radial size (measured in cylinder diameters)
% H = half-domain height (measured in cylinder diameters)
% rectExpansion = vector for expansion ratios [horz vert] (z = 1)
% The function will save a file to MATLAB directory (where this function
% rests) and display the following:
% Number of radial blocks
% Number of rectangular blocks
% Number of inlet/outlet faces
% Number of cylinder faces
function [] = blockMeshMaker(nAngles, radialExpansion, rectExpansion, Lf, Lw, R, H)