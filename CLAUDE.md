# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WeaselToonCadova is a Swift-based 3D CAD project using the [Cadova](https://github.com/tomasf/Cadova) framework to programmatically model a pontoon boat. The project translates a manually-designed Fusion 360 CAD model into Swift code that generates 3MF files.

## Build Commands

```bash
swift build                    # Compile the package
swift build -c release         # Optimized release build
swift run WeaselToonCadova     # Generate 3MF from original target
swift run WeaselToon2          # Generate 3MF files from newer target
```

Requires Swift 6.2+ and macOS 14+. Uses C++ interop mode for the Manifold geometry library.

## Architecture

**Two executable targets:**
- `WeaselToonCadova` - Original implementation in `Sources/WeaselToonCadova/WeaselToonCadova.swift`
- `WeaselToon2` - Refined approach in `Sources/WeaselToon2/main.swift` with better organization

**Code patterns:**
- All dimensions centralized in a `Dims` struct with nested sub-structs by component type
- Dimensions are in inches (matching TinyPontoonBoats kit specs)
- Geometry components conform to Cadova's `Shape3D` protocol
- Functions return `any Geometry3D` for composable CSG operations
- Output is 3MF format for viewing in Cadova Viewer, Bambu Studio, or Fusion 360

**Key Cadova concepts used:**
- `Loft` with layers for complex curved shapes (nose cones)
- `Extrude` for linear profiles (hat channels, tubes)
- CSG operations: `subtracting()`, `adding()`, union via closures
- Transforms: `translated()`, `rotated()`, `scaled()`

## Development Workflow

1. Edit Swift code
2. Run `swift run WeaselToon2` (or other target)
3. View generated 3MF in [Cadova Viewer](https://github.com/tomasf/CadovaViewer)
4. Iterate on dimensions/geometry

## Key Dependencies

- **Cadova 0.4.x** - CAD framework providing Shape3D, geometry operations, 3MF export
- **Manifold-swift** - Underlying 3D geometry engine (handles mesh operations)
