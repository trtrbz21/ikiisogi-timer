// Renders the app icon ("A: ring") into the asset catalog.
//
//   swift Tools/generate-app-icon.swift
//
// Produces the three iOS 18+ appearances:
//   AppIcon.png        default (light) — opaque, no alpha channel (required by App Store)
//   AppIcon-Dark.png   dark — transparent background so the system draws its dark backdrop
//   AppIcon-Tinted.png tinted — grayscale, the system applies the user's tint color

import AppKit
import SwiftUI

let size = 1024
let outputDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("IkiisogiTimer/Assets.xcassets/AppIcon.appiconset")

/// Share of the ring still remaining. Reads as "time is running out" without being empty.
let remaining: CGFloat = 0.27
let ringDiameter: CGFloat = 600
let lineWidth: CGFloat = 34

struct RingIcon: View {
    var background: Color?
    var track: Color
    var arc: Color

    var body: some View {
        ZStack {
            if let background { background }
            Circle()
                .stroke(track, lineWidth: lineWidth)
            // The arc ends at 12 o'clock and is eaten away clockwise as time passes.
            Circle()
                .trim(from: 1 - remaining, to: 1)
                .stroke(arc, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: ringDiameter, height: ringDiameter)
        .frame(width: CGFloat(size), height: CGFloat(size))
        .background(background ?? .clear)
    }
}

@MainActor
func write(_ view: some View, to name: String, opaque: Bool) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    guard var image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }

    if opaque {
        // Redraw without an alpha channel.
        let context = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        image = context.makeImage()!
    }

    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    let url = outputDirectory.appendingPathComponent(name)
    try data.write(to: url)
    print("wrote \(url.path)")
}

try MainActor.assumeIsolated {
    try write(RingIcon(background: .black, track: .white.opacity(0.14), arc: .white), to: "AppIcon.png", opaque: true)
    try write(RingIcon(background: nil, track: .white.opacity(0.18), arc: .white), to: "AppIcon-Dark.png", opaque: false)
    try write(RingIcon(background: .black, track: Color(white: 0.25), arc: .white), to: "AppIcon-Tinted.png", opaque: true)
}
