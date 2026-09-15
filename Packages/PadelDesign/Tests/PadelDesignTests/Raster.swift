import CoreGraphics
import SwiftUI

/// A view, rendered, with its pixels readable.
///
/// - Important: Rendering happens on the Mac, so the thicknesses these suites
///   see are the phone's. Assertions go in fractions of the frame, not points.
@MainActor
struct Raster {
    /// One pixel, as it appears **over black**, which is what makes a
    /// transparent pixel read as zero rather than as white.
    struct Pixel {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        /// The three channels weighted the way an eye weighs them.
        var luminance: Double {
            0.2126 * red + 0.7152 * green + 0.0722 * blue
        }
    }

    let width: Int
    let height: Int

    /// Straight sRGB bytes, four to a pixel, first row at the top.
    private let pixels: [UInt8]

    /// Renders `view` at exactly `size`.
    init?(_ view: some View, size: CGSize) {
        self.init(view.frame(width: size.width, height: size.height))
    }

    /// Renders `view` at whatever size it asks for, which is how the layout
    /// assertions get at the size a view takes.
    init?(_ view: some View) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1

        guard let image = renderer.cgImage, image.width > 0, image.height > 0 else {
            return nil
        }

        // Locals, and not the properties below, because the closure would
        // otherwise capture a half-built `self`.
        let columns = image.width
        let rows = image.height

        width = columns
        height = rows

        var bytes = [UInt8](repeating: 0, count: columns * rows * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard
                let space = CGColorSpace(name: CGColorSpace.sRGB),
                let context = CGContext(
                    data: buffer.baseAddress,
                    width: columns,
                    height: rows,
                    bitsPerComponent: 8,
                    bytesPerRow: columns * 4,
                    space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }

            context.draw(
                image, in: CGRect(x: 0, y: 0, width: CGFloat(columns), height: CGFloat(rows)))
            return true
        }

        guard drawn else { return nil }
        pixels = bytes
    }

    // MARK: Reading a pixel

    /// The pixel at `(column, row)`, counting from the top left.
    func pixel(_ column: Int, _ row: Int) -> Pixel {
        let offset = (row * width + column) * 4

        return Pixel(
            red: Double(pixels[offset]) / 255,
            green: Double(pixels[offset + 1]) / 255,
            blue: Double(pixels[offset + 2]) / 255,
            alpha: Double(pixels[offset + 3]) / 255)
    }

    func luminance(_ column: Int, _ row: Int) -> Double {
        pixel(column, row).luminance
    }

    func alpha(_ column: Int, _ row: Int) -> Double {
        pixel(column, row).alpha
    }

    // MARK: Reading a patch

    func rowLuminance(_ row: Int) -> Double {
        meanLuminance(columns: 0..<width, rows: row..<(row + 1))
    }

    /// The mean brightness of a patch. Nearly every assertion about the court
    /// is written against a patch and not a pixel: the weave lies over the
    /// whole surface, and a single pixel is either on a stripe or between two.
    func meanLuminance(columns: Range<Int>, rows: Range<Int>) -> Double {
        var total = 0.0

        for row in rows {
            for column in columns {
                total += luminance(column, row)
            }
        }

        return total / Double(columns.count * rows.count)
    }

    /// Whether a patch of this raster is painted the same as `other`'s.
    ///
    /// - Parameter tolerance: Rendering one view twice is not bit-exact —
    ///   antialiasing lands a pixel a step of 1/255 either side.
    func patch(
        columns: Range<Int>, rows: Range<Int>, matches other: Raster,
        tolerance: Double = 1 / 255
    ) -> Bool {
        let mine = meanLuminance(columns: columns, rows: rows)
        let theirs = other.meanLuminance(columns: columns, rows: rows)

        return abs(mine - theirs) < tolerance
    }

    /// How many pixels of one row were drawn on, which is how a round shape's
    /// width is measured. The threshold sits above the heaviest shadow in the
    /// package — black at 0.5, blurred down — so a shadow never answers for the
    /// thing casting it.
    func drawnWidth(inRow row: Int, atLeast threshold: Double = 0.6) -> Int {
        (0..<width).count { alpha($0, row) > threshold }
    }

    // MARK: Comparing to a token

    /// Whether the pixel at `(column, row)` is the color `token` resolves to.
    /// The tolerance is generous because the weave lies over every court
    /// surface at a few thousandths of white, and a tighter comparison would be
    /// a comparison of the texture rather than of the paint.
    func pixel(
        _ column: Int, _ row: Int, isCloseTo token: Color, tolerance: Double = 0.05
    ) -> Bool {
        let resolved = token.resolve(in: EnvironmentValues())
        let pixel = pixel(column, row)

        return abs(pixel.red - Double(resolved.red)) < tolerance
            && abs(pixel.green - Double(resolved.green)) < tolerance
            && abs(pixel.blue - Double(resolved.blue)) < tolerance
    }

    /// A token's brightness, weighted the way ``Pixel/luminance`` weights a
    /// pixel's, so the two can be compared.
    static func luminance(of token: Color) -> Double {
        let resolved = token.resolve(in: EnvironmentValues())

        return Pixel(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue),
            alpha: Double(resolved.opacity)
        ).luminance
    }
}
