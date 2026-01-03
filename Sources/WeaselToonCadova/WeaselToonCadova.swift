import Cadova

// MARK: - Dimensions (all in inches)
struct BoatDimensions {
    // Main pontoons (27" diameter) - outer pontoons
    static let mainPontoonDiameter = 27.0
    static let mainPontoonStraightLength = 35.4  // Corrected
    static let mainPontoonSpacing = 60.0
    
    // Small pontoons (18" diameter) - inner pontoons
    static let smallPontoonDiameter = 18.0
    static let smallPontoonStraightLength = 24.0  // Corrected
    static let smallPontoonNoseconeLength = 24.0
    static let smallPontoonSpacing = 24.0
    
    // Hat channel (from the diagram you provided)
    static let hatChannelTopWidth = 2.0
    static let hatChannelHeight = 2.0
    static let hatChannelTopThickness = 0.175
    static let hatChannelWallThickness = 0.150
    static let hatChannelFlangeWidth = 1.0
    static let hatChannelFlangeThickness = 0.150
    static let hatChannelTotalBottomWidth = 1.35
    
    // Pontoon mounting channel (raised T-slot profile)
    static let channelWidth = 2.0
    static let channelHeight = 0.75
    static let channelSlotWidth = 0.8
    static let channelSlotDepth = 0.5
    static let channelSpacing = 8.0  // For 27" pontoons with 2 channels
    
    // Transom
    static let transomThickness = 0.125
    
    // Crossmember spacing
    static let crossmemberSpacing = 16.0
    
    // Bolt holes
    static let boltHoleDiameter = 0.375
}

// MARK: - Pontoon Mounting Channel (raised T-slot profile)

struct PontoonChannel: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // T-slot channel profile
        // Base rectangle
        Box(x: length, y: d.channelWidth, z: d.channelHeight)
            .aligned(at: .centerX, .centerY, .minZ)
            .subtracting {
                // T-slot groove (wider at bottom, narrow at top)
                Box(x: length + 2, y: d.channelSlotWidth, z: d.channelSlotDepth)
                    .aligned(at: .centerX, .centerY, .maxZ)
                    .translated(z: d.channelHeight)
            }
    }
}

// MARK: - Transom (flat end cap)

struct Transom: Shape3D {
    let diameter: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        Cylinder(diameter: diameter, height: d.transomThickness)
            .rotated(y: 90°)
            .aligned(at: .centerX, .centerY, .centerZ)
    }
}

// MARK: - Pontoon Straight Section

struct PontoonStraight: Shape3D {
    let diameter: Double
    let length: Double
    let channelCount: Int
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Main cylinder
        Cylinder(diameter: diameter, height: length)
            .rotated(y: 90°)
            .aligned(at: .minX, .centerY, .centerZ)
            .adding {
                // Rear transom at X=0
                Transom(diameter: diameter)
                    .translated(x: -d.transomThickness / 2)
            }
            .adding {
                // Front transom
                Transom(diameter: diameter)
                    .translated(x: length + d.transomThickness / 2)
            }
            .adding {
                // Mounting channels on top
                if channelCount == 1 {
                    PontoonChannel(length: length - 2)
                        .translated(x: length / 2, z: diameter / 2)
                }
            }
            .adding {
                if channelCount == 2 {
                    PontoonChannel(length: length - 2)
                        .translated(x: length / 2, y: d.channelSpacing / 2, z: diameter / 2)
                }
            }
            .adding {
                if channelCount == 2 {
                    PontoonChannel(length: length - 2)
                        .translated(x: length / 2, y: -d.channelSpacing / 2, z: diameter / 2)
                }
            }
    }
}

// MARK: - Pontoon Nosecone

struct PontoonNosecone: Shape3D {
    let diameter: Double
    let length: Double
    let channelCount: Int
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Elliptical nosecone (stretched hemisphere)
        Sphere(diameter: diameter)
            .scaled(x: (length * 2) / diameter)
            .intersecting {
                Box(x:length + 1, y:diameter + 1, z:diameter + 1)
                    .aligned(at: .minX, .centerY, .centerZ)
            }
            .aligned(at: .minX, .centerY, .centerZ)
            .adding {
                // Rear transom
                Transom(diameter: diameter)
                    .translated(x: -d.transomThickness / 2)
            }
            .adding {
                // Channel on the curved surface (shorter)
                if channelCount == 1 {
                    PontoonChannel(length: length * 0.4)
                        .translated(x: length * 0.2, z: diameter / 2)
                }
            }
            .adding {
                if channelCount == 2 {
                    PontoonChannel(length: length * 0.4)
                        .translated(x: length * 0.2, y: d.channelSpacing / 2, z: diameter / 2)
                }
            }
            .adding {
                if channelCount == 2 {
                    PontoonChannel(length: length * 0.4)
                        .translated(x: length * 0.2, y: -d.channelSpacing / 2, z: diameter / 2)
                }
            }
    }
}

// MARK: - Hat Channel (accurate to diagram)

struct HatChannel: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Build the hat channel cross-section from the diagram
        // Top plate
        Rectangle(x: d.hatChannelTopWidth, y: d.hatChannelTopThickness)
            .aligned(at: .centerX, .maxY)
            .translated(y: d.hatChannelHeight)
            .adding {
                // Left wall
                Rectangle(x: d.hatChannelWallThickness, y: d.hatChannelHeight - d.hatChannelTopThickness)
                    .aligned(at: .minX, .minY)
                    .translated(x: -d.hatChannelTopWidth / 2, y: d.hatChannelFlangeThickness)
            }
            .adding {
                // Right wall
                Rectangle(x: d.hatChannelWallThickness, y: d.hatChannelHeight - d.hatChannelTopThickness)
                    .aligned(at: .maxX, .minY)
                    .translated(x: d.hatChannelTopWidth / 2, y: d.hatChannelFlangeThickness)
            }
            .adding {
                // Left flange
                Rectangle(x: d.hatChannelTotalBottomWidth, y: d.hatChannelFlangeThickness)
                    .aligned(at: .minX, .minY)
                    .translated(x: -d.hatChannelTopWidth / 2)
            }
            .adding {
                // Right flange
                Rectangle(x: d.hatChannelTotalBottomWidth, y: d.hatChannelFlangeThickness)
                    .aligned(at: .maxX, .minY)
                    .translated(x: d.hatChannelTopWidth / 2)
            }
            .extruded(height: length)
            .rotated(x: 90°)
            .aligned(at: .centerX, .centerY, .minZ)
    }
}

// MARK: - C-Bracket

struct CBracket: Shape3D {
    var body: any Geometry3D {
        let height = 4.0
        let width = 2.0
        let thickness = 0.25
        
        // Two vertical sides
        Box(x: thickness, y: width, z: height)
            .translated(x: width / 2 - thickness / 2)
            .adding {
                Box(x: thickness, y: width, z: height)
                    .translated(x: -width / 2 + thickness / 2)
            }
            .adding {
                // Top plate
                Box(x: width, y: width, z: thickness)
                    .translated(z: height - thickness)
            }
            .aligned(at: .centerXY, .minZ)
    }
}

// MARK: - Main Crossmember

struct MainCrossmember: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        Box(x: 2, y: length, z: 3)
            .aligned(at: .centerXY, .minZ)
    }
}

// MARK: - Full Boat Assembly

struct PontoonBoat: Shape3D {
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Calculate total main pontoon length (multiple straights + nosecone)
        let mainPontoonTotalStraight = d.mainPontoonStraightLength * 4  // 4 straight sections
        let mainNoseconeLength = 36.0
        
        // Main 27" pontoons (OUTER) - 2 channels each
        // Multiple straight sections joined together
        PontoonStraight(diameter: d.mainPontoonDiameter, length: d.mainPontoonStraightLength, channelCount: 2)
            .adding {
                PontoonStraight(diameter: d.mainPontoonDiameter, length: d.mainPontoonStraightLength, channelCount: 2)
                    .translated(x: d.mainPontoonStraightLength)
            }
            .adding {
                PontoonStraight(diameter: d.mainPontoonDiameter, length: d.mainPontoonStraightLength, channelCount: 2)
                    .translated(x: d.mainPontoonStraightLength * 2)
            }
            .adding {
                PontoonStraight(diameter: d.mainPontoonDiameter, length: d.mainPontoonStraightLength, channelCount: 2)
                    .translated(x: d.mainPontoonStraightLength * 3)
            }
            .adding {
                PontoonNosecone(diameter: d.mainPontoonDiameter, length: mainNoseconeLength, channelCount: 2)
                    .translated(x: mainPontoonTotalStraight)
            }
            .translated(y: d.mainPontoonSpacing / 2)
            .symmetry(over: .y)
            .colored(.orange)
        
        .adding {
            // Middle 18" pontoons (INNER) - 1 channel each
            // Rear straight section
            PontoonStraight(diameter: d.smallPontoonDiameter, length: d.smallPontoonStraightLength, channelCount: 1)
                .translated(x: 20, y: d.smallPontoonSpacing / 2)
                .adding {
                    // Front section with nosecone
                    PontoonStraight(diameter: d.smallPontoonDiameter, length: d.smallPontoonStraightLength, channelCount: 1)
                        .translated(x: 20 + d.smallPontoonStraightLength, y: d.smallPontoonSpacing / 2)
                }
                .adding {
                    PontoonNosecone(diameter: d.smallPontoonDiameter, length: d.smallPontoonNoseconeLength, channelCount: 1)
                        .translated(x: 20 + d.smallPontoonStraightLength * 2, y: d.smallPontoonSpacing / 2)
                }
                .symmetry(over: .y)
                .colored(.orange)
        }
        
        .adding {
            // Front 18" pontoons (your upgrade) - 1 channel each
            PontoonStraight(diameter: d.smallPontoonDiameter, length: d.smallPontoonStraightLength, channelCount: 1)
                .translated(x: mainPontoonTotalStraight, y: d.smallPontoonSpacing / 2)
                .adding {
                    PontoonNosecone(diameter: d.smallPontoonDiameter, length: d.smallPontoonNoseconeLength, channelCount: 1)
                        .translated(x: mainPontoonTotalStraight + d.smallPontoonStraightLength, y: d.smallPontoonSpacing / 2)
                }
                .symmetry(over: .y)
                .colored(.orange)
        }
        
        .adding {
            // Hat channel crossmembers for front pontoons
            HatChannel(length: d.smallPontoonSpacing)
                .translated(x: mainPontoonTotalStraight + 4, z: d.smallPontoonDiameter / 2 + d.channelHeight)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.gray)
        }
        
        .adding {
            // C-brackets at center
            CBracket()
                .translated(x: mainPontoonTotalStraight + 4, z: d.smallPontoonDiameter / 2 + d.channelHeight + d.hatChannelHeight)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .clonedAt(x: d.crossmemberSpacing)
                .colored(.lightGray)
        }
        
        .adding {
            // Main crossmembers
            MainCrossmember(length: d.mainPontoonSpacing)
                .translated(x: 10, z: d.mainPontoonDiameter / 2 + d.channelHeight)
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
                .translated(x: mainPontoonTotalStraight - 10, z: d.mainPontoonDiameter / 2 + d.channelHeight + 4)
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