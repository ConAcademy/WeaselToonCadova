

import Cadova

// MARK: - Dimensions (all in inches)
struct BoatDimensions {
    // Main pontoons (27" diameter)
    static let mainPontoonDiameter = 27.0
    static let mainPontoonLength = 144.0  // Estimate total length
    
    // Small pontoons (18" diameter)
    static let smallPontoonDiameter = 18.0
    static let smallPontoonStraightLength = 48.0  // Estimate
    static let smallPontoonNoseconeLength = 24.0  // Estimate
    
    // Hat channel
    static let hatChannelWidth = 2.0
    static let hatChannelHeight = 2.0
    static let hatChannelWall = 0.150
    static let hatChannelFlangeWidth = 1.35
    
    // Spacing
    static let mainPontoonSpacing = 60.0  // Center to center
    static let smallPontoonSpacing = 24.0  // Center to center
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
        // Main cylinder body
        Cylinder(diameter: diameter, height: straightLength)
            .aligned(at: .centerXY, .minZ)
        
        // Nosecone (if present)
        if hasNosecone {
            Loft {
                layer(z: straightLength) {
                    Circle(diameter: diameter)
                }
                layer(z: straightLength + noseconeLength) {
                    Circle(diameter: diameter * 0.3)  // Tapered nose
                }
            }
        }
        
        // Rear cap (hemisphere or flat)
        Sphere(diameter: diameter)
            .intersecting {
                Box(diameter, diameter, diameter / 2)
                    .aligned(at: .centerXY, .minZ)
            }
            .rotated(x: 180°)
    }
}

struct HatChannel: Shape3D {
    let length: Double
    
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Create hat channel cross-section
        let profile = Rectangle(x: d.hatChannelWidth, y: d.hatChannelHeight)
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
                // Bottom flanges with return lips
                Rectangle(x: d.hatChannelFlangeWidth, y: d.hatChannelWall)
                    .aligned(at: .maxX, .minY)
                    .translated(x: -d.hatChannelWidth / 2)
                Rectangle(x: d.hatChannelFlangeWidth, y: d.hatChannelWall)
                    .aligned(at: .minX, .minY)
                    .translated(x: d.hatChannelWidth / 2)
            }
        
        profile
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
        // Vertical sides
        Box(x: thickness, y: width, z: height)
            .translated(x: width / 2 - thickness / 2)
        Box(x: thickness, y: width, z: height)
            .translated(x: -width / 2 + thickness / 2)
        
        // Top plate
        Box(x: width, y: width, z: thickness)
            .translated(z: height - thickness)
    }
}

// MARK: - Full Boat Assembly

struct PontoonBoat: Shape3D {
    var body: any Geometry3D {
        let d = BoatDimensions.self
        
        // Main 27" pontoons (port and starboard)
        Group {
            // Port main pontoon
            Pontoon(
                diameter: d.mainPontoonDiameter,
                straightLength: d.mainPontoonLength,
                hasNosecone: true,
                noseconeLength: 36
            )
            .rotated(x: -90°)
            .translated(y: d.mainPontoonSpacing / 2)
            
            // Starboard main pontoon
            Pontoon(
                diameter: d.mainPontoonDiameter,
                straightLength: d.mainPontoonLength,
                hasNosecone: true,
                noseconeLength: 36
            )
            .rotated(x: -90°)
            .translated(y: -d.mainPontoonSpacing / 2)
        }
        .colored(.orange)
        
        // Middle 18" pontoons (2 sets: straight + nosecone each)
        Group {
            for side in [-1.0, 1.0] {
                // Straight section
                Pontoon(
                    diameter: d.smallPontoonDiameter,
                    straightLength: d.smallPontoonStraightLength
                )
                .rotated(x: -90°)
                .translated(
                    x: 48,  // Position along length
                    y: side * d.smallPontoonSpacing / 2
                )
                
                // Nosecone section (forward)
                Pontoon(
                    diameter: d.smallPontoonDiameter,
                    straightLength: d.smallPontoonStraightLength,
                    hasNosecone: true,
                    noseconeLength: d.smallPontoonNoseconeLength
                )
                .rotated(x: -90°)
                .translated(
                    x: 48 + d.smallPontoonStraightLength,
                    y: side * d.smallPontoonSpacing / 2
                )
            }
        }
        .colored(.orange)
        
        // Front 18" pontoons (new addition - your upgrade)
        Group {
            for side in [-1.0, 1.0] {
                // Straight + nosecone
                Pontoon(
                    diameter: d.smallPontoonDiameter,
                    straightLength: d.smallPontoonStraightLength,
                    hasNosecone: true,
                    noseconeLength: d.smallPontoonNoseconeLength
                )
                .rotated(x: -90°)
                .translated(
                    x: d.mainPontoonLength - 24,  // Forward position
                    y: side * d.smallPontoonSpacing / 2
                )
            }
        }
        .colored(.orange)
        
        // Hat channel crossmembers for front pontoons
        Group {
            for i in 0..<4 {
                HatChannel(length: d.smallPontoonSpacing)
                    .translated(
                        x: d.mainPontoonLength - 24 + Double(i) * d.crossmemberSpacing,
                        z: d.smallPontoonDiameter / 2 + d.hatChannelHeight
                    )
            }
        }
        .colored(.gray)
        
        // C-brackets (connecting hat channels to tow plate/crossmembers)
        Group {
            for i in 0..<4 {
                CBracket()
                    .translated(
                        x: d.mainPontoonLength - 24 + Double(i) * d.crossmemberSpacing,
                        z: d.smallPontoonDiameter / 2 + d.hatChannelHeight
                    )
            }
        }
        .colored(.lightGray)
        
        // Main crossmembers (simplified)
        Group {
            for i in 0..<8 {
                Box(x: 2, y: d.mainPontoonSpacing, z: 3)
                    .aligned(at: .centerXY, .minZ)
                    .translated(
                        x: Double(i) * 18,
                        z: d.mainPontoonDiameter / 2 + 2
                    )
            }
        }
        .colored(.gray)
        
        // Tow plate (center fore-aft beam)
        Box(x: 38, y: 3, z: 0.375)
            .aligned(at: .minX, .centerY, .minZ)
            .translated(
                x: d.mainPontoonLength - 60,
                z: d.mainPontoonDiameter / 2 + 5
            )
            .colored(.darkGray)
    }
}

// MARK: - Main

@main
struct WeaselToonCadova {
    static func main() async throws {
        await Model("pontoon-boat") {
            PontoonBoat()
        }
    }
}

