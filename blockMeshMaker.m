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
function [] = blockMeshMaker(param)
    arguments
        param.nAngles double {mustBeInteger, mustBeFinite, mustBeScalarOrEmpty,...
            mustBeGreaterThan(param.nAngles, 7)} = 8;
        param.radialExpansion (1, 2) double {mustBeRow, mustBeFinite,...
            mustBePositive} = [2 1];
        param.rectExpansion (1, 2) double {mustBeRow, mustBeFinite, ...
            mustBePositive} = [4 1];
        param.Lf double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 4;
        param.Lw double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 6;
        param.R double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 1;
        param.H double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 5;
    end
    fid = fopen("blockMeshDict", "w+"); % Create new file to write to
    % Constant lines of every blockMeshDict
    fprintf(fid, "FoamFile\n{\n\tversion:\t2.0;\n\tformat\tascii;\n"...
        +"\tclass\tdictionary;\n\tobject:\tblockMeshDict;\n}\n\n");
    fprintf(fid, "convertToMeters:\t1.0;\n\n");
    fprinf(fid, "vertices\n(\n");
    % Vertex determination - cylinder first
    theta = 360 / param.nAngles; % angle increment
    total = 0; % For labeling vertices
    k = 0; % For total counter
    % First front, then back
    for n = 0:1
        % Wall vertices
        for i = 0:param.nAngles - 1
            fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", 0.5 * ...
                cosd(theta * i), 0.5 * sind(theta * i), n, i + total);
        end
        k = i + 1; % For total counter
        % Outer radius vertices
        for i = 0:param.nAngles - 1
            fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", (0.5 + ...
                param.R) * cosd(theta * i), (0.5 + param.R) * sind(theta...
                * i), n, i + k + total);
        end
        k = k + i + 1; % For total counter
        % Top-back domain vertices
        i = 0; % Checking when to terminate
        while (cosd(i * theta) > 0)
            fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", Lw, ...
                (0.5 + param.R) * sind(theta * i), n, i + k + total);
            i = i + 1;
        end
        fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", param.Lw, ...
            param.H, n, i + k + total); % Top-right corner
        k = k + i; % For total counter
        % Top domain vertices
        if (mod(param.nAngles, 4) == 0)
            for j = 1:-1
                fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", (0.5 +...
                    param.R) * cosd(90 - theta * j), param.H, n, k + 1 -...
                    j + total);
            end
            k = k + 3;
        else
            fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", (0.5 + ...
                param.R) * cosd(theta * i - 1), param.H, n, k + total);
            fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", (0.5 + ...
                param.R) * cosd(theta * i), param.H, n, k + total + 1);
            k = k + 2;
        end
        % Front domain vertices
        fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", param.Lf, ...
            param.H, n, k + total); % Top-left corner
        k = k + 1; % For total counter
        j = 0; % For labeling front wall
        while (cosd(i * theta) < 0)
            fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", param.Lw, ...
            (0.5 + param.R) * sind(theta * i), n, j + k + total);
            j = j + 1;
            i = i + 1;
        end
        fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", param.Lw, ...
            -param.H, n, k + j + 1 + total); % Bottom-left corner
        k = k + j + 2; % For total counter
        % Bottom domain vertices
        if (mod(param.nAngles, 4) == 0)
            for j = 1:-1
                fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", (0.5 +...
                    param.R) * cosd(270 - theta * j), -param.H, n, k + 1 -...
                    j + total);
            end
            k = k + 3;
        else
            fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", (0.5 + ...
                param.R) * cosd(theta * i - 1), -param.H, n, k + total);
            fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", (0.5 + ...
                param.R) * cosd(theta * i), -param.H, n, k + total + 1);
            k = k + 2;
        end
        fprintf(fid, "\t(%1.8f %2.8f %3.2f) \\\\%4.1f\n", param.Lw, ...
            -param.H, n, k + total); % Bottom-right corner
        k = k + 1; % For total counter
    end