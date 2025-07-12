enum Direction { down, left, up, right }

const List<(int, int)> planeAround = [(-1, 0), (1, 0), (0, -1), (0, 1)];

const List<(int, int)> planeConnection = [(1, 0), (0, 1), (1, 1), (-1, 1)];
