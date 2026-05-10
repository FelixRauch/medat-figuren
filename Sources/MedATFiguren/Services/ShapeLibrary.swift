import Foundation

/// A curated library of puzzle shapes with validated decompositions.
/// All coordinates are in normalized [0.0, 1.0] × [0.0, 1.0] space.
public final class ShapeLibrary {

    public static let shared = ShapeLibrary()
    private init() {}

    /// All shapes, loaded lazily.
    public lazy var allShapes: [PuzzleShape] = buildLibrary()

    /// Shapes that have a decomposition for the given piece count.
    public func shapes(forPieceCount count: Int) -> [PuzzleShape] {
        allShapes.filter { $0.availablePieceCounts.contains(count) }
    }

    /// A random shape suitable for the given difficulty.
    /// Falls back to the first shape if no exact match exists.
    public func randomShape(for difficulty: DifficultyLevel) -> PuzzleShape {
        let candidates = shapes(forPieceCount: difficulty.pieceCount)
        if let pick = candidates.randomElement() { return pick }
        // Fallback: find nearest piece count
        let nearest = allShapes
            .flatMap { s in s.availablePieceCounts.map { ($0, s) } }
            .min { abs($0.0 - difficulty.pieceCount) < abs($1.0 - difficulty.pieceCount) }
        return nearest?.1 ?? allShapes[0]
    }

    // MARK: - Library construction

    private func buildLibrary() -> [PuzzleShape] {
        [
            sphere(),
            trapezoid(),
            regularQuadrilateral(),
            regularPentagon(),
            regularHexagon(),
            square(),
            rightTriangle(),
            rectangle(),
            lShape(),
            tShape(),
            parallelogram(),
            pentagon(),
            hexagon(),
            arrowShape(),
            irregularQuad(),
        ]
    }

    // MARK: - Shape definitions

    // MARK: Sphere (smooth 24-gon approximation; rendered as a circle)
    private func sphere() -> PuzzleShape {
        let n = 24
        let cx = 0.5, cy = 0.5, r = 0.42
        func pt(_ i: Int) -> NormalizedPoint {
            let angle = 2 * Double.pi * Double(i) / Double(n) - Double.pi / 2
            return NormalizedPoint(cx + r * cos(angle), cy + r * sin(angle))
        }
        let outline = (0..<n).map { pt($0) }

        // 2-piece: left and right halves through vertical diameter
        let topCenter = NormalizedPoint(cx, cy - r)
        let botCenter = NormalizedPoint(cx, cy + r)
        let leftHalf: [NormalizedPoint]  = [topCenter] + (n/2...n).map { pt($0 % n) }
        let rightHalf: [NormalizedPoint] = [topCenter] + (0...n/2).map { pt($0) } + [botCenter]

        // 4-piece: pie quarters
        let qSize = n / 4
        let fourPieces: [ShapePiece] = (0..<4).map { q in
            let verts: [NormalizedPoint] = [NormalizedPoint(cx, cy)] + (0...qSize).map { pt((q * qSize + $0) % n) }
            return ShapePiece(id: "sph-4-\(q)", vertices: verts)
        }

        // 6-piece: pie sixths
        let sSize = n / 6
        let sixPieces: [ShapePiece] = (0..<6).map { s in
            let verts: [NormalizedPoint] = [NormalizedPoint(cx, cy)] + (0...sSize).map { pt((s * sSize + $0) % n) }
            return ShapePiece(id: "sph-6-\(s)", vertices: verts)
        }

        return PuzzleShape(
            id: "sphere", name: "Sphere",
            outline: outline,
            decompositions: [
                2: [
                    ShapePiece(id: "sph-2-a", vertices: leftHalf),
                    ShapePiece(id: "sph-2-b", vertices: rightHalf),
                ],
                4: fourPieces,
                6: sixPieces,
            ],
            isCircle: true
        )
    }

    // MARK: Trapezoid
    private func trapezoid() -> PuzzleShape {
        let outline: [NormalizedPoint] = [
            NormalizedPoint(0.3, 0.2), NormalizedPoint(0.7, 0.2),
            NormalizedPoint(0.9, 0.8), NormalizedPoint(0.1, 0.8),
        ]
        return PuzzleShape(
            id: "trapezoid", name: "Trapezoid",
            outline: outline,
            decompositions: [
                2: [
                    ShapePiece(id: "trap-2-a",
                               vertices: [NormalizedPoint(0.3,0.2), NormalizedPoint(0.7,0.2), NormalizedPoint(0.5,0.8), NormalizedPoint(0.1,0.8)]),
                    ShapePiece(id: "trap-2-b",
                               vertices: [NormalizedPoint(0.7,0.2), NormalizedPoint(0.9,0.8), NormalizedPoint(0.5,0.8)]),
                ],
                3: [
                    ShapePiece(id: "trap-3-a",
                               vertices: [NormalizedPoint(0.1,0.8), NormalizedPoint(0.3,0.2), NormalizedPoint(0.5,0.5)]),
                    ShapePiece(id: "trap-3-b",
                               vertices: [NormalizedPoint(0.3,0.2), NormalizedPoint(0.7,0.2), NormalizedPoint(0.5,0.5)]),
                    ShapePiece(id: "trap-3-c",
                               vertices: [NormalizedPoint(0.7,0.2), NormalizedPoint(0.9,0.8), NormalizedPoint(0.5,0.5), NormalizedPoint(0.1,0.8)]),
                ],
                4: [
                    ShapePiece(id: "trap-4-a",
                               vertices: [NormalizedPoint(0.1,0.8), NormalizedPoint(0.3,0.2), NormalizedPoint(0.5,0.2), NormalizedPoint(0.35,0.8)]),
                    ShapePiece(id: "trap-4-b",
                               vertices: [NormalizedPoint(0.35,0.8), NormalizedPoint(0.5,0.2), NormalizedPoint(0.5,0.8)]),
                    ShapePiece(id: "trap-4-c",
                               vertices: [NormalizedPoint(0.5,0.8), NormalizedPoint(0.5,0.2), NormalizedPoint(0.7,0.2), NormalizedPoint(0.65,0.8)]),
                    ShapePiece(id: "trap-4-d",
                               vertices: [NormalizedPoint(0.65,0.8), NormalizedPoint(0.7,0.2), NormalizedPoint(0.9,0.8)]),
                ],
            ]
        )
    }

    // MARK: Regular 4-sided polygon (rhombus / diamond)
    private func regularQuadrilateral() -> PuzzleShape {
        // A regular quadrilateral rotated 45° → diamond shape
        let outline: [NormalizedPoint] = [
            NormalizedPoint(0.5, 0.1),
            NormalizedPoint(0.9, 0.5),
            NormalizedPoint(0.5, 0.9),
            NormalizedPoint(0.1, 0.5),
        ]
        return PuzzleShape(
            id: "rhombus", name: "Rhombus (4 sides)",
            outline: outline,
            decompositions: [
                2: [
                    ShapePiece(id: "rhom-2-a",
                               vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.5), NormalizedPoint(0.5,0.9)]),
                    ShapePiece(id: "rhom-2-b",
                               vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.5,0.9), NormalizedPoint(0.1,0.5)]),
                ],
                4: [
                    ShapePiece(id: "rhom-4-a",
                               vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.5)]),
                    ShapePiece(id: "rhom-4-b",
                               vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.9,0.5), NormalizedPoint(0.5,0.9)]),
                    ShapePiece(id: "rhom-4-c",
                               vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.5,0.9), NormalizedPoint(0.1,0.5)]),
                    ShapePiece(id: "rhom-4-d",
                               vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.1,0.5), NormalizedPoint(0.5,0.1)]),
                ],
            ]
        )
    }

    // MARK: Regular pentagon (5 sides)
    private func regularPentagon() -> PuzzleShape {
        let n = 5
        let cx = 0.5, cy = 0.5, r = 0.42
        func pt(_ i: Int) -> NormalizedPoint {
            let angle = 2 * Double.pi * Double(i) / Double(n) - Double.pi / 2
            return NormalizedPoint(cx + r * cos(angle), cy + r * sin(angle))
        }
        let outline = (0..<n).map { pt($0) }
        let center = NormalizedPoint(cx, cy)
        // 5 triangle pieces from center
        let fivePieces: [ShapePiece] = (0..<5).map { i in
            ShapePiece(id: "rpent-5-\(i)", vertices: [center, pt(i), pt((i+1) % n)])
        }
        return PuzzleShape(
            id: "regular_pentagon", name: "Pentagon (5 sides)",
            outline: outline,
            decompositions: [
                3: [
                    ShapePiece(id: "rpent-3-a", vertices: [center, pt(0), pt(1), pt(2)]),
                    ShapePiece(id: "rpent-3-b", vertices: [center, pt(2), pt(3)]),
                    ShapePiece(id: "rpent-3-c", vertices: [center, pt(3), pt(4), pt(0)]),
                ],
                5: fivePieces,
            ]
        )
    }

    // MARK: Regular hexagon (6 sides)
    private func regularHexagon() -> PuzzleShape {
        let n = 6
        let cx = 0.5, cy = 0.5, r = 0.42
        func pt(_ i: Int) -> NormalizedPoint {
            let angle = 2 * Double.pi * Double(i) / Double(n) - Double.pi / 2
            return NormalizedPoint(cx + r * cos(angle), cy + r * sin(angle))
        }
        let outline = (0..<n).map { pt($0) }
        let center = NormalizedPoint(cx, cy)
        let sixPieces: [ShapePiece] = (0..<6).map { i in
            ShapePiece(id: "rhex-6-\(i)", vertices: [center, pt(i), pt((i+1) % n)])
        }
        return PuzzleShape(
            id: "regular_hexagon", name: "Hexagon (6 sides)",
            outline: outline,
            decompositions: [
                2: [
                    ShapePiece(id: "rhex-2-a", vertices: [center, pt(0), pt(1), pt(2), pt(3)]),
                    ShapePiece(id: "rhex-2-b", vertices: [center, pt(3), pt(4), pt(5), pt(0)]),
                ],
                3: [
                    ShapePiece(id: "rhex-3-a", vertices: [center, pt(0), pt(1), pt(2)]),
                    ShapePiece(id: "rhex-3-b", vertices: [center, pt(2), pt(3), pt(4)]),
                    ShapePiece(id: "rhex-3-c", vertices: [center, pt(4), pt(5), pt(0)]),
                ],
                6: sixPieces,
            ]
        )
    }

    // MARK: Square
    private func square() -> PuzzleShape {
        PuzzleShape(
            id: "square", name: "Square",
            outline: [
                NormalizedPoint(0.1, 0.1), NormalizedPoint(0.9, 0.1),
                NormalizedPoint(0.9, 0.9), NormalizedPoint(0.1, 0.9),
            ],
            decompositions: [
                2: [
                    ShapePiece(id: "sq-2-a",
                               vertices: [NormalizedPoint(0.1, 0.1), NormalizedPoint(0.9, 0.1), NormalizedPoint(0.9, 0.9)]),
                    ShapePiece(id: "sq-2-b",
                               vertices: [NormalizedPoint(0.1, 0.1), NormalizedPoint(0.9, 0.9), NormalizedPoint(0.1, 0.9)]),
                ],
                4: [
                    ShapePiece(id: "sq-4-a",
                               vertices: [NormalizedPoint(0.1,0.1), NormalizedPoint(0.5,0.1), NormalizedPoint(0.5,0.5), NormalizedPoint(0.1,0.5)]),
                    ShapePiece(id: "sq-4-b",
                               vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.1), NormalizedPoint(0.9,0.5), NormalizedPoint(0.5,0.5)]),
                    ShapePiece(id: "sq-4-c",
                               vertices: [NormalizedPoint(0.1,0.5), NormalizedPoint(0.5,0.5), NormalizedPoint(0.5,0.9), NormalizedPoint(0.1,0.9)]),
                    ShapePiece(id: "sq-4-d",
                               vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.9,0.5), NormalizedPoint(0.9,0.9), NormalizedPoint(0.5,0.9)]),
                ],
            ]
        )
    }

    private func rightTriangle() -> PuzzleShape {
        PuzzleShape(
            id: "right_triangle", name: "Right Triangle",
            outline: [
                NormalizedPoint(0.1, 0.9), NormalizedPoint(0.9, 0.9), NormalizedPoint(0.1, 0.1),
            ],
            decompositions: [
                2: [
                    ShapePiece(id: "rt-2-a",
                               vertices: [NormalizedPoint(0.1,0.9), NormalizedPoint(0.5,0.5), NormalizedPoint(0.1,0.1)]),
                    ShapePiece(id: "rt-2-b",
                               vertices: [NormalizedPoint(0.1,0.9), NormalizedPoint(0.9,0.9), NormalizedPoint(0.5,0.5)]),
                ],
                3: [
                    ShapePiece(id: "rt-3-a",
                               vertices: [NormalizedPoint(0.1,0.9), NormalizedPoint(0.5,0.9), NormalizedPoint(0.3,0.5)]),
                    ShapePiece(id: "rt-3-b",
                               vertices: [NormalizedPoint(0.5,0.9), NormalizedPoint(0.9,0.9), NormalizedPoint(0.3,0.5)]),
                    ShapePiece(id: "rt-3-c",
                               vertices: [NormalizedPoint(0.1,0.9), NormalizedPoint(0.3,0.5), NormalizedPoint(0.1,0.1)]),
                ],
            ]
        )
    }

    private func rectangle() -> PuzzleShape {
        PuzzleShape(
            id: "rectangle", name: "Rectangle",
            outline: [
                NormalizedPoint(0.1,0.2), NormalizedPoint(0.9,0.2),
                NormalizedPoint(0.9,0.8), NormalizedPoint(0.1,0.8),
            ],
            decompositions: [
                2: [
                    ShapePiece(id: "rect-2-a",
                               vertices: [NormalizedPoint(0.1,0.2), NormalizedPoint(0.5,0.2), NormalizedPoint(0.5,0.8), NormalizedPoint(0.1,0.8)]),
                    ShapePiece(id: "rect-2-b",
                               vertices: [NormalizedPoint(0.5,0.2), NormalizedPoint(0.9,0.2), NormalizedPoint(0.9,0.8), NormalizedPoint(0.5,0.8)]),
                ],
                3: [
                    ShapePiece(id: "rect-3-a",
                               vertices: [NormalizedPoint(0.1,0.2), NormalizedPoint(0.4,0.2), NormalizedPoint(0.4,0.8), NormalizedPoint(0.1,0.8)]),
                    ShapePiece(id: "rect-3-b",
                               vertices: [NormalizedPoint(0.4,0.2), NormalizedPoint(0.65,0.2), NormalizedPoint(0.65,0.8), NormalizedPoint(0.4,0.8)]),
                    ShapePiece(id: "rect-3-c",
                               vertices: [NormalizedPoint(0.65,0.2), NormalizedPoint(0.9,0.2), NormalizedPoint(0.9,0.8), NormalizedPoint(0.65,0.8)]),
                ],
                4: [
                    ShapePiece(id: "rect-4-a",
                               vertices: [NormalizedPoint(0.1,0.2), NormalizedPoint(0.5,0.2), NormalizedPoint(0.5,0.5), NormalizedPoint(0.1,0.5)]),
                    ShapePiece(id: "rect-4-b",
                               vertices: [NormalizedPoint(0.5,0.2), NormalizedPoint(0.9,0.2), NormalizedPoint(0.9,0.5), NormalizedPoint(0.5,0.5)]),
                    ShapePiece(id: "rect-4-c",
                               vertices: [NormalizedPoint(0.1,0.5), NormalizedPoint(0.5,0.5), NormalizedPoint(0.5,0.8), NormalizedPoint(0.1,0.8)]),
                    ShapePiece(id: "rect-4-d",
                               vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.9,0.5), NormalizedPoint(0.9,0.8), NormalizedPoint(0.5,0.8)]),
                ],
            ]
        )
    }

    private func lShape() -> PuzzleShape {
        PuzzleShape(
            id: "l_shape", name: "L-Shape",
            outline: [
                NormalizedPoint(0.1,0.1), NormalizedPoint(0.5,0.1),
                NormalizedPoint(0.5,0.6), NormalizedPoint(0.9,0.6),
                NormalizedPoint(0.9,0.9), NormalizedPoint(0.1,0.9),
            ],
            decompositions: [
                2: [
                    ShapePiece(id: "l-2-a",
                               vertices: [NormalizedPoint(0.1,0.1), NormalizedPoint(0.5,0.1), NormalizedPoint(0.5,0.9), NormalizedPoint(0.1,0.9)]),
                    ShapePiece(id: "l-2-b",
                               vertices: [NormalizedPoint(0.5,0.6), NormalizedPoint(0.9,0.6), NormalizedPoint(0.9,0.9), NormalizedPoint(0.5,0.9)]),
                ],
                3: [
                    ShapePiece(id: "l-3-a",
                               vertices: [NormalizedPoint(0.1,0.1), NormalizedPoint(0.5,0.1), NormalizedPoint(0.5,0.6), NormalizedPoint(0.1,0.6)]),
                    ShapePiece(id: "l-3-b",
                               vertices: [NormalizedPoint(0.1,0.6), NormalizedPoint(0.5,0.6), NormalizedPoint(0.5,0.9), NormalizedPoint(0.1,0.9)]),
                    ShapePiece(id: "l-3-c",
                               vertices: [NormalizedPoint(0.5,0.6), NormalizedPoint(0.9,0.6), NormalizedPoint(0.9,0.9), NormalizedPoint(0.5,0.9)]),
                ],
                5: [
                    ShapePiece(id: "l-5-a",
                               vertices: [NormalizedPoint(0.1,0.1), NormalizedPoint(0.5,0.1), NormalizedPoint(0.5,0.35), NormalizedPoint(0.1,0.35)]),
                    ShapePiece(id: "l-5-b",
                               vertices: [NormalizedPoint(0.1,0.35), NormalizedPoint(0.5,0.35), NormalizedPoint(0.5,0.6), NormalizedPoint(0.1,0.6)]),
                    ShapePiece(id: "l-5-c",
                               vertices: [NormalizedPoint(0.1,0.6), NormalizedPoint(0.5,0.6), NormalizedPoint(0.5,0.9), NormalizedPoint(0.1,0.9)]),
                    ShapePiece(id: "l-5-d",
                               vertices: [NormalizedPoint(0.5,0.6), NormalizedPoint(0.7,0.6), NormalizedPoint(0.7,0.9), NormalizedPoint(0.5,0.9)]),
                    ShapePiece(id: "l-5-e",
                               vertices: [NormalizedPoint(0.7,0.6), NormalizedPoint(0.9,0.6), NormalizedPoint(0.9,0.9), NormalizedPoint(0.7,0.9)]),
                ],
            ]
        )
    }

    private func tShape() -> PuzzleShape {
        PuzzleShape(
            id: "t_shape", name: "T-Shape",
            outline: [
                NormalizedPoint(0.1,0.1), NormalizedPoint(0.9,0.1),
                NormalizedPoint(0.9,0.45), NormalizedPoint(0.6,0.45),
                NormalizedPoint(0.6,0.9), NormalizedPoint(0.4,0.9),
                NormalizedPoint(0.4,0.45), NormalizedPoint(0.1,0.45),
            ],
            decompositions: [
                3: [
                    ShapePiece(id: "t-3-a",
                               vertices: [NormalizedPoint(0.1,0.1), NormalizedPoint(0.9,0.1), NormalizedPoint(0.9,0.45), NormalizedPoint(0.1,0.45)]),
                    ShapePiece(id: "t-3-b",
                               vertices: [NormalizedPoint(0.4,0.45), NormalizedPoint(0.5,0.45), NormalizedPoint(0.5,0.9), NormalizedPoint(0.4,0.9)]),
                    ShapePiece(id: "t-3-c",
                               vertices: [NormalizedPoint(0.5,0.45), NormalizedPoint(0.6,0.45), NormalizedPoint(0.6,0.9), NormalizedPoint(0.5,0.9)]),
                ],
                5: [
                    ShapePiece(id: "t-5-a",
                               vertices: [NormalizedPoint(0.1,0.1), NormalizedPoint(0.5,0.1), NormalizedPoint(0.5,0.45), NormalizedPoint(0.1,0.45)]),
                    ShapePiece(id: "t-5-b",
                               vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.1), NormalizedPoint(0.9,0.45), NormalizedPoint(0.5,0.45)]),
                    ShapePiece(id: "t-5-c",
                               vertices: [NormalizedPoint(0.4,0.45), NormalizedPoint(0.6,0.45), NormalizedPoint(0.5,0.7)]),
                    ShapePiece(id: "t-5-d",
                               vertices: [NormalizedPoint(0.4,0.45), NormalizedPoint(0.5,0.7), NormalizedPoint(0.4,0.9)]),
                    ShapePiece(id: "t-5-e",
                               vertices: [NormalizedPoint(0.5,0.7), NormalizedPoint(0.6,0.45), NormalizedPoint(0.6,0.9)]),
                ],
            ]
        )
    }

    private func parallelogram() -> PuzzleShape {
        PuzzleShape(
            id: "parallelogram", name: "Parallelogram",
            outline: [
                NormalizedPoint(0.25,0.2), NormalizedPoint(0.9,0.2),
                NormalizedPoint(0.75,0.8), NormalizedPoint(0.1,0.8),
            ],
            decompositions: [
                2: [
                    ShapePiece(id: "par-2-a",
                               vertices: [NormalizedPoint(0.25,0.2), NormalizedPoint(0.575,0.2), NormalizedPoint(0.425,0.8), NormalizedPoint(0.1,0.8)]),
                    ShapePiece(id: "par-2-b",
                               vertices: [NormalizedPoint(0.575,0.2), NormalizedPoint(0.9,0.2), NormalizedPoint(0.75,0.8), NormalizedPoint(0.425,0.8)]),
                ],
                4: [
                    ShapePiece(id: "par-4-a",
                               vertices: [NormalizedPoint(0.25,0.2), NormalizedPoint(0.45,0.2), NormalizedPoint(0.3,0.8), NormalizedPoint(0.1,0.8)]),
                    ShapePiece(id: "par-4-b",
                               vertices: [NormalizedPoint(0.45,0.2), NormalizedPoint(0.65,0.2), NormalizedPoint(0.5,0.8), NormalizedPoint(0.3,0.8)]),
                    ShapePiece(id: "par-4-c",
                               vertices: [NormalizedPoint(0.65,0.2), NormalizedPoint(0.9,0.2), NormalizedPoint(0.75,0.8), NormalizedPoint(0.5,0.8)]),
                    ShapePiece(id: "par-4-d",
                               vertices: [NormalizedPoint(0.25,0.2), NormalizedPoint(0.1,0.8), NormalizedPoint(0.3,0.8)]),
                ],
            ]
        )
    }

    private func pentagon() -> PuzzleShape {
        PuzzleShape(
            id: "pentagon", name: "Pentagon",
            outline: [
                NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.38),
                NormalizedPoint(0.75,0.9), NormalizedPoint(0.25,0.9),
                NormalizedPoint(0.1,0.38),
            ],
            decompositions: [
                3: [
                    ShapePiece(id: "pent-3-a",
                               vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.38), NormalizedPoint(0.5,0.5)]),
                    ShapePiece(id: "pent-3-b",
                               vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.5,0.5), NormalizedPoint(0.1,0.38)]),
                    ShapePiece(id: "pent-3-c",
                               vertices: [NormalizedPoint(0.1,0.38), NormalizedPoint(0.5,0.5), NormalizedPoint(0.9,0.38), NormalizedPoint(0.75,0.9), NormalizedPoint(0.25,0.9)]),
                ],
                5: [
                    ShapePiece(id: "pent-5-a",
                               vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.38), NormalizedPoint(0.5,0.5)]),
                    ShapePiece(id: "pent-5-b",
                               vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.5,0.5), NormalizedPoint(0.1,0.38)]),
                    ShapePiece(id: "pent-5-c",
                               vertices: [NormalizedPoint(0.1,0.38), NormalizedPoint(0.5,0.5), NormalizedPoint(0.25,0.9)]),
                    ShapePiece(id: "pent-5-d",
                               vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.9,0.38), NormalizedPoint(0.75,0.9)]),
                    ShapePiece(id: "pent-5-e",
                               vertices: [NormalizedPoint(0.25,0.9), NormalizedPoint(0.5,0.5), NormalizedPoint(0.75,0.9)]),
                ],
            ]
        )
    }

    private func hexagon() -> PuzzleShape {
        PuzzleShape(
            id: "hexagon", name: "Hexagon",
            outline: [
                NormalizedPoint(0.5,0.1), NormalizedPoint(0.85,0.3),
                NormalizedPoint(0.85,0.7), NormalizedPoint(0.5,0.9),
                NormalizedPoint(0.15,0.7), NormalizedPoint(0.15,0.3),
            ],
            decompositions: [
                6: [
                    ShapePiece(id: "hex-6-a", vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.5,0.1), NormalizedPoint(0.85,0.3)]),
                    ShapePiece(id: "hex-6-b", vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.85,0.3), NormalizedPoint(0.85,0.7)]),
                    ShapePiece(id: "hex-6-c", vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.85,0.7), NormalizedPoint(0.5,0.9)]),
                    ShapePiece(id: "hex-6-d", vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.5,0.9), NormalizedPoint(0.15,0.7)]),
                    ShapePiece(id: "hex-6-e", vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.15,0.7), NormalizedPoint(0.15,0.3)]),
                    ShapePiece(id: "hex-6-f", vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.15,0.3), NormalizedPoint(0.5,0.1)]),
                ],
            ]
        )
    }

    private func arrowShape() -> PuzzleShape {
        PuzzleShape(
            id: "arrow", name: "Arrow",
            outline: [
                NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.5),
                NormalizedPoint(0.65,0.5), NormalizedPoint(0.65,0.9),
                NormalizedPoint(0.35,0.9), NormalizedPoint(0.35,0.5),
                NormalizedPoint(0.1,0.5),
            ],
            decompositions: [
                4: [
                    ShapePiece(id: "arr-4-a", vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.5), NormalizedPoint(0.65,0.5)]),
                    ShapePiece(id: "arr-4-b", vertices: [NormalizedPoint(0.1,0.5), NormalizedPoint(0.5,0.1), NormalizedPoint(0.35,0.5)]),
                    ShapePiece(id: "arr-4-c", vertices: [NormalizedPoint(0.35,0.5), NormalizedPoint(0.5,0.1), NormalizedPoint(0.65,0.5)]),
                    ShapePiece(id: "arr-4-d",
                               vertices: [NormalizedPoint(0.35,0.5), NormalizedPoint(0.65,0.5), NormalizedPoint(0.65,0.9), NormalizedPoint(0.35,0.9)]),
                ],
                6: [
                    ShapePiece(id: "arr-6-a", vertices: [NormalizedPoint(0.5,0.1), NormalizedPoint(0.9,0.5), NormalizedPoint(0.65,0.5)]),
                    ShapePiece(id: "arr-6-b", vertices: [NormalizedPoint(0.1,0.5), NormalizedPoint(0.5,0.1), NormalizedPoint(0.35,0.5)]),
                    ShapePiece(id: "arr-6-c", vertices: [NormalizedPoint(0.35,0.5), NormalizedPoint(0.5,0.1), NormalizedPoint(0.65,0.5)]),
                    ShapePiece(id: "arr-6-d",
                               vertices: [NormalizedPoint(0.35,0.5), NormalizedPoint(0.5,0.5), NormalizedPoint(0.5,0.7), NormalizedPoint(0.35,0.7)]),
                    ShapePiece(id: "arr-6-e",
                               vertices: [NormalizedPoint(0.5,0.5), NormalizedPoint(0.65,0.5), NormalizedPoint(0.65,0.7), NormalizedPoint(0.5,0.7)]),
                    ShapePiece(id: "arr-6-f",
                               vertices: [NormalizedPoint(0.35,0.7), NormalizedPoint(0.65,0.7), NormalizedPoint(0.65,0.9), NormalizedPoint(0.35,0.9)]),
                ],
            ]
        )
    }

    private func irregularQuad() -> PuzzleShape {
        PuzzleShape(
            id: "irregular_quad", name: "Irregular Quadrilateral",
            outline: [
                NormalizedPoint(0.2,0.1), NormalizedPoint(0.85,0.2),
                NormalizedPoint(0.8,0.85), NormalizedPoint(0.1,0.75),
            ],
            decompositions: [
                2: [
                    ShapePiece(id: "iq-2-a",
                               vertices: [NormalizedPoint(0.2,0.1), NormalizedPoint(0.85,0.2), NormalizedPoint(0.475,0.525)]),
                    ShapePiece(id: "iq-2-b",
                               vertices: [NormalizedPoint(0.2,0.1), NormalizedPoint(0.475,0.525), NormalizedPoint(0.8,0.85), NormalizedPoint(0.1,0.75)]),
                ],
                3: [
                    ShapePiece(id: "iq-3-a",
                               vertices: [NormalizedPoint(0.2,0.1), NormalizedPoint(0.85,0.2), NormalizedPoint(0.475,0.525)]),
                    ShapePiece(id: "iq-3-b",
                               vertices: [NormalizedPoint(0.85,0.2), NormalizedPoint(0.8,0.85), NormalizedPoint(0.475,0.525)]),
                    ShapePiece(id: "iq-3-c",
                               vertices: [NormalizedPoint(0.2,0.1), NormalizedPoint(0.475,0.525), NormalizedPoint(0.8,0.85), NormalizedPoint(0.1,0.75)]),
                ],
            ]
        )
    }
}
