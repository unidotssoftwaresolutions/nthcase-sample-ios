#!/usr/bin/env swift
// Makes the asset catalog from the original art, which stays unchanged in art/.
//
//   swift scripts/make-assets.swift      (from the repository root, on a Mac)
//
// - art/icons/<name>.svg  → Assets.xcassets/icon-<name>.imageset   (a byte-for-byte copy, vector, template)
// - art/glyphs/<name>.svg → Assets.xcassets/glyph-<name>.imageset
// - art/launcher.svg      → Assets.xcassets/AppIcon.appiconset/AppIcon.png (1024 px, opaque, drawn by macOS's own
//   SVG renderer: iOS app icons must be bitmaps)
//
// The SVGs keep "Preserve Vector Data", so they stay sharp at every size, and render as templates, so the app tints
// them from its palette. Run it again whenever art/ changes, and commit what it writes.
import AppKit
import Foundation

let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let art = root.appendingPathComponent("art")
let catalog = root.appendingPathComponent("Mossgrove/Resources/Assets.xcassets")

guard fm.fileExists(atPath: art.appendingPathComponent("launcher.svg").path) else {
    FileHandle.standardError.write("Run this from the repository root: art/launcher.svg was not found.\n".data(using: .utf8)!)
    exit(1)
}

func write(_ text: String, to url: URL) throws {
    try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try text.write(to: url, atomically: true, encoding: .utf8)
}

// Start clean, so a drawing removed from art/ leaves the catalog too.
if fm.fileExists(atPath: catalog.path) { try fm.removeItem(at: catalog) }
try write("""
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

""", to: catalog.appendingPathComponent("Contents.json"))

var made = 0
for (folder, prefix) in [("icons", "icon-"), ("glyphs", "glyph-")] {
    let names = try fm.contentsOfDirectory(atPath: art.appendingPathComponent(folder).path).filter { $0.hasSuffix(".svg") }.sorted()
    for name in names {
        let asset = prefix + name.dropLast(4).replacingOccurrences(of: "_", with: "-")
        let set = catalog.appendingPathComponent("\(asset).imageset")
        try fm.createDirectory(at: set, withIntermediateDirectories: true)
        try fm.copyItem(at: art.appendingPathComponent("\(folder)/\(name)"), to: set.appendingPathComponent("\(asset).svg"))
        try write("""
        {
          "images" : [
            {
              "filename" : "\(asset).svg",
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          },
          "properties" : {
            "preserves-vector-representation" : true,
            "template-rendering-intent" : "template"
          }
        }

        """, to: set.appendingPathComponent("Contents.json"))
        made += 1
    }
}

// The app icon: launcher.svg drawn at 1024 × 1024 with no alpha channel.
let iconSet = catalog.appendingPathComponent("AppIcon.appiconset")
try fm.createDirectory(at: iconSet, withIntermediateDirectories: true)
guard let launcher = NSImage(contentsOf: art.appendingPathComponent("launcher.svg")) else {
    FileHandle.standardError.write("macOS could not read art/launcher.svg.\n".data(using: .utf8)!)
    exit(1)
}
let side = 1024
let context = CGContext(
    data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
launcher.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
NSGraphicsContext.restoreGraphicsState()
let png = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
try png.write(to: iconSet.appendingPathComponent("AppIcon.png"))
try write("""
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

""", to: iconSet.appendingPathComponent("Contents.json"))

print("Wrote \(made) drawings and the app icon to \(catalog.path)")
