% This function will accept the following input variables:
% nAngles = number of angular partitions. There will always be a
% vertical "pie slice" but the number of horizontal slices vary (default
% value is 8)
% radialExpansion = vector for expansion ratios [radial angular] (z = 1)
% (default is [2 1])
% rCellCount = vector for number of cells in each direction [radial
% angular] (z = 1) (default is [10 20])
% Lf = fore distance (measured in cylinder diameters) (default is 4)
% Lw = wake distance (measured in cylinder diameters) (default is 6)
% R = radial size (measured in cylinder diameters) (default is 1)
% H = half-domain height (measured in cylinder diameters) (default is 5)
% rectExpansion = vector for expansion ratios [horz vert] (z = 1) (default
% is [4 4])
% boxCellCount = vector for number of cells fore and aft [fore aft] (z = 1)
% (default is [15 30])
% The function will save a file to MATLAB directory (where this function
% rests) and display the following:
% Number of vertices
% Number of radial blocks
% Number of rectangular blocks
% Number of inlet faces
% Number of outlet faces
% Number of cylinder faces
% Number of top faces
% Number of bottom faces
function [] = blockMeshMaker(param)
    arguments
        param.nAngles double {mustBeInteger, mustBeFinite, mustBeScalarOrEmpty,...
            mustBeGreaterThan(param.nAngles, 7)} = 8;
        param.radialExpansion (1, 2) double {mustBeRow, mustBeFinite,...
            mustBePositive} = [2 1];
        param.rCellCount (1, 2) double {mustBeRow, mustBeFinite,...
            mustBePositive, mustBeInteger} = [10 20];
        param.rectExpansion (1, 2) double {mustBeRow, mustBeFinite, ...
            mustBePositive} = [4 4];
        param.Lf double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 4;
        param.Lw double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 6;
        param.R double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 1;
        param.H double {mustBeReal, mustBeFinite, mustBeScalarOrEmpty,...
            mustBePositive} = 5;
        param.boxCellCount (1, 2) double {mustBeRow, mustBeFinite,...
            mustBePositive, mustBeInteger} = [15 30];
    end
    % Prevent buggy meshes
    try
        assert(param.Lf > param.R + 0.5);
        assert(param.Lw > param.R + 0.5);
        assert(param.H > param.R + 0.5);
    catch
        myExc = MException('MATLAB:blockMeshMaker:boundary', ...
            "Parameters Lf, Lw, and H must be larger than outer shell.");
        throw(myExc);
    end
    fid = fopen("blockMeshDict", "w+"); % Create new file to write to
    % Vertex determination - cylinder first
    theta = 360 / param.nAngles; % angle increment
    vertices = zeros(16 + 6 * param.nAngles, 3); % Matrix to hold vertices
    arcCenters = zeros(2 * param.nAngles, 3); % Matrix to hold arc midpoints
    zCounter = length(vertices) / 2;
    k = 1; % For indexing
    % Circular vertices
    for i = 0:param.nAngles - 1
        % Cylinder
        vertices(i + 1, :) = [0.5 * cosd(theta * i) ...
            0.5 * sind(theta * i) -0.5];
        arcCenters(i + 1, :) = [0.5 * cosd(theta * (i + 0.5)) ...
            0.5 * sind(theta * (i + 0.5)) -0.5];
        % Outer ring
        vertices(i + param.nAngles + 1, :) = [(0.5 + ...
            param.R) * cosd(theta * i) (0.5 + param.R) * sind(theta...
            * i) -0.5];
        arcCenters(i + param.nAngles + 1, :) = [0.5 * cosd(theta * (i + 0.5)) ...
            0.5 * sind(theta * (i + 0.5)) -0.5];
    end
    k = k + 2 * (i + 1);
    % Top-back domain vertices
    i = 0;
    % Checking when to terminate
    while (cosd(i * theta) > 0)
        vertices(i + k, :) = [param.Lw (0.5 + param.R)...
            * sind(theta * i) -0.5];
        i = i + 1;
    end
    % Top-right corner
    vertices(i + k, :) = [param.Lw param.H -0.5];
    k = k + i + 1;
    % Top domain vertices
    if (mod(param.nAngles, 4) == 0)
        for j = 1:-1:-1
            vertices(k + 1 - j, :) = [(0.5 + param.R)...
                * cosd(90 - theta * j) param.H -0.5];
        end
        k = k + 3;
        i = i + 1;
    else
        vertices(k, :) = [(0.5 + param.R) * cosd(theta...
            * (i - 1)) param.H -0.5];
        vertices(k + 1, :) = [(0.5 + param.R) * ...
            cosd(theta * i) param.H -0.5];
        k = k + 2;
    end
    % Front domain vertices
    % Top-left corner
    vertices(k, :) = [-param.Lf param.H -0.5];
    k = k + 1;
    j = 0;
    while (cosd(i * theta) < 0)
        vertices(j + k, :) = [-param.Lf (0.5 + param.R)...
            * sind(theta * i) -0.5];
        j = j + 1;
        i = i + 1;
    end
    % Bottom-left corner
    vertices(j + k, :) = [-param.Lf -param.H -0.5];
    k = k + j + 1;
    % Bottom domain vertices
    if (mod(param.nAngles, 4) == 0)
        for j = 1:-1:-1
            vertices(k + 1 - j, :) = [(0.5 + param.R)...
                * cosd(270 - theta * j) -param.H -0.5];
        end
        k = k + 3;
        i = i + 1;
    else
        vertices(k, :) = [(0.5 + param.R) * cosd(theta...
            * (i - 1)) -param.H -0.5];
        vertices(k + 1, :) = [(0.5 + param.R) * ...
            cosd(theta * i) -param.H -0.5];
        k = k + 2;
    end
    % Bottom-right corner
    vertices(k, :) = [param.Lw -param.H -0.5];
    k = k + 1;
    j = 0;
    % Bottom-back domain vertices
    while (theta * i < 360)
        vertices(k + j, :) = [param.Lw (0.5 + param.R)...
            * sind(theta * i) -0.5];
        i = i + 1;
        j = j + 1;
    end
    vertices(zCounter + 1:end, :) = [vertices(1:zCounter, 1:2) ...
        0.5 * ones(zCounter, 1)]; % Duplicate for out-of-plane points
    % Uncomment this line to plot points
    % plot(vertices(1:zCounter, 1), vertices(1:zCounter, 2), 'o');
    % Constant lines of every blockMeshDict
    fprintf(fid, "FoamFile\n{\n\tversion:\t2.0;\n\tformat:\tascii;\n"...
        +"\tclass:\tdictionary;\n\tobject:\tblockMeshDict;\n}\n\n");
    fprintf(fid, "convertToMeters:\t1.0;\n\n");
    % Print vertices from list
    fprintf(fid, "vertices\n(\n");
    fprintf(fid, "\t(%.10f %.10f %.10f) \\\\ %.0f\n", [vertices'; ...
        0:15 + 6 * param.nAngles]);
    fprintf(fid, ");\n\n");
    % Print blocks
    fprintf(fid, "blocks\n(\n");
    % Circular ring
    for i = 0:param.nAngles - 2
        fprintf(fid, "\t\\\\ block %.0f\n", i);
        fprintf(fid, "\thex (%.0f %.0f %.0f %.0f %.0f %.0f %.0f"...
            + " %.0f) (%.0f %.0f 1) simpleGrading (%.10f %.10f"... 
            + " 1)\n", i, i + param.nAngles, i + param.nAngles + 1, i + 1,...
            i + zCounter, i + zCounter + param.nAngles, i + zCounter...
            + param.nAngles + 1, i + zCounter + 1, param.rCellCount(1),...
            param.rCellCount(2), param.radialExpansion(1), ...
            param.radialExpansion(2));
    end
    % Last block in circular ring
    fprintf(fid, "\t\\\\ block %.0f\n", param.nAngles - 1);
    fprintf(fid, "\thex (%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f) (%.0f"...
        + " %.0f 1) simpleGrading (%.10f %.10f 1)\n", param.nAngles - 1,...
        2 * param.nAngles - 1, param.nAngles, 0, param.nAngles + zCounter...
        - 1, 2 * param.nAngles + zCounter - 1, param.nAngles + zCounter,...
        zCounter, param.rCellCount(1), param.rCellCount(2),...
        param.radialExpansion(1), param.radialExpansion(2));
    % Remaining blocks
    % We start with blocks from x-axis to first square block
    % Find the top-right corner
    stop = find(vertices(:, 2) < param.H, 1, "last") - 1;
    % Ascend from x-axis
    for i = 2 * param.nAngles:stop - 2
        fprintf(fid, "\t\\\\ block %.0f\n", i - param.nAngles);
        fprintf(fid, "\thex (%.0f %.0f %.0f %.0f %.0f %.0f %.0f"...
            + " %.0f) (%.0f %.0f 1) simpleGrading (%.10f %.10f"... 
            + " 1)\n", i - param.nAngles, i, i + 1, i - param.nAngles + 1,...
            i - param.nAngles + zCounter, i + zCounter, i + 1 + zCounter...
            , i + zCounter + 1 - param.nAngles, param.boxCellCount(2),...
            param.rCellCount(2), param.rectExpansion(1), ...
            param.radialExpansion(2));
    end
    % Top-right block
    fprintf(fid, "\t\\\\ block %.0f\n", stop - param.nAngles - 1);
    fprintf(fid, "\thex (%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f) (%.0f"...
        + " %.0f 1) simpleGrading (%.10f %.10f 1)\n", stop - param.nAngles...
        - 1, stop - 1, stop, stop + 1, stop - param.nAngles + zCounter - 1,...
        stop + zCounter - 1, stop + zCounter, stop + zCounter,...
        param.boxCellCount(2), param.boxCellCount(2), ...
        param.rectExpansion(1), param.rectExpansion(2));
    % Now we move to the left edge of the domain
    % Find the top-left corner
    stop = find(vertices(:, 1) > -param.Lf, 1, "last") - 1;
    % Go left from top-right block
    for i = 1:2

    end
    fprintf(fid, ");\n\n");
    fclose(fid); % Close file
    disp("Number of vertices:");
    disp(length(vertices));
    disp("Number of radial blocks:");
    disp(param.nAngles);