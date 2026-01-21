# Plotter 60x50 SelfColor V4

## About
This Processing sketch is a powerful tool designed to convert SVG vector images into GCODE for a large-format drawing plotter (60x50cm). It is specifically tailored for artistic applications, offering advanced color management and sophisticated hatching algorithms to create pen/brush plot drawings. The system handles complex geometries, ensuring that filled regions respect inner boundaries (holes, nested shapes) for a natural and precise artistic result.

## Key Features

*   **SVG Import**: Seamlessly loads SVG files, analyzing shapes and extracting color information using the Geomerative library.
*   **Color Management**: Automatically separates shapes by color, facilitating automatic or manual pen/brush changes during the plotting process.
*   **Advanced Hatching (Fill Algorithms)**:
    *   **Linear Hatching**: Classic parallel line fill with customizable angles.
    *   **Smart Concentric Hatching**: Contour-following fill that offsets inwards from the shape boundary.
        *   **Inner Shape Awareness**: Automatically detects and respects inner shapes (e.g., eyes in a face, mouths, holes). The concentric fill "flows around" these inner details rather than covering them, preserving the integrity of the image.
*   **Geometry Optimization**:
    *   **Vertex Sanitization**: Proactively cleans geometry data to prevent topological errors (e.g., removing NaN coordinates).
    *   **Auto-Correction**: Automatically closes open paths and repairs malformed shapes before processing them with JTS/PGS geometry engines.
*   **GCODE Generation**: Exports optimized GCODE instructions, including Z-axis movements (pen up/down), tool change protocols, and brush cleaning/refilling paths.
*   **Preview & Estimation**: Provides a real-time on-screen visualization of the toolpath and an accurate estimation of the execution time.

## Requirements

To run this sketch, the following Processing libraries are required:
*   **Geomerative**: For parsing and manipulating SVG vector data.
*   **PGS (Processing Geometry Suite)**: For advanced geometric operations (buffering, boolean operations, JTS conversions).

## Latest Updates

*   **Concentric Hatching Fix**: Resolved issues where concentric fills would overlap inner shapes (e.g., irises, mouths). The algorithm now correctly subtracts contained shapes before generating the concentric lines.
*   **Enhanced Robustness**: Added safeguards against `TopologyException` and implemented proactive `PShape` sanitization to prevent crashes when processing complex or imperfect SVG files.

## Usage

1.  Open the sketch in the Processing IDE.
2.  Run the sketch.
3.  Select an `.svg` file from the file dialog.
4.  Wait for the processing to complete (progress is shown in the console).
5.  The generated GCODE file will be saved in the `GCODE/` subdirectory, along with a PNG preview of the result.
