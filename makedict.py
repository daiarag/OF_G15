import numpy as np

def generate_blockMeshDict_template(vertices: np.ndarray, blocks: np.ndarray, block_res: np.ndarray, 
                                     edges: np.ndarray = None, inlet_face: np.ndarray = None, 
                                     outlet_face: np.ndarray = None, pipe_faces: np.ndarray = None, 
                                     output_path="blockMeshDict"):
    """
    Create a blockMeshDict file with given vertices, blocks, block resolutions, edges, and boundaries.
    
    vertices: np.ndarray of shape (n_vertices, 3)
    blocks: np.ndarray of shape (n_blocks, 8) - vertex indices
    block_res: np.ndarray of shape (n_blocks, 3) - (nx, ny, nz) for each block
    edges: np.ndarray of shape (n_edges, 3) - (start_idx, end_idx, intermediate_point_idx) [optional]
    inlet_face: np.ndarray of shape (n_vertices_per_face) - single inlet face vertices
    outlet_face: np.ndarray of shape (n_vertices_per_face) - single outlet face vertices
    pipe_faces: np.ndarray of shape (n_pipe_faces, n_vertices_per_face) - faces for pipe boundary (wall)
    output_path: path to write the blockMeshDict
    """
    
    header = """/*--------------------------------*- C++ -*----------------------------------*\\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  vX.X (fill in version if needed)       |
|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |
|    \\/     M anipulation  |                                                 |
\\*---------------------------------------------------------------------------*/

FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      blockMeshDict;
}

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

convertToMeters 1.0;

vertices
(
"""
    
    # Build vertices section
    vertices_section = ""
    for idx, v in enumerate(vertices):
        vertices_section += f"    ({v[0]} {v[1]} {v[2]}) // vertex {idx}\n"
    vertices_section += ");\n\n"

    # Build blocks section
    blocks_section = "blocks\n(\n"
    for idx, (b, res) in enumerate(zip(blocks, block_res)):
        nx, ny, nz = res
        blocks_section += f"    hex ({' '.join(map(str, b))}) ({nx} {ny} {nz}) simpleGrading (1 1 1) // block {idx}\n"
    blocks_section += ");\n\n"

    # Build edges section (optional)
    edges_section = ""
    if edges is not None and len(edges) > 0:
        edges_section += "edges\n(\n"
        for idx, edge in enumerate(edges):
            start_idx, end_idx, mid_idx = edge
            mid_point = vertices[mid_idx]
            edges_section += f"    arc {start_idx} {end_idx} ({mid_point[0]} {mid_point[1]} {mid_point[2]}) // edge {idx}\n"
        edges_section += ");\n\n"

    # Build boundary section
    boundary_section = "boundary\n(\n"
    
    if inlet_face is not None:
        boundary_section += f"    inlet\n    {{\n        type patch;\n        faces\n        (\n"
        boundary_section += f"            ({' '.join(map(str, inlet_face))})\n"
        boundary_section += "        );\n    }\n"
    
    if outlet_face is not None:
        boundary_section += f"    outlet\n    {{\n        type patch;\n        faces\n        (\n"
        boundary_section += f"            ({' '.join(map(str, outlet_face))})\n"
        boundary_section += "        );\n    }\n"
    
    # Group all pipe faces under a single "pipe" wall boundary
    if pipe_faces is not None and len(pipe_faces) > 0:
        boundary_section += "    pipe\n    {\n        type wall;\n        faces\n        (\n"
        for face in pipe_faces:
            boundary_section += f"            ({' '.join(map(str, face))})\n"
        boundary_section += "        );\n    }\n"

    boundary_section += ");\n\n"

    # Write to file
    with open(output_path, "w") as f:
        f.write(header)
        f.write(vertices_section)
        f.write(blocks_section)
        if edges_section:
            f.write(edges_section)
        f.write(boundary_section)

    print(f"blockMeshDict written to '{output_path}' with {len(vertices)} vertices, {len(blocks)} blocks, {len(edges) if edges is not None else 0} edges.")