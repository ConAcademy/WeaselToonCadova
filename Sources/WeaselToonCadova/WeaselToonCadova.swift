import Cadova

// MARK: - Dimensions (all in inches)
struct BoatDimensions {
    // Main pontoons (27" diameter) - outer pontoons
    static let mainPontoonDiameter = 27.0
    static let mainPontoonLength = 144.0
    static let mainPontoonSpacing = 60.0  // Center to center (outer)
    
    // Small pontoons (18" diameter) - inner pontoons
    static let smallPontoonDiameter = 18.0
    static let smallPontoonStraightLength = 48.0
    static let smallPontoonNoseconeLength = 24.0
    static let smallPontoonSpacing = 24.0  // Center to center (inner)
    
    // Hat channel
    static let hatChannelWidth = 2.0
    static let hatChannelHeight = 2.0
    static let hatChannelWall = 0.150
    static let hatChannelFlangeWidth = 1.35
    
    // Crossmember spacing
    static let crossmemberSpacing = 16.0
}

// MARK: - Components

struct Pontoon: Shape3D {
    let diameter: Double
    let straightLength: Double
    let hasNosecone: Bool
    let noseconeLength: Double
    
    init(diameter: Double, straightLength: Double, hasNosecone: Bool = false, noseconeLength: Double = 0) {
        self.diameter = diameter
        self.straightLength = straightLength
        self.hasNosecone = hasNosecone
        self.noseconeLength = noseconeLength
    }
    
    var body: any Geometry3D {
        // Main cylinder body - oriented along X axis (fore-aft)
        Cylinder(diameter: diameter, height: straightLength)
            .rotated(y: 90°)  // Rotate so cylinder runs along X
            .aligned(at: .minX, .centerY, .centerZ)
            .adding {
                // Rear cap (hemisphere) at X=0
                Sphere(diameter: diameter)
                    .scaled(x: 0.5)
                    .aligned(at: .maxX, .centerY, .centerZ)
                
                // Nosecone at front
                if hasNosecone {
                    Loft {
                        layer(z: 0) {
                            Circle(diameter: diameter)
                        }
                        layer(z: noseconeLength) {
                            Circle(diameter: diameter * 0.1)
                        }
                    }
                    .rotated(y: 90°)
                    .translated(x: straightLength)
                }
            }
    }
}

struct HatChannel: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Hat channel cross-section
        Rectangle(x: d.hatChannelWidth, y: d.hatChannelHeight)
            .aligned(at: .centerX, .minY)
            .subtracting {
                Rectangle(
                    x: d.hatChannelWidth - 2 * d.hatChannelWall,
                    y: d.hatChannelHeight - d.hatChannelWall
                )
                .aligned(at: .centerX, .minY)
                .translated(y: d.hatChannelWall)
            }
            .adding {
                // Bottom flanges
                Rectangle(x: d.hatChannelFlangeWidth, y: d.hatChannelWall)
                    .aligned(at: .maxX, .minY)
                    .translated(x: -d.hatChannelWidth / 2)
                Rectangle(x: d.hatChannelFlangeWidth, y: d.hatChannelWall)
                    .aligned(at: .minX, .minY)
                    .translated(x: d.hatChannelWidth / 2)
            }
            .extruded(height: length)
            .rotated(x: 90°)
            .aligned(at: .centerX, .centerY, .minZ)
    }
}

struct CBracket: Shape3D {
    let height: Double
    let width: Double
    let thickness: Double
    
    init(height: Double = 4.0, width: Double = 2.0, thickness: Double = 0.25) {
        self.height = height
        self.width = width
        self.thickness = thickness
    }
    
    var body: any Geometry3D {
        Box(x: thickness, y: width, z: height)
            .translated(x: width / 2 - thickness / 2)
            .adding {
                Box(x: thickness, y: width, z: height)
                    .translated(x: -width / 2 + thickness / 2)
                Box(x: width, y: width, z: thickness)
                    .translated(z: height - thickness)
            }
            .aligned(at: .centerXY, .minZ)
    }
}

// MARK: - Full Boat Assembly

struct PontoonBoat: Shape3D {
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Main 27" pontoons (OUTER - port and starboard)
        Pontoon(
            diameter: d.mainPontoonDiameter,
            straightLength: d.mainPontoonLength,
            hasNosecone: true,
            noseconeLength: 36
        )
        .translated(y: d.mainPontoonSpacing / 2)
        .symmetry(over: .y)  // Mirror across Y to get port & starboard
        .colored(.orange)
        
        .adding {
            // Middle 18" pontoons (INNER - between main pontoons)
            // Rear straight section
            Pontoon(
                diameter: d.smallPontoonDiameter,
                straightLength: d.smallPontoonStraightLength,
                hasNosecone: false
            )
            .translated(x: 20, y: d.smallPontoonSpacing / 2)
            .adding {
                // Front section with nosecone
                Pontoon(
                    diameter: d.smallPontoonDiameter,
                    straightLength: d.smallPontoonStraightLength,
                    hasNosecone: true,
                    noseconeLength: d.smallPontoonNoseconeLength
                )
                .translated(x: 20 + d.smallPontoonStraightLength, y: d.smallPontoonSpacing / 2)
            }
            .symmetry(over: .y)  // Mirror for both sides
            .colored(.orange)
        }
        
        .adding {
            // Front 18" pontoons (your upgrade - also INNER)
            Pontoon(
                diameter: d.smallPontoonDiameter,
                straightLength: d.smallPontoonStraightLength,
                hasNosecone: true,
                noseconeLength: d.smallPontoonNoseconeLength
            )
            .translated(x: d.mainPontoonLength, y: d.smallPontoonSpacing / 2)
            .symmetry(over: .y)
            .colored(.orange)
        }
        
        .adding {
            // Hat channel crossmembers for front pontoons
            HatChannel(length: d.smallPontoonSpacing)
                .translated(x: d.mainPontoonLength, z: d.smallPontoonDiameter / 2 + 2)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.gray)
        }
        
        .adding {
            // C-brackets at center
            CBracket()
                .translated(x: d.mainPontoonLength, z: d.smallPontoonDiameter / 2 + 2 + d.hatChannelHeight)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.lightGray)
        }
        
        .adding {
            // Main crossmembers spanning between main pontoons
            Box(x: 2, y: d.mainPontoonSpacing, z: 3)
                .aligned(at: .centerXY, .minZ)
                .translated(x: 10, z: d.mainPontoonDiameter / 2 + 2)
                .clonedAt(x: 18)
                .clonedAt(x: 18)
                .clonedAt(x: 18)
                .clonedAt(x: 18)
                .clonedAt(x: 18)
                .clonedAt(x: 18)
                .clonedAt(x: 18)
                .colored(.gray)
        }
        
        .adding {
            // Tow plate (runs fore-aft at centerline)
            Box(x: 38, y: 3, z: 0.375)
                .aligned(at: .minX, .centerY, .minZ)
                .translated(x: d.mainPontoonLength - 10, z: d.mainPontoonDiameter / 2 + 5)
                .colored(.darkGray)
        }
    }
}

// MARK: - Main

@main
struct Main {
    static func main() async throws {
        await Model("pontoon-boat") {
            PontoonBoat()
        }
    }
}