# Pontoon Boat 3D Model - Cadova Swift CAD

This project creates a parametric 3D model of an 8' x 15' pontoon boat using [Cadova](https://github.com/tomasf/Cadova), a Swift DSL for 3D modeling.

## Boat Specifications

Based on [TinyPontoonBoats.com](https://www.tinypontoonboats.com/) specifications:

- **Overall Size**: 8' wide × 15' long (96" × 180")
- **Main Pontoons**: 2× 27" diameter HDPE plastic floats
  - 4 straight sections (36" each) + 1 nose cone (35.4") per pontoon
  - Rated capacity: ~330 lbs per straight section
- **Auxiliary Pontoons**: 4× 18" diameter (custom upgrade)
  - 2 on each side, mounted underneath for extra buoyancy
  - Each with 1-2 straight sections + nose cone
- **Frame**: 6061 aluminum hat channels and T-extrusions
  - 2" tall hat channel crossmembers
  - T-shaped main beams running the length of each pontoon

## Building the Model

### Prerequisites

- macOS 14+ (or Linux/Windows with Swift 6.1+)
- Swift 6.1 toolchain installed
- Xcode 16+ (on macOS)

### Build Commands

```bash
# Navigate to project directory
cd PontoonBoat

# Build the project
swift build

# Run to generate 3MF files
swift run
```

### Output Files

The following 3MF files will be generated:

| File | Description |
|------|-------------|
| `pontoon-boat-complete.3mf` | Full boat assembly |
| `pontoon-27-nosecone.3mf` | 27" nose cone component |
| `pontoon-27-straight.3mf` | 27" straight section |
| `pontoon-18-nosecone.3mf` | 18" auxiliary nose cone |
| `pontoon-18-straight.3mf` | 18" auxiliary straight section |
| `hat-channel.3mf` | Hat channel crossmember |
| `frame-assembly.3mf` | Complete frame only |
| `main-pontoon-assembly.3mf` | Single main pontoon |
| `aux-pontoon-assembly.3mf` | Single auxiliary pontoon |

## Viewing the Models

Use [Cadova Viewer](https://github.com/tomasf/CadovaViewer) on macOS, or any 3MF compatible viewer:
- Bambu Studio
- PrusaSlicer
- Microsoft 3D Viewer
- Most 3D printing slicers

## Customization

Edit `Sources/main.swift` to modify dimensions in the `PontoonDimensions` struct:

```swift
struct PontoonDimensions {
    static let boatWidth: Double = 96.0      // 8 feet
    static let boatLength: Double = 180.0    // 15 feet
    // ... etc
}
```

## Project Structure

```
PontoonBoat/
├── Package.swift           # Swift package manifest
├── Sources/
│   └── main.swift          # Main model definitions
└── README.md               # This file
```

## References

- [TinyPontoonBoats.com - Pontoons](https://www.tinypontoonboats.com/pontoons/)
- [TinyPontoonBoats.com - Accessories](https://www.tinypontoonboats.com/accessories/)
- [27" Frame Assembly Instructions](https://www.tinypontoonboats.com/assembly/frames/27sn/)
- [Cadova Documentation](https://github.com/tomasf/Cadova/wiki)

## License

This model is for personal use. The TinyPontoonBoats design is patented.