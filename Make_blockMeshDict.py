import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Arc
import argparse

def pull():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--graph",
        action="store_true",
        help="if used display graph"
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="if used write blockmeshdict"
    )
    args = parser.parse_args()
    graph = args.graph
    write = args.write
    return graph, write


def arc_from_points(p1, p2, p3):
    p1, p2, p3 = map(np.array, (p1, p2, p3))

    # Midpoints of segments
    mid_ab = (p1 + p2) / 2
    mid_bc = (p2 + p3) / 2

    # Perpendicular directions
    dir_ab = p2 - p1
    dir_bc = p3 - p2
    perp_ab = np.array([-dir_ab[1], dir_ab[0]])
    perp_bc = np.array([-dir_bc[1], dir_bc[0]])

    # Solve for intersection (circumcenter)
    def intersect(p1, d1, p2, d2):
        A = np.stack([d1, -d2], axis=1)
        b = p2 - p1
        t = np.linalg.lstsq(A, b, rcond=None)[0]
        return p1 + t[0] * d1

    center = intersect(mid_ab, perp_ab, mid_bc, perp_bc)
    radius = np.linalg.norm(p1 - center)

    def angle(v):
        return np.degrees(np.arctan2(v[1], v[0]))

    start_angle = angle(p1 - center)
    mid_angle = angle(p2 - center)
    end_angle = angle(p3 - center)

    # Determine if arc goes counter-clockwise or clockwise
    def angle_diff(a1, a2):
        return (a2 - a1 + 360) % 360

    if angle_diff(start_angle, mid_angle) < angle_diff(start_angle, end_angle):
        theta1, theta2 = start_angle, end_angle
    else:
        theta1, theta2 = end_angle, start_angle

    # Build matplotlib Arc patch
    arc = Arc(center, 2 * radius, 2 * radius, angle=0, theta1=theta1, theta2=theta2)
    return arc

def write_blockMeshDict(points, edges=None, arcs=None,
                        blocks_def=None, boundary_def=None,
                        filename="blockMeshDict",
                        convertToMeters=1.0):
    """
    Write an OpenFOAM blockMeshDict with given vertices, edges & arcs.
    
    blocks_def: a string containing your 'blocks ( ... );' section
    boundary_def: a string containing your 'boundary ( ... );' section
    """
    header = f"""/*--------------------------------*- C++ -*----------------------------------*\\
| =========                 |                                                 |
| \\      /  F ield           | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration       | Version:  8                                     |
|   \\/     A nd              | www.openfoam.org                                |
\\*---------------------------------------------------------------------------*/
    
convertToMeters  {convertToMeters};

"""
    with open(filename, "w") as f:
        # Header + vertices
        f.write(header)
        f.write("vertices\n(\n")
        for p in points:
            f.write(f"    ({p[0]:.6g} {p[1]:.6g} {p[2]:.6g})\n")
        f.write(");\n\n")
        
        # Blocks (user must supply topology)
        if blocks_def is not None:
            f.write(blocks_def.strip() + "\n\n")
        else:
            f.write("// TODO: define your blocks here\n\n")
        
        # Edges / Arcs
        if (edges is not None and len(edges)) or (arcs is not None and len(arcs)):
            f.write("edges\n(\n")
            # straight edges (optional; blockMesh treats undefined as straight)
            if edges is not None:
                for e in edges:
                    f.write(f"    // straight edge between {e[0]} and {e[1]} (implicit)\n")
                    # you could write a spline with zero interior points, but this is optional
            # arcs
            if arcs is not None:
                for a in arcs:
                    i, mid, j = a
                    xm, ym, zm = points[mid]
                    f.write(f"    arc {i} {j} ({xm:.6g} {ym:.6g} {zm:.6g});\n")
            f.write(");\n\n")
        
        # Boundary
        if boundary_def is not None:
            f.write(boundary_def.strip() + "\n\n")
        else:
            f.write("// TODO: define your boundary patches here\n\n")
        
        # mergePatchPairs
        f.write("mergePatchPairs\n(\n);\n")

    print(f"Written blockMeshDict to '{filename}'")



if __name__ == "__main__":
    graph, write = pull()
    # Example placeholders for blocks/boundaries:
    blocks_section = """
blocks
(
    // a single hexahedral block using the 8 points
    hex (0 1 2 3 4 5 6 7) (10 10 10) simpleGrading (1 1 1)
);
"""
    boundary_section = """
boundary
(
    inlet
    {
        type patch;
        faces
        (
            (0 4 7 3)
        );
    }
    outlet
    {
        type patch;
        faces
        (
            (1 2 6 5)
        );
    }
);
"""
    # Generate
    


    points = np.array([
        [0, 0], #0
        [10, 0], #1
        [10, 10], #2
        [0, 10], #3
        [0, 4], #4
        [0, 5], #5
        [10, 1], #6
        [6, 4], #7
        [3, 5], #8
        [4, 7], #9
        [2, 5], #10
        [5, 5], #11
        [4, 6], #12
        [3, 6], #13
        [2.5, 6.5], #14
    ])

    # Define edges as pairs of indices into points
    edges = np.array([
        [0, 1], 
        [2, 6],
        [1, 7],
        [7, 4],
        [2, 3],
        [3, 5],
        [6, 9],
        [8, 11],
        [5, 10],
        [4, 0],
        [11, 12],
    ])

    arcs = np.array([
        [8, 13, 12],
        [10, 14, 9],
    ])


    # Optionally, plot the graph for visualization
    #plt.figure(figsize=(6, 4))
    fig, ax = plt.subplots()

    for start, end in edges:
        xs, ys = zip(points[start], points[end])
        plt.plot(xs, ys, 'b-o')

    for start, mid, end in arcs:
        arc = arc_from_points(points[start], points[mid], points[end])
        ax.add_patch(arc)
        #print(f"{start}, {mid}, {end}")


    for i, (x, y) in enumerate(points):
        plt.text(x, y + 0.05, str(i), ha='center', fontsize=10)

    plt.axis('equal')
    plt.title("Single Tesla Valve Loop (Graph Approximation)")
    plt.grid(True)
    if graph:
        plt.show()
    if write:
        write_blockMeshDict(points, edges, arcs,
                        blocks_def=blocks_section,
                        boundary_def=boundary_section)
