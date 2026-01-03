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
    
    // Hat channel (crossmember)
    static let hatChannelWidth = 2.0
    static let hatChannelHeight = 2.0
    static let hatChannelWall = 0.150
    static let hatChannelFlangeWidth = 1.35
    
    // Pontoon mounting channel (raised profile on pontoon)
    static let channelWidth = 2.0
    static let channelHeight = 0.75
    static let channelSlotWidth = 1.0
    static let channelSlotDepth = 0.4
    static let channelSpacing = 8.0  // For 27" pontoons with 2 channels
    
    // Transom
    static let transomThickness = 0.125
    
    // Crossmember spacing
    static let crossmemberSpacing = 16.0
    
    // Bolt holes
    static let boltHoleDiameter = 0.375
}

// MARK: - Pontoon Mounting Channel (raised profile)

struct PontoonChannel: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Channel cross-section: raised rectangle with slot
        Rectangle(x: d.channelWidth, y: d.channelHeight)
            .aligned(at: .centerX, .minY)
            .subtracting {
                // Slot for square nuts
                Rectangle(x: d.channelSlotWidth, y: d.channelSlotDepth)
                    .aligned(at: .centerX, .maxY)
                    .translated(y: d.channelHeight)
            }
            .extruded(height: length)
            .rotated(x: 90°)
            .aligned(at: .centerX, .centerY, .minZ)
    }
}

// MARK: - Pontoon Components

struct PontoonStraight: Shape3D {
    let diameter: Double
    let length: Double
    let channelCount: Int  // 1 for 18", 2 for 27"
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Main cylinder body
        Cylinder(diameter: diameter, height: length)
            .rotated(y: 90°)
            .aligned(at: .minX, .centerY, .centerZ)
            .adding {
                // Transom at rear (X=0)
                Cylinder(diameter: diameter, height: d.transomThickness)
                    .rotated(y: 90°)
                    .aligned(at: .maxX, .centerY, .centerZ)
                
                // Transom at front (will be overlapped by nosecone or next section)
                Cylinder(diameter: diameter, height: d.transomThickness)
                    .rotated(y: 90°)
                    .aligned(at: .minX, .centerY, .centerZ)
                    .translated(x: length)
                
                // Mounting channels on top
                if channelCount == 1 {
                    // Single center channel for 18" pontoons
                    PontoonChannel(length: length)
                        .translated(x: length / 2, z: diameter / 2)
                } else if channelCount == 2 {
                    // Two channels for 27" pontoons
                    PontoonChannel(length: length)
                        .translated(x: length / 2, y: d.channelSpacing / 2, z: diameter / 2)
                    PontoonChannel(length: length)
                        .translated(x: length / 2, y: -d.channelSpacing / 2, z: diameter / 2)
                }
            }
    }
}

struct PontoonNosecone: Shape3D {
    let diameter: Double
    let length: Double
    let channelCount: Int  // 1 for 18", 2 for 27"
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Nosecone: elliptical/rounded shape
        // Use a sphere scaled to create an oblate ellipsoid
        Sphere(diameter: diameter)
            .scaled(x: length / (diameter / 2))  // Stretch along X
            .intersecting {
                // Keep only the front half
                Box(x:length, y:diameter, z:diameter)
                    .aligned(at: .minX, .centerY, .centerZ)
            }
            .adding {
                // Transom at rear of nosecone section
                Cylinder(diameter: diameter, height: d.transomThickness)
                    .rotated(y: 90°)
                    .aligned(at: .maxX, .centerY, .centerZ)
                
                // Short straight section before the curve for channel mounting
                Cylinder(diameter: diameter, height: length * 0.3)
                    .rotated(y: 90°)
                    .aligned(at: .minX, .centerY, .centerZ)
                
                // Mounting channels on top (shorter, on the straight part)
                if channelCount == 1 {
                    PontoonChannel(length: length * 0.6)
                        .translated(x: length * 0.3, z: diameter / 2)
                } else if channelCount == 2 {
                    PontoonChannel(length: length * 0.6)
                        .translated(x: length * 0.3, y: d.channelSpacing / 2, z: diameter / 2)
                    PontoonChannel(length: length * 0.6)
                        .translated(x: length * 0.3, y: -d.channelSpacing / 2, z: diameter / 2)
                }
            }
    }
}

// MARK: - Combined Pontoon (straight + nosecone)

struct Pontoon: Shape3D {
    let diameter: Double
    let straightLength: Double
    let hasNosecone: Bool
    let noseconeLength: Double
    let channelCount: Int
    
    init(diameter: Double, straightLength: Double, hasNosecone: Bool = false, noseconeLength: Double = 0, channelCount: Int = 1) {
        self.diameter = diameter
        self.straightLength = straightLength
        self.hasNosecone = hasNosecone
        self.noseconeLength = noseconeLength
        self.channelCount = channelCount
    }
    
    var body: any Geometry3D {
        PontoonStraight(diameter: diameter, length: straightLength, channelCount: channelCount)
            .adding {
                if hasNosecone {
                    PontoonNosecone(diameter: diameter, length: noseconeLength, channelCount: channelCount)
                        .translated(x: straightLength)
                }
            }
    }
}

// MARK: - Hat Channel Crossmember

struct HatChannel: Shape3D {
    let length: Double
    let withHoles: Bool
    
    init(length: Double, withHoles: Bool = true) {
        self.length = length
        self.withHoles = withHoles
    }
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
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
                if withHoles {
                    // Flange holes at ends
                    Cylinder(diameter: d.boltHoleDiameter, height: d.hatChannelHeight + 1)
                        .translated(x: -d.hatChannelWidth / 2 - 0.4, y: length / 2 - 1.5)
                        .clonedAt(y: -length + 3)
                    Cylinder(diameter: d.boltHoleDiameter, height: d.hatChannelHeight + 1)
                        .translated(x: d.hatChannelWidth / 2 + 0.4, y: length / 2 - 1.5)
                        .clonedAt(y: -length + 3)
                }
            }
    }
}

// MARK: - C-Bracket

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
                Cylinder(diameter: d.boltHoleDiameter, height: thickness + 0.5)
                    .translated(x: -0.4, y: 0.4, z: height - thickness - 0.25)
                    .clonedAt(x: 0.8)
                    .clonedAt(y: -0.8)
            }
    }
}

// MARK: - Main Crossmember

struct MainCrossmember: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        Box(x: 2, y: length, z: 3)
            .aligned(at: .centerXY, .minZ)
            .subtracting {
                Cylinder(diameter: d.boltHoleDiameter, height: 4)
                    .translated(y: length / 2 - 2, z: -0.5)
                    .clonedAt(y: -4)
                    .clonedAt(y: -length + 8)
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
        
        // Main 27" pontoons (OUTER) - 2 channels each
        Pontoon(
            diameter: d.mainPontoonDiameter,
            straightLength: d.mainPontoonLength,
            hasNosecone: true,
            noseconeLength: 36,
            channelCount: 2
        )
        .translated(y: d.mainPontoonSpacing / 2)
        .symmetry(over: .y)
        .colored(.orange)
        
        .adding {
            // Middle 18" pontoons (INNER) - 1 channel each
            // Rear straight section
            Pontoon(
                diameter: d.smallPontoonDiameter,
                straightLength: d.smallPontoonStraightLength,
                hasNosecone: false,
                channelCount: 1
            )
            .translated(x: 20, y: d.smallPontoonSpacing / 2)
            .adding {
                // Front section with nosecone
                Pontoon(
                    diameter: d.smallPontoonDiameter,
                    straightLength: d.smallPontoonStraightLength,
                    hasNosecone: true,
                    noseconeLength: d.smallPontoonNoseconeLength,
                    channelCount: 1
                )
                .translated(x: 20 + d.smallPontoonStraightLength, y: d.smallPontoonSpacing / 2)
            }
            .symmetry(over: .y)
            .colored(.orange)
        }
        
        .adding {
            // Front 18" pontoons (your upgrade) - 1 channel each
            Pontoon(
                diameter: d.smallPontoonDiameter,
                straightLength: d.smallPontoonStraightLength,
                hasNosecone: true,
                noseconeLength: d.smallPontoonNoseconeLength,
                channelCount: 1
            )
            .translated(x: d.mainPontoonLength, y: d.smallPontoonSpacing / 2)
            .symmetry(over: .y)
            .colored(.orange)
        }
        
        .adding {
            // Hat channel crossmembers for front pontoons
            HatChannel(length: d.smallPontoonSpacing, withHoles: true)
                .translated(x: d.mainPontoonLength + 4, z: d.smallPontoonDiameter / 2 + d.channelHeight + 1)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.gray)
        }
        
        .adding {
            // C-brackets at center
            CBracket()
                .translated(x: d.mainPontoonLength + 4, z: d.smallPontoonDiameter / 2 + d.channelHeight + 1 + d.hatChannelHeight)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.lightGray)
        }
        
        .adding {
            // Main crossmembers
            MainCrossmember(length: d.mainPontoonSpacing)
                .translated(x: 10, z: d.mainPontoonDiameter / 2 + d.channelHeight + 1)
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
                .translated(x: d.mainPontoonLength - 10, z: d.mainPontoonDiameter / 2 + d.channelHeight + 4)
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