import Cadova

// MARK: - Dimensions (all in inches)
struct BoatDimensions {
    // Main pontoons (27" diameter)
    static let mainPontoonDiameter = 27.0
    static let mainPontoonLength = 144.0
    
    // Small pontoons (18" diameter)
    static let smallPontoonDiameter = 18.0
    static let smallPontoonStraightLength = 48.0
    static let smallPontoonNoseconeLength = 24.0
    
    // Hat channel
    static let hatChannelWidth = 2.0
    static let hatChannelHeight = 2.0
    static let hatChannelWall = 0.150
    static let hatChannelFlangeWidth = 1.35
    
    // Spacing
    static let mainPontoonSpacing = 60.0
    static let smallPontoonSpacing = 24.0
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
        Cylinder(diameter: diameter, height: straightLength)
            .aligned(at: .centerXY, .minZ)
            .adding {
                // Rear cap (hemisphere)
                Sphere(diameter: diameter)
                    .intersecting {
                        Box(x: diameter, y:diameter, z:diameter / 2)
                            .aligned(at: .centerXY, .maxZ)
                    }
                
                // Nosecone (if present)
                if hasNosecone {
                    Loft {
                        layer(z: straightLength) {
                            Circle(diameter: diameter)
                        }
                        layer(z: straightLength + noseconeLength) {
                            Circle(diameter: diameter * 0.15)
                        }
                    }
                }
            }
    }
}

struct HatChannel: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Create hat channel cross-section as a 2D profile
        Rectangle(x: d.hatChannelWidth, y: d.hatChannelHeight)
            .aligned(at: .centerX, .minY)
            .subtracting {
                // Hollow interior
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
            .aligned(at: .centerXY, .minZ)
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
        // U-shape: two vertical sides + top plate
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
        
        // Main 27" pontoons - use symmetry for port/starboard
        Pontoon(
            diameter: d.mainPontoonDiameter,
            straightLength: d.mainPontoonLength,
            hasNosecone: true,
            noseconeLength: 36
        )
        .rotated(x: -90°)
        .translated(y: d.mainPontoonSpacing / 2)
        .symmetry(over: .x)
        .colored(.orange)
        
        .adding {
            // Middle 18" pontoons (port side, then mirrored)
            Pontoon(
                diameter: d.smallPontoonDiameter,
                straightLength: d.smallPontoonStraightLength
            )
            .rotated(x: -90°)
            .translated(x: 48, y: d.smallPontoonSpacing / 2)
            .adding {
                Pontoon(
                    diameter: d.smallPontoonDiameter,
                    straightLength: d.smallPontoonStraightLength,
                    hasNosecone: true,
                    noseconeLength: d.smallPontoonNoseconeLength
                )
                .rotated(x: -90°)
                .translated(x: 48 + d.smallPontoonStraightLength, y: d.smallPontoonSpacing / 2)
            }
            .symmetry(over: .x)
            .colored(.orange)
        }
        
        .adding {
            // Front 18" pontoons (your upgrade)
            Pontoon(
                diameter: d.smallPontoonDiameter,
                straightLength: d.smallPontoonStraightLength,
                hasNosecone: true,
                noseconeLength: d.smallPontoonNoseconeLength
            )
            .rotated(x: -90°)
            .translated(x: d.mainPontoonLength - 24, y: d.smallPontoonSpacing / 2)
            .symmetry(over: .x)
            .colored(.orange)
        }
        
        .adding {
            // Hat channel crossmembers for front pontoons
            HatChannel(length: d.smallPontoonSpacing)
                .translated(x: d.mainPontoonLength - 24, z: d.smallPontoonDiameter / 2 + d.hatChannelHeight)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.gray)
        }
        
        .adding {
            // C-brackets
            CBracket()
                .translated(x: d.mainPontoonLength - 24, z: d.smallPontoonDiameter / 2 + d.hatChannelHeight + d.hatChannelHeight)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.lightGray)
        }
        
        .adding {
            // Main crossmembers (simplified)
            Box(x: 2, y: d.mainPontoonSpacing, z: 3)
                .aligned(at: .centerXY, .minZ)
                .translated(z: d.mainPontoonDiameter / 2 + 2)
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
            // Tow plate
            Box(x: 38, y: 3, z: 0.375)
                .aligned(at: .minX, .centerY, .minZ)
                .translated(x: d.mainPontoonLength - 60, z: d.mainPontoonDiameter / 2 + 5)
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