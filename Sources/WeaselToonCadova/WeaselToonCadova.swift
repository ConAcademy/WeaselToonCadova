import Cadova

// MARK: - Dimensions (all in inches)
struct BoatDimensions {
    // Main pontoons (27" diameter) - outer pontoons
    static let mainPontoonDiameter = 27.0
    static let mainPontoonLength = 144.0
    static let mainPontoonSpacing = 60.0
    
    // Small pontoons (18" diameter) - inner pontoons
    static let smallPontoonDiameter = 18.0
    static let smallPontoonStraightLength = 48.0
    static let smallPontoonNoseconeLength = 24.0
    static let smallPontoonSpacing = 24.0
    
    // Hat channel
    static let hatChannelWidth = 2.0
    static let hatChannelHeight = 2.0
    static let hatChannelWall = 0.150
    static let hatChannelFlangeWidth = 1.35
    
    // Pontoon channel (groove for mounting)
    static let pontoonChannelWidth = 2.2
    static let pontoonChannelDepth = 0.5
    
    // Crossmember spacing
    static let crossmemberSpacing = 16.0
    
    // Bolt holes
    static let boltHoleDiameter = 0.375
}

// MARK: - Components

struct Pontoon: Shape3D {
    let diameter: Double
    let straightLength: Double
    let hasNosecone: Bool
    let noseconeLength: Double
    let hasChannel: Bool
    
    init(diameter: Double, straightLength: Double, hasNosecone: Bool = false, noseconeLength: Double = 0, hasChannel: Bool = true) {
        self.diameter = diameter
        self.straightLength = straightLength
        self.hasNosecone = hasNosecone
        self.noseconeLength = noseconeLength
        self.hasChannel = hasChannel
    }
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Main cylinder body - oriented along X axis (fore-aft)
        Cylinder(diameter: diameter, height: straightLength)
            .rotated(y: 90°)
            .aligned(at: .minX, .centerY, .centerZ)
            .adding {
                // Transom (flat rear cap) at X=0
                Cylinder(diameter: diameter, height: 0.125)
                    .rotated(y: 90°)
                    .aligned(at: .maxX, .centerY, .centerZ)
                
                // Nosecone at front (if present)
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
                } else {
                    // Flat front cap if no nosecone
                    Cylinder(diameter: diameter, height: 0.125)
                        .rotated(y: 90°)
                        .aligned(at: .minX, .centerY, .centerZ)
                        .translated(x: straightLength)
                }
            }
            .subtracting {
                // Channel groove on top for mounting
                if hasChannel {
                    Box(x: straightLength + 10, y: d.pontoonChannelWidth, z: d.pontoonChannelDepth)
                        .aligned(at: .centerX, .centerY, .minZ)
                        .translated(x: straightLength / 2, z: diameter / 2 - d.pontoonChannelDepth)
                }
            }
    }
}

struct HatChannel: Shape3D {
    let length: Double
    let withHoles: Bool
    
    init(length: Double, withHoles: Bool = true) {
        self.length = length
        self.withHoles = withHoles
    }
    
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
            .subtracting {
                // Bolt holes through flanges at ends
                if withHoles {
                    // Port side holes (2 per end)
                    Cylinder(diameter: d.boltHoleDiameter, height: d.hatChannelHeight + 1)
                        .translated(x: -d.hatChannelWidth / 2 - 0.4, y: length / 2 - 1)
                        .clonedAt(y: -length + 2)
                    Cylinder(diameter: d.boltHoleDiameter, height: d.hatChannelHeight + 1)
                        .translated(x: -d.hatChannelWidth / 2 - 0.4, y: length / 2 - 2.5)
                        .clonedAt(y: -length + 5)
                    
                    // Starboard side holes
                    Cylinder(diameter: d.boltHoleDiameter, height: d.hatChannelHeight + 1)
                        .translated(x: d.hatChannelWidth / 2 + 0.4, y: length / 2 - 1)
                        .clonedAt(y: -length + 2)
                    Cylinder(diameter: d.boltHoleDiameter, height: d.hatChannelHeight + 1)
                        .translated(x: d.hatChannelWidth / 2 + 0.4, y: length / 2 - 2.5)
                        .clonedAt(y: -length + 5)
                    
                    // Center holes for C-bracket
                    Cylinder(diameter: d.boltHoleDiameter, height: d.hatChannelHeight + 1)
                        .translated(x: -0.5, y: 0.5)
                        .clonedAt(x: 1)
                        .clonedAt(y: -1)
                }
            }
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
        let d = BoatDimensions.self
        
        Box(x: thickness, y: width, z: height)
            .translated(x: width / 2 - thickness / 2)
            .adding {
                Box(x: thickness, y: width, z: height)
                    .translated(x: -width / 2 + thickness / 2)
                Box(x: width, y: width, z: thickness)
                    .translated(z: height - thickness)
            }
            .aligned(at: .centerXY, .minZ)
            .subtracting {
                // Bolt holes in top plate
                Cylinder(diameter: d.boltHoleDiameter, height: thickness + 0.5)
                    .translated(x: -0.4, y: 0.4, z: height - thickness - 0.25)
                    .clonedAt(x: 0.8)
                    .clonedAt(y: -0.8)
            }
    }
}

struct MainCrossmember: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        Box(x: 2, y: length, z: 3)
            .aligned(at: .centerXY, .minZ)
            .subtracting {
                // Mounting holes along length
                Cylinder(diameter: d.boltHoleDiameter, height: 4)
                    .translated(y: length / 2 - 2, z: -0.5)
                    .clonedAt(y: -4)
                    .clonedAt(y: -length + 8)
                
                // Center holes for inner pontoon mounts
                Cylinder(diameter: d.boltHoleDiameter, height: 4)
                    .translated(y: d.smallPontoonSpacing / 2 + 2, z: -0.5)
                    .clonedAt(y: -4)
                    .symmetry(over: .y)
            }
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
            noseconeLength: 36,
            hasChannel: true
        )
        .translated(y: d.mainPontoonSpacing / 2)
        .symmetry(over: .y)
        .colored(.orange)
        
        .adding {
            // Middle 18" pontoons (INNER - between main pontoons)
            // Rear straight section (no nosecone, has transom on both ends effectively)
            Pontoon(
                diameter: d.smallPontoonDiameter,
                straightLength: d.smallPontoonStraightLength,
                hasNosecone: false,
                hasChannel: true
            )
            .translated(x: 20, y: d.smallPontoonSpacing / 2)
            .adding {
                // Front section with nosecone
                Pontoon(
                    diameter: d.smallPontoonDiameter,
                    straightLength: d.smallPontoonStraightLength,
                    hasNosecone: true,
                    noseconeLength: d.smallPontoonNoseconeLength,
                    hasChannel: true
                )
                .translated(x: 20 + d.smallPontoonStraightLength, y: d.smallPontoonSpacing / 2)
            }
            .symmetry(over: .y)
            .colored(.orange)
        }
        
        .adding {
            // Front 18" pontoons (your upgrade)
            Pontoon(
                diameter: d.smallPontoonDiameter,
                straightLength: d.smallPontoonStraightLength,
                hasNosecone: true,
                noseconeLength: d.smallPontoonNoseconeLength,
                hasChannel: true
            )
            .translated(x: d.mainPontoonLength, y: d.smallPontoonSpacing / 2)
            .symmetry(over: .y)
            .colored(.orange)
        }
        
        .adding {
            // Hat channel crossmembers for front pontoons (with holes)
            HatChannel(length: d.smallPontoonSpacing, withHoles: true)
                .translated(x: d.mainPontoonLength, z: d.smallPontoonDiameter / 2 + 2)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.gray)
        }
        
        .adding {
            // C-brackets at center (with holes)
            CBracket()
                .translated(x: d.mainPontoonLength, z: d.smallPontoonDiameter / 2 + 2 + d.hatChannelHeight)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.lightGray)
        }
        
        .adding {
            // Main crossmembers spanning between main pontoons (with holes)
            MainCrossmember(length: d.mainPontoonSpacing)
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
                .subtracting {
                    // Mounting holes in tow plate
                    Cylinder(diameter: BoatDimensions.boltHoleDiameter, height: 1)
                        .translated(x: d.mainPontoonLength - 10 + 2, z: d.mainPontoonDiameter / 2 + 5 - 0.25)
                        .clonedAt(x: 16)
                        .clonedAt(x: 16)
                }
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