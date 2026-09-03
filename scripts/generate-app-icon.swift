#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: generate-app-icon.swift <output.iconset>\n".utf8))
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fileManager = FileManager.default
try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let representations: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1_024)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func makeIcon(pixels: Int) throws -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    let scale = CGFloat(pixels) / 1_024
    context.scaleBy(x: scale, y: scale)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let tileRect = CGRect(x: 104, y: 104, width: 816, height: 816)
    let tilePath = CGPath(
        roundedRect: tileRect,
        cornerWidth: 190,
        cornerHeight: 190,
        transform: nil
    )

    // Graphite tile: quiet enough for the Dock, with the identity carrying
    // the contrast rather than decorative texture.
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -26), blur: 42, color: color(0, 0, 0, 0.34))
    context.addPath(tilePath)
    context.setFillColor(color(23, 26, 31))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(tilePath)
    context.clip()
    let tileGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(55, 61, 70), color(22, 25, 30)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        tileGradient,
        start: CGPoint(x: 300, y: 900),
        end: CGPoint(x: 760, y: 120),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    context.restoreGState()

    context.addPath(tilePath)
    context.setStrokeColor(color(255, 255, 255, 0.13))
    context.setLineWidth(10)
    context.strokePath()

    let squareSize: CGFloat = 158
    let gap: CGFloat = 62
    let left = (1_024 - (squareSize * 2 + gap)) / 2
    let bottom = 472 as CGFloat
    let squareColors = [
        color(247, 249, 252),
        color(222, 228, 235),
        color(222, 228, 235),
        color(247, 249, 252)
    ]

    for row in 0..<2 {
        for column in 0..<2 {
            let rect = CGRect(
                x: left + CGFloat(column) * (squareSize + gap),
                y: bottom + CGFloat(row) * (squareSize + gap),
                width: squareSize,
                height: squareSize
            )
            let path = CGPath(
                roundedRect: rect,
                cornerWidth: 36,
                cornerHeight: 36,
                transform: nil
            )
            context.addPath(path)
            context.setFillColor(squareColors[row * 2 + column])
            context.fillPath()
        }
    }

    // The ledge makes the familiar four-square mark specific to NotchShelf.
    context.setStrokeColor(color(105, 169, 255))
    context.setLineWidth(58)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: 286, y: 354))
    context.addLine(to: CGPoint(x: 738, y: 354))
    context.strokePath()

    context.setStrokeColor(color(181, 213, 255, 0.9))
    context.setLineWidth(12)
    context.move(to: CGPoint(x: 310, y: 366))
    context.addLine(to: CGPoint(x: 714, y: 366))
    context.strokePath()

    guard let image = context.makeImage() else {
        throw CocoaError(.fileWriteUnknown)
    }
    let representation = NSBitmapImageRep(cgImage: image)
    guard let data = representation.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

for representation in representations {
    let destination = outputDirectory.appendingPathComponent(representation.name)
    try makeIcon(pixels: representation.pixels).write(to: destination, options: .atomic)
}
