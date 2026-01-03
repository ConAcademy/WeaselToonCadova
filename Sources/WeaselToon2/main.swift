import Cadova
import Foundation

// =============================================================================
// MARK: - Dimensions (in inches - matching TinyPontoonBoats specs)
// =============================================================================

struct Dims {
    // Overall boat
    static let boatWidth: Double = 96.0      // 8 feet
    static let boatLength: Double = 180.0    // 15 feet
    
    // Main 27" pontoons
    struct Main {
        static let diameter: Double = 27.0
        static let noseConeLength: Double = 35.4
        static let straightLength: Double = 36.0
        static let straightsPerPontoon: Int = 4  // 4 straights for 15' boat
        static let boltHoleDiameter: Double = 0.5
        static let channelWidth: Double = 1.5    // Dual channels on top
        static let channelSpacing: Double = 9.0  // ~12" center to center
    }
    
    // Auxiliary 18" pontoons (4 total in center)
    struct Aux {
        static let diameter: Double = 18.0
        static let noseConeLength: Double = 24.0
        static let straightLength: Double = 36.0
        static let straightsPerPontoon: Int = 2  // Shorter assemblies
        static let boltHoleDiameter: Double = 0.375
    }
    
    // Frame - Main beams (T-extrusion that sits in pontoon channels)
    struct MainBeam {
        static let width: Double = 2.5
        static let height: Double = 2.0
        static let flangeThickness: Double = 0.25
    }
    
    // Frame - Hat channel crossmembers
    struct HatChannel {
        static let height: Double = 2.0
        static let topWidth: Double = 2.0
        static let bottomWidth: Double = 3.5
        static let flangeWidth: Double = 1.25
        static let thickness: Double = 0.125
        static let length: Double = 95.75
    }
    
    // Frame - Square tube (front crossmember)
    struct SquareTube {
        static let size: Double = 2.0
        static let wall: Double = 0.125
    }
    
    // Spacing
    static let mainPontoonCenterToCenter: Double = 74.0  // For 8' wide boat
    static let crossmemberCount: Int = 9  // Including front tube
    
    // Motor mount / transom area
    struct Transom {
        static let width: Double = 24.0
        static let height: Double = 14.0
        static let depth: Double = 3.0
    }
}

// =============================================================================
// MARK: - Pontoon Float Components
// =============================================================================

/// Creates a pontoon nose cone with realistic bulbous shape
func noseCone(diameter: Double, length: Double) -> any Geometry3D {
    // The TPB nose cones have a distinctive bulbous shape that tapers to a point
    Loft(interpolation: .smootherstep) {
        // Back (blunt end with strengthening recess)
        layer(z: 0) {
            Circle(diameter: diameter)
        }
        // Slight bulge
        layer(z: length * 0.15) {
            Circle(diameter: diameter * 1.02)
        }
        // Main body taper begins
        layer(z: length * 0.40) {
            Circle(diameter: diameter * 0.90)
        }
        // More aggressive taper
        layer(z: length * 0.65) {
            Circle(diameter: diameter * 0.65)
        }
        // Near tip
        layer(z: length * 0.85) {
            Circle(diameter: diameter * 0.35)
        }
        // Rounded tip
        layer(z: length * 0.95) {
            Circle(diameter: diameter * 0.15)
        }
        // Close to point
        layer(z: length) {
            Circle(diameter: 0.5)  // Slightly rounded tip
        }
    }
    .colored(.orange)
}

/// Creates a pontoon straight section cylinder
func straightSection(diameter: Double, length: Double) -> any Geometry3D {
    // Main cylinder body with reinforcement ribs
    let ribSpacing: Double = 6.0
    let ribCount = Int(length / ribSpacing)
    
    // Start with main cylinder
    var result: any Geometry3D = Cylinder(diameter: diameter, height: length)
        .rotated(x: -90°)
        .colored(.orange)
    
    // Add reinforcement ribs (subtle visual detail)
    for i in 1..<ribCount {
        let ribPos = Double(i) * ribSpacing
        let rib = Ring(outerDiameter: diameter + 0.3, innerDiameter: diameter - 0.1)
            .extruded(height: 0.5)
            .rotated(x: -90°)
            .translated(y: ribPos)
            .colored(.orange)
        result = result.adding { rib }
    }
    
    return result
}

/// Creates a complete pontoon assembly with nose cone and straights
func pontoonAssembly(
    diameter: Double,
    noseConeLength: Double,
    straightLength: Double,
    straightCount: Int,
    hasFrontNose: Bool = true,
    hasRearNose: Bool = false
) -> any Geometry3D {
    // Start building the pontoon
    var result: any Geometry3D = Box(0.001)  // Dummy starting point
    var isFirst = true
    
    // Rear nose cone (if applicable)
    if hasRearNose {
        let rearNose = noseCone(diameter: diameter, length: noseConeLength)
            .rotated(x: -90°)  // Point backward
        if isFirst {
            result = rearNose
            isFirst = false
        } else {
            result = result.adding { rearNose }
        }
    }
    
    // Straight sections
    for i in 0..<straightCount {
        let yOffset = hasRearNose ? noseConeLength + Double(i) * straightLength : Double(i) * straightLength
        let straight = straightSection(diameter: diameter, length: straightLength)
            .translated(y: yOffset)
        if isFirst {
            result = straight
            isFirst = false
        } else {
            result = result.adding { straight }
        }
    }
    
    // Front nose cone
    if hasFrontNose {
        let frontYOffset = hasRearNose 
            ? noseConeLength + Double(straightCount) * straightLength 
            : Double(straightCount) * straightLength
        let frontNose = noseCone(diameter: diameter, length: noseConeLength)
            .rotated(x: 90°)  // Point forward
            .translated(y: frontYOffset)
        result = result.adding { frontNose }
    }
    
    return result
}

/// Main 27" pontoon (double-nose configuration for 15' boat)
func main27Pontoon() -> any Geometry3D {
    pontoonAssembly(
        diameter: Dims.Main.diameter,
        noseConeLength: Dims.Main.noseConeLength,
        straightLength: Dims.Main.straightLength,
        straightCount: Dims.Main.straightsPerPontoon,
        hasFrontNose: true,
        hasRearNose: true
    )
}

/// Auxiliary 18" pontoon (double-nose configuration)
func aux18Pontoon() -> any Geometry3D {
    pontoonAssembly(
        diameter: Dims.Aux.diameter,
        noseConeLength: Dims.Aux.noseConeLength,
        straightLength: Dims.Aux.straightLength,
        straightCount: Dims.Aux.straightsPerPontoon,
        hasFrontNose: true,
        hasRearNose: true  // Both ends have nose cones
    )
}

// =============================================================================
// MARK: - Frame Components
// =============================================================================

/// Main beam T-extrusion profile (cross-section)
func mainBeamProfile() -> any Geometry2D {
    let w = Dims.MainBeam.width
    let h = Dims.MainBeam.height
    let t = Dims.MainBeam.flangeThickness
    
    // T-beam: vertical stem with horizontal top flange
    return Rectangle(x: t * 2, y: h)
        .aligned(at: .centerX, .bottom)
        .adding {
            // Top flange
            Rectangle(x: w, y: t)
                .aligned(at: .centerX, .maxY)
                .translated(y: h - t)
        }
}

/// Hat channel profile (cross-section) - trapezoidal with flanges
func hatChannelProfile() -> any Geometry2D {
    let h = Dims.HatChannel.height
    let topW = Dims.HatChannel.topWidth
    let botW = Dims.HatChannel.bottomWidth
    let flangeW = Dims.HatChannel.flangeWidth
    let t = Dims.HatChannel.thickness

    // Outer trapezoidal shape (wider at bottom)
    let outer = Polygon([
        [-topW/2, h],           // top left
        [topW/2, h],            // top right
        [botW/2, 0],            // bottom right (wider)
        [botW/2 + flangeW, 0],  // right flange outer
        [botW/2 + flangeW, t],  // right flange top
        [botW/2, t],            // right flange inner
        [(topW/2 - t), h - t],  // inner top right
        [-(topW/2 - t), h - t], // inner top left
        [-(botW/2 - t), t],     // inner bottom left
        [-botW/2, t],           // left flange inner
        [-botW/2 - flangeW, t], // left flange top
        [-botW/2 - flangeW, 0], // left flange outer
        [-botW/2, 0],           // bottom left (wider)
    ])

    return outer
}

/// Hat channel crossmember (full 3D)
func hatChannel(length: Double = Dims.HatChannel.length) -> any Geometry3D {
    hatChannelProfile()
        .extruded(height: length)
        .rotated(y: 90°)
        .rotated(z: 180°)
        .translated(x: length/2)
        .withMaterial(.steel)
}

/// Square tube (front crossmember)
func squareTube(length: Double) -> any Geometry3D {
    let size = Dims.SquareTube.size
    let wall = Dims.SquareTube.wall
    
    return Rectangle(x: size, y: size)
        .aligned(at: .center)
        .subtracting {
            Rectangle(x: size - 2*wall, y: size - 2*wall)
                .aligned(at: .center)
        }
        .extruded(height: length)
        .rotated(y: 90°)
        .translated(x: length/2)
        .withMaterial(.steel)
}

/// Main beam extrusion
func mainBeam(length: Double) -> any Geometry3D {
    mainBeamProfile()
        .extruded(height: length)
        .rotated(x: -90°)
        .withMaterial(.steel)
}

// =============================================================================
// MARK: - Complete Assemblies
// =============================================================================

/// Frame assembly - main beams and crossmembers
func frameAssembly() -> any Geometry3D {
    let length = Dims.boatLength
    let spacing = Dims.mainPontoonCenterToCenter
    let mainDia = Dims.Main.diameter
    let beamH = Dims.MainBeam.height
    
    // Frame sits on top of pontoons
    let frameZ = mainDia/2 + beamH/2
    
    // Crossmember positions (evenly distributed)
    let crossmemberSpacing = length / Double(Dims.crossmemberCount)
    let channelOffset = Dims.Main.channelSpacing / 2
    
    // Start with port side main beams
    var result: any Geometry3D = mainBeam(length: length)
        .translated(x: -spacing/2 - channelOffset, z: frameZ)
    
    result = result.adding {
        mainBeam(length: length)
            .translated(x: -spacing/2 + channelOffset, z: frameZ)
    }
    
    // Starboard side main beams
    result = result.adding {
        mainBeam(length: length)
            .translated(x: spacing/2 - channelOffset, z: frameZ)
    }
    
    result = result.adding {
        mainBeam(length: length)
            .translated(x: spacing/2 + channelOffset, z: frameZ)
    }
    
    // Front square tube crossmember
    result = result.adding {
        squareTube(length: spacing + 10)
            .translated(x: -spacing/2 - 5, y: length - 2, z: frameZ + beamH)
    }
    
    // Hat channel crossmembers
    for i in 0..<Dims.crossmemberCount {
        let yPos = 3.0 + Double(i) * crossmemberSpacing
        result = result.adding {
            hatChannel(length: spacing + 10)
                .translated(x: -spacing/2 - 5, y: yPos, z: frameZ + beamH)
        }
    }
    
    return result
}

/// Motor mount / transom bracket (simplified)
func transomBracket() -> any Geometry3D {
    let w = Dims.Transom.width
    let h = Dims.Transom.height
    let d = Dims.Transom.depth
    
    // Simple L-bracket shape for motor mount
    return Box(x: w, y: d, z: h)
        .aligned(at: .centerX, .minY, .minZ)
        .withMaterial(.steel)
}

/// Complete pontoon boat assembly
func pontoonBoatComplete() -> any Geometry3D {
    let mainDia = Dims.Main.diameter
    let auxDia = Dims.Aux.diameter
    let spacing = Dims.mainPontoonCenterToCenter
    
    // Aux pontoon positions - arranged in a 2x2 pattern in the center
    let auxXSpacing: Double = 22.0  // Horizontal spacing between aux pontoon pairs
    let auxYFront: Double = 50.0    // Y position of front aux pair
    let auxYRear: Double = 120.0    // Y position of rear aux pair
    
    // Aux pontoons sit lower than main pontoons
    let auxZ = mainDia/2 - auxDia/2 - 5.0
    
    // Start with port main pontoon
    var result: any Geometry3D = main27Pontoon()
        .translated(x: -spacing/2, z: mainDia/2)
    
    // Starboard main pontoon
    result = result.adding {
        main27Pontoon()
            .translated(x: spacing/2, z: mainDia/2)
    }
    
    // === AUXILIARY PONTOONS (4 total in center) ===
    // Front pair
    result = result.adding {
        aux18Pontoon()
            .translated(x: -auxXSpacing/2, y: auxYFront - 40, z: auxZ)
    }
    
    result = result.adding {
        aux18Pontoon()
            .translated(x: auxXSpacing/2, y: auxYFront - 40, z: auxZ)
    }
    
    // Rear pair (rotated to face backward)
    result = result.adding {
        aux18Pontoon()
            .rotated(z: 180°)
            .translated(x: -auxXSpacing/2, y: auxYRear + 60, z: auxZ)
    }
    
    result = result.adding {
        aux18Pontoon()
            .rotated(z: 180°)
            .translated(x: auxXSpacing/2, y: auxYRear + 60, z: auxZ)
    }
    
    // Frame assembly
    result = result.adding {
        frameAssembly()
    }
    
    // Transom / motor mount
    result = result.adding {
        transomBracket()
            .translated(y: 5, z: mainDia/2 + Dims.MainBeam.height + 2)
    }
    
    return result
}

// =============================================================================
// MARK: - Individual Part Exports
// =============================================================================

func exportNoseCone27() -> any Geometry3D {
    noseCone(diameter: Dims.Main.diameter, length: Dims.Main.noseConeLength)
        .rotated(x: -90°)
        .aligned(at: .centerX, .minY, .minZ)
}

func exportStraight27() -> any Geometry3D {
    straightSection(diameter: Dims.Main.diameter, length: Dims.Main.straightLength)
        .aligned(at: .centerX, .minY, .minZ)
}

func exportNoseCone18() -> any Geometry3D {
    noseCone(diameter: Dims.Aux.diameter, length: Dims.Aux.noseConeLength)
        .rotated(x: -90°)
        .aligned(at: .centerX, .minY, .minZ)
}

func exportStraight18() -> any Geometry3D {
    straightSection(diameter: Dims.Aux.diameter, length: Dims.Aux.straightLength)
        .aligned(at: .centerX, .minY, .minZ)
}

func exportHatChannel() -> any Geometry3D {
    hatChannel()
        .aligned(at: .centerX, .centerY, .minZ)
}

func exportMainPontoon() -> any Geometry3D {
    main27Pontoon()
        .aligned(at: .centerX, .minY, .minZ)
}

func exportAuxPontoon() -> any Geometry3D {
    aux18Pontoon()
        .aligned(at: .centerX, .minY, .minZ)
}

// =============================================================================
// MARK: - Main Entry Point
// =============================================================================

@main
struct PontoonBoatApp {
    static func main() async throws {
        print(String(repeating: "=", count: 60))
        print("Pontoon Boat 3D Model Generator")
        print(String(repeating: "=", count: 60))
        print("")
        print("Boat Specifications:")
        print("  Overall: 8' x 15' (96\" x 180\")")
        print("  Main pontoons: 27\" diameter (2x)")
        print("  Aux pontoons: 18\" diameter (4x)")
        print("")
        print("Generating 3MF files...")
        print("")
        
        // Complete boat assembly
        print("  → pontoon-boat-complete.3mf")
        await Model("pontoon-boat-complete") {
            pontoonBoatComplete()
        }
        
        // Frame only
        print("  → frame-assembly.3mf")
        await Model("frame-assembly") {
            frameAssembly()
        }
        
        // Individual components
        print("  → 27-nosecone.3mf")
        await Model("27-nosecone") {
            exportNoseCone27()
        }
        
        print("  → 27-straight.3mf")
        await Model("27-straight") {
            exportStraight27()
        }
        
        print("  → 18-nosecone.3mf")
        await Model("18-nosecone") {
            exportNoseCone18()
        }
        
        print("  → 18-straight.3mf")
        await Model("18-straight") {
            exportStraight18()
        }
        
        print("  → hat-channel.3mf")
        await Model("hat-channel") {
            exportHatChannel()
        }
        
        print("  → main-pontoon.3mf")
        await Model("main-pontoon") {
            exportMainPontoon()
        }
        
        print("  → aux-pontoon.3mf")
        await Model("aux-pontoon") {
            exportAuxPontoon()
        }
        
        print("")
        print(String(repeating: "=", count: 60))
        print("Done! View .3mf files in Cadova Viewer or Bambu Studio")
        print(String(repeating: "=", count: 60))
    }
}