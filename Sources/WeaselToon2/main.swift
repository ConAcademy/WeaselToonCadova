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
        static let straightsPerPontoon: Int = 1  // Short assemblies: 1 straight + 2 nose cones
        static let boltHoleDiameter: Double = 0.375
    }
    
    // Frame - Main beams (T-extrusion that sits in pontoon channels)
    struct MainBeam {
        static let flangeWidth: Double = 2.5    // Top flange width
        static let stemWidth: Double = 1.25     // Stem fits in 1.5" channel
        static let height: Double = 2.0         // Total height
        static let flangeThickness: Double = 0.25
        static let stemHeight: Double = 1.0     // How deep stem goes into channel
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

/// Creates a pontoon straight section cylinder with top channels
func straightSection(
    diameter: Double,
    length: Double,
    channelCount: Int = 1,
    channelSpacing: Double = 0.0
) -> any Geometry3D {
    let channelWidth: Double = 1.5
    let channelDepth: Double = 0.75

    // Main cylinder body with reinforcement ribs
    let ribSpacing: Double = 6.0
    let ribCount = Int(length / ribSpacing)

    // Start with main cylinder
    var result: any Geometry3D = Cylinder(diameter: diameter, height: length)
        .rotated(x: -90°)
        .colored(.orange)

    // Cut channels into top of pontoon
    if channelCount == 1 {
        // Single center channel
        let channel = Box(x: channelWidth, y: length + 2, z: channelDepth)
            .translated(z: diameter/2 - channelDepth/2)
            .translated(y: length/2 - 1)
        result = result.subtracting { channel }
    } else if channelCount == 2 {
        // Dual channels for 27" pontoons
        let leftChannel = Box(x: channelWidth, y: length + 2, z: channelDepth)
            .translated(x: -channelSpacing/2, z: diameter/2 - channelDepth/2)
            .translated(y: length/2 - 1)
        let rightChannel = Box(x: channelWidth, y: length + 2, z: channelDepth)
            .translated(x: channelSpacing/2, z: diameter/2 - channelDepth/2)
            .translated(y: length/2 - 1)
        result = result.subtracting { leftChannel }
        result = result.subtracting { rightChannel }
    }

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
    hasRearNose: Bool = false,
    channelCount: Int = 1,
    channelSpacing: Double = 0.0
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

    // Straight sections with top channels
    for i in 0..<straightCount {
        let yOffset = hasRearNose ? noseConeLength + Double(i) * straightLength : Double(i) * straightLength
        let straight = straightSection(
            diameter: diameter,
            length: straightLength,
            channelCount: channelCount,
            channelSpacing: channelSpacing
        ).translated(y: yOffset)
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
/// Has TWO top channels for frame mounting
func main27Pontoon() -> any Geometry3D {
    pontoonAssembly(
        diameter: Dims.Main.diameter,
        noseConeLength: Dims.Main.noseConeLength,
        straightLength: Dims.Main.straightLength,
        straightCount: Dims.Main.straightsPerPontoon,
        hasFrontNose: true,
        hasRearNose: true,
        channelCount: 2,
        channelSpacing: Dims.Main.channelSpacing
    )
}

/// Auxiliary 18" pontoon (double-nose configuration)
/// Has ONE top channel for frame mounting
func aux18Pontoon() -> any Geometry3D {
    pontoonAssembly(
        diameter: Dims.Aux.diameter,
        noseConeLength: Dims.Aux.noseConeLength,
        straightLength: Dims.Aux.straightLength,
        straightCount: Dims.Aux.straightsPerPontoon,
        hasFrontNose: true,
        hasRearNose: true,
        channelCount: 1,
        channelSpacing: 0.0
    )
}

// =============================================================================
// MARK: - Frame Components
// =============================================================================

/// Main beam T-extrusion profile (cross-section)
/// T-shaped: wide flange on top, narrower stem below that fits in pontoon channel
func mainBeamProfile() -> any Geometry2D {
    let flangeW = Dims.MainBeam.flangeWidth
    let stemW = Dims.MainBeam.stemWidth
    let flangeT = Dims.MainBeam.flangeThickness
    let stemH = Dims.MainBeam.stemHeight

    // T-beam: vertical stem with horizontal top flange
    return Rectangle(x: stemW, y: stemH)
        .aligned(at: .centerX, .bottom)
        .adding {
            // Top flange (wider, sits on pontoon surface)
            Rectangle(x: flangeW, y: flangeT)
                .aligned(at: .centerX, .bottom)
                .translated(y: stemH)
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

/// C-bracket that wraps around pontoon and connects to frame
/// These secure the pontoons to the crossmembers
func cBracket(pontoonDiameter: Double) -> any Geometry3D {
    let thickness: Double = 0.125  // 1/8" steel
    let width: Double = 2.0        // Width of the bracket
    let wrapAngle: Double = 180.0  // Wraps halfway around pontoon
    let tabHeight: Double = 2.0    // Height of mounting tabs
    let tabWidth: Double = 1.5     // Width of mounting tabs

    let innerRadius = pontoonDiameter / 2
    let outerRadius = innerRadius + thickness

    // U-shaped wrap around pontoon
    let wrap = Circle(diameter: outerRadius * 2)
        .subtracting {
            Circle(diameter: innerRadius * 2)
        }
        .subtracting {
            // Cut off top half to make U-shape
            Rectangle(x: outerRadius * 3, y: outerRadius * 2)
                .translated(y: outerRadius)
        }
        .extruded(height: width)
        .translated(z: -width/2)

    // Mounting tabs on each side
    let leftTab = Box(x: thickness, y: tabHeight, z: tabWidth)
        .translated(x: -innerRadius - thickness/2, y: tabHeight/2, z: 0)

    let rightTab = Box(x: thickness, y: tabHeight, z: tabWidth)
        .translated(x: innerRadius + thickness/2, y: tabHeight/2, z: 0)

    return wrap
        .adding { leftTab }
        .adding { rightTab }
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
    let beamTotalH = Dims.MainBeam.stemHeight + Dims.MainBeam.flangeThickness
    let channelDepth: Double = 0.75  // How deep channels are cut into pontoon

    // Main beams sit in channels - flange on pontoon surface, stem in channel
    let beamZ = mainDia/2 - channelDepth  // Bottom of stem in channel

    // Crossmember positions (evenly distributed)
    let crossmemberSpacing = length / Double(Dims.crossmemberCount)
    let channelOffset = Dims.Main.channelSpacing / 2

    // Start with port side main beams
    var result: any Geometry3D = mainBeam(length: length)
        .translated(x: -spacing/2 - channelOffset, z: beamZ)

    result = result.adding {
        mainBeam(length: length)
            .translated(x: -spacing/2 + channelOffset, z: beamZ)
    }

    // Starboard side main beams
    result = result.adding {
        mainBeam(length: length)
            .translated(x: spacing/2 - channelOffset, z: beamZ)
    }

    result = result.adding {
        mainBeam(length: length)
            .translated(x: spacing/2 + channelOffset, z: beamZ)
    }

    // Crossmembers sit on top of main beams (on the flange)
    let crossmemberZ = beamZ + beamTotalH

    // Front square tube crossmember
    result = result.adding {
        squareTube(length: spacing + 10)
            .translated(x: -spacing/2 - 5, y: length - 2, z: crossmemberZ)
    }

    // Hat channel crossmembers with C-brackets
    for i in 0..<Dims.crossmemberCount {
        let yPos = 3.0 + Double(i) * crossmemberSpacing
        result = result.adding {
            hatChannel(length: spacing + 10)
                .translated(x: -spacing/2 - 5, y: yPos, z: crossmemberZ)
        }

        // C-brackets at each crossmember on both main pontoons
        // Port side bracket
        result = result.adding {
            cBracket(pontoonDiameter: mainDia)
                .rotated(x: 90°)
                .translated(x: -spacing/2, y: yPos, z: mainDia/2)
        }
        // Starboard side bracket
        result = result.adding {
            cBracket(pontoonDiameter: mainDia)
                .rotated(x: 90°)
                .translated(x: spacing/2, y: yPos, z: mainDia/2)
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
    // Aux pontoon length: 24 (nose) + 36 (straight) + 24 (nose) = 84"
    let auxLength: Double = Dims.Aux.noseConeLength * 2 + Dims.Aux.straightLength * Double(Dims.Aux.straightsPerPontoon)
    let auxXSpacing: Double = 30.0  // Horizontal spacing between aux pontoon pairs (wider)

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

    // === AUXILIARY PONTOONS (4 total in 2x2 pattern) ===
    // Rear pair - near stern, nose cones pointing backward
    // Position so rear nose cone is around y=20
    let rearPairY: Double = 20.0
    result = result.adding {
        aux18Pontoon()
            .translated(x: -auxXSpacing/2, y: rearPairY, z: auxZ)
    }
    result = result.adding {
        aux18Pontoon()
            .translated(x: auxXSpacing/2, y: rearPairY, z: auxZ)
    }

    // Front pair - toward bow, nose cones pointing forward
    // Position so front tip is around y=170
    let frontPairY: Double = 170.0 - auxLength
    result = result.adding {
        aux18Pontoon()
            .translated(x: -auxXSpacing/2, y: frontPairY, z: auxZ)
    }
    result = result.adding {
        aux18Pontoon()
            .translated(x: auxXSpacing/2, y: frontPairY, z: auxZ)
    }
    
    // Frame assembly
    result = result.adding {
        frameAssembly()
    }
    
    // Transom / motor mount - sits at the stern, on top of frame
    let transomZ = mainDia/2 + Dims.MainBeam.stemHeight + Dims.MainBeam.flangeThickness + 2
    result = result.adding {
        transomBracket()
            .translated(y: 5, z: transomZ)
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