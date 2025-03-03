% This function will accept the following input variables:
% nAngles = number of angular partitions. There will always be a
% vertical "pie slice" but the number of horizontal slices vary (default
% value is 8)
% radialExpansion = vector for expansion ratios [radial angular] (z = 1)
% (default is [2 1])
% Lf = fore distance (measured in cylinder diameters) (default is 4)
% Lw = wake distance (measured in cylinder diameters) (default is 6)
% R = radial size (measured in cylinder diameters) (default is 1)
% H = half-domain height (measured in cylinder diameters) (default is 5)
% rectExpansion = vector for expansion ratios [horz vert] (z = 1) (default
% is [4 1])
% The function will save a file to MATLAB directory (where this function
% rests) and display the following:
% Number of radial blocks
% Number of rectangular blocks
% Number of inlet/outlet faces
% Number of cylinder faces
function [] = blockMeshMaker(nAngles, radialExpansion, rectExpansion,...
    Lf, Lw, R, H)
    arguments
        nAngles double {mustBeInteger, mustBeFinite, mustBeScalarOrEmpty,...
            mustBeGreaterThan(nAngles, 7)} = 8;
        radialExpansion (1, 2) double {mustBeRow, mustBeFinite,...
            mustBePositive} = [2 1];
        rectExpansion (1, 2) double {mustBeRow, mustBeFinite, ...
            mustBePositive} = [4 1];
        Lf double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 4;
        Lw double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 6;
        R double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 1;
        H double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 5;
    end
    fid = fopen("blockMeshDict", "w+"); % Create new file to write to
    % Constant lines of every blockMeshDict
    fprintf(fid, "FoamFile\n{\n\tversion:\t2.0;\n\tformat\tascii;\n"...
        +"\tclass\tdictionary;\n\tobject:\tblockMeshDict;\n}\n\n");
    fprintf(fid, "convertToMeters:\t1.0;\n\n");
    fprinf(fid, "vertices\n(\n");
    % Vertex determination - cylinder first
    theta = 360 / nAngles; % angle increment
    % Wall vertices
    for i = 0:nAngles - 1
        fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", 0.5 * cosd(theta...
            * i), 0.5 * sind(theta * i), 0, i);
    end
    % Outer radius vertices
    for i = 0:nAngles - 1
        fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", (0.5 + R) * ...
            cosd(theta * i), (0.5 + R) * sind(theta * i), 0, i + 8);
    end