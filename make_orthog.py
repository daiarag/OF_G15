import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Arc
import argparse
#from testing import generate_blockMeshDict_template
from makedict import generate_blockMeshDict_template


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





if __name__ == "__main__":
    graph, write = pull()

    num_valves = 1
    theta = np.pi/4
    valve_len = 3 #inner length
    diameter = 1
    end_len = 4
    density = 20

    r = valve_len * np.sin(theta) / (1 + np.sin(theta))
    t1 = 3*(np.pi/2 + theta)/4
    t2 = (np.pi/2 + theta)/2
    t3 = (np.pi/2 + theta)/4
    points_2d = np.array([
        [0, 0], #0
        [-valve_len, 0], #1
        [-valve_len - diameter, 0], #2
        [-valve_len - diameter - end_len, 0], #3
        [-valve_len - diameter - end_len, -diameter], #4
        [-valve_len - diameter, -diameter], #5
        [-valve_len, -diameter], #6
        [diameter/np.tan(theta), -diameter], #7
        [diameter/np.sin(theta), 0], #8
        [diameter/np.tan(theta) + diameter/np.sin(theta), -diameter], #9
        [diameter/np.tan(theta) + diameter/np.sin(theta) + end_len*np.cos(theta), -diameter - end_len*np.sin(theta)], #10
        [diameter/np.tan(theta) + end_len*np.cos(theta), -diameter - end_len*np.sin(theta)], #11
        [-valve_len + r + r*np.sin(theta), r*np.cos(theta)], #12
        [-valve_len + r + (r+diameter)*np.sin(theta), (r+diameter)*np.cos(theta)], #13
        [-valve_len + r - r*np.cos(t1), r*np.sin(t1)], #14
        [-valve_len + r - (r + diameter)*np.cos(t1), (r + diameter)*np.sin(t1)], #15
        [-valve_len + r - r*np.cos(t2), r*np.sin(t2)], #16
        [-valve_len + r - (r + diameter)*np.cos(t2), (r + diameter)*np.sin(t2)], #17
        [-valve_len + r - r*np.cos(t3), r*np.sin(t3)], #18
        [-valve_len + r - (r + diameter)*np.cos(t3), (r + diameter)*np.sin(t3)], #19
    ])

    # Define edges as pairs of indices into points
    edges_2d = np.array([
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],
        [4, 5],
        [5, 6],
        [2, 5],
        [1, 6],
        [0, 8],
        [6, 7],
        [0, 7],
        [8, 9],
        [7, 9],
        [7, 11],
        [10, 11],
        [10, 9],
        [0, 12],
        [8, 13],
        [12, 13],
        [17, 16],
    ])
    #arcs are [start, mid, end]
    arcs_2d = np.array([
        [1, 18, 16],
        [2, 19, 17],
        [16, 14, 12],
        [17, 15, 13],
    ])

# this is very hacky, fix later
    arcs_3d = np.array([
        [1, 16, 18],
        [2, 17, 19],
        [16, 12, 14],
        [17, 13, 15],
    ])


#coutnerclockwise from positive z
# start at bottom leftmost corner
    blocks_2d = np.array([
        [4, 5, 2, 3],
        [5, 6, 1, 2],
        [6, 7, 0, 1],
        [7, 9, 8, 0],
        [11, 10, 9, 7],
        [0, 8, 13, 12],
        [2, 1, 16, 17],
        [17, 16, 12, 13],
    ])
    #segments per unit length
    block_res = []
    for block in blocks_2d:
        block_res.append([density, density, 1])
    block_res = np.array(block_res)

    #diam_res = int(round(density*diameter))

    """
    dmax = density
    block_res = []
    for block in blocks_2d:
        x_len = (np.abs(points_2d[block[0]][0] - points_2d[block[1]][0]) + np.abs(points_2d[block[2]][0] - points_2d[block[3]][0]))/2
        y_len = (np.abs(points_2d[block[0]][1] - points_2d[block[3]][1]) + np.abs(points_2d[block[1]][1] - points_2d[block[2]][1]))/2
        xn = int(np.round(density*x_len))
        yn = int(np.round(density*x_len))
        dmax = np.min([dmax, x_len / xn, y_len / yn])
        block_res.append([xn, yn, 1])
    block_res = np.array(block_res)
    print(f"Min dx is: {dmax}")
    
    #print max density after rounding for courant num
    """
    inlet_2d = np.array([4, 3])

    outlet_2d = np.array([10, 11])

    pipes_2d = np.array([
        [4, 5],
        [5, 6],
        [6, 7],
        [7, 11],
        [10, 9],
        [9, 8],
        [8, 13],
        [13, 17],
        [17, 2],
        [2, 3],
        [1, 0],
        [0, 12],
        [12, 16],
        [16, 1],
    ])

    
#PATCH MUST BE FLIPPED FOR OPPOSITE SIDE

    if graph:
        fig, ax = plt.subplots()

        for start, end in edges_2d:
            xs, ys = zip(points_2d[start], points_2d[end])
            plt.plot(xs, ys, 'b-o')

        for start, mid, end in arcs_2d:
            arc = arc_from_points(points_2d[start], points_2d[mid], points_2d[end])
            ax.add_patch(arc)
            #print(f"{start}, {mid}, {end}")


        for i, (x, y) in enumerate(points_2d):
            plt.text(x, y + 0.05, str(i), ha='center', fontsize=10)

        plt.axis('equal')
        plt.title("Single Tesla Valve Loop (Graph Approximation)")
        plt.grid(True)
        plt.show()

    if write:
        z_value = 0.05
        vertices = np.concatenate([np.hstack((points_2d, np.full((points_2d.shape[0], 1), z_value))),  np.hstack((points_2d, np.full((points_2d.shape[0], 1), -z_value)))])
        num_2d = len(points_2d)
        inlet_3d = np.concatenate([inlet_2d, inlet_2d[::-1] + num_2d])
        outlet_3d = np.concatenate([outlet_2d, outlet_2d[::-1] + num_2d])
        #pipes_3d = np.concatenate([np.hstack((pipes_2d[:, ::-1], pipes_2d + num_2d)), blocks_2d, blocks_2d[:, ::-1] + num_2d])
        pipes_3d = np.hstack((pipes_2d[:, ::-1], pipes_2d + num_2d))
        pipes_3d = np.vstack((pipes_3d[:-6], pipes_3d[-6:, ::-1]))
        blocks_3d = np.hstack((blocks_2d + num_2d, blocks_2d))
        arcs_3d = np.concatenate([arcs_3d, arcs_3d + num_2d])


        generate_blockMeshDict_template(vertices = vertices, blocks = blocks_3d, edges = arcs_3d, block_res = block_res, inlet_face = inlet_3d, outlet_face = outlet_3d, pipe_faces = pipes_3d)

        # REFORMAT EDGES ORDERING
        # func takes [start, end, mid]
