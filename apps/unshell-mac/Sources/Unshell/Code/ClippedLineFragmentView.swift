import AppKit
import CodeEditTextView
import CoreText

/// Supplies `ClippedLineFragmentView`s to CodeEditTextView.
final class ClippedLineRenderDelegate: TextLayoutManagerRenderDelegate {
    func lineFragmentView(for lineFragment: LineFragment) -> LineFragmentView {
        ClippedLineFragmentView()
    }
}

/// Draws only the glyphs that intersect the dirty rect.
///
/// CodeEditTextView's default view draws the whole CTLine on every redraw.
/// A minified file has lines tens of thousands of points wide, and AppKit
/// redraws the visible slice of such a view on every horizontal scroll step,
/// so drawing the full line made each frame cost ~300 ms. Here each glyph run
/// is checked against the dirty rect and, within a run, only the visible glyph
/// range is drawn, so the cost follows the visible width, not the line length.
final class ClippedLineFragmentView: LineFragmentView {
    /// Glyph runs of each text content with their x extents (relative to the
    /// line), sorted by x. Built on first draw, dropped when the fragment changes.
    private struct RunExtent { let minX: CGFloat; let maxX: CGFloat; let run: CTRun }
    private var extents: [[RunExtent]]?

    override func setLineFragment(_ newFragment: LineFragment, fragmentRange: NSRange, renderer: LineFragmentRenderer) {
        extents = nil
        super.setLineFragment(newFragment, fragmentRange: fragmentRange, renderer: renderer)
    }

    override func prepareForReuse() {
        extents = nil
        super.prepareForReuse()
    }

    private func runExtents(_ lineFragment: LineFragment) -> [[RunExtent]] {
        if let extents { return extents }
        let built: [[RunExtent]] = lineFragment.contents.map { content in
            guard case .text(let line) = content.data else { return [] }
            return (CTLineGetGlyphRuns(line) as! [CTRun]).compactMap { run in
                guard CTRunGetGlyphCount(run) > 0 else { return nil }
                var first = CGPoint.zero
                CTRunGetPositions(run, CFRange(location: 0, length: 1), &first)
                let width = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), nil, nil, nil))
                return RunExtent(minX: first.x, maxX: first.x + width, run: run)
            }
        }
        extents = built
        return built
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let lineFragment, let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        defer { context.restoreGState() }
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.setAllowsFontSubpixelPositioning(true)
        context.setShouldSubpixelPositionFonts(true)
        context.setAllowsFontSubpixelQuantization(true)
        context.setShouldSubpixelQuantizeFonts(true)
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)

        let baseline = lineFragment.height - lineFragment.descent + lineFragment.heightDifference / 2
        let scale = window?.backingScaleFactor ?? 2
        let minX = dirtyRect.minX, maxX = dirtyRect.maxX
        let allExtents = runExtents(lineFragment)
        var lineX: CGFloat = 0
        for (index, content) in lineFragment.contents.enumerated() {
            defer { lineX += content.width }
            guard case .text = content.data, lineX <= maxX, lineX + content.width >= minX else { continue }
            let origin = CGPoint(x: (lineX * scale).rounded() / scale, y: (baseline * scale).rounded() / scale)
            let runs = allExtents[index]
            let localMin = minX - origin.x, localMax = maxX - origin.x
            // First run that ends at or after the dirty rect's left edge.
            var low = 0, high = runs.count
            while low < high {
                let mid = (low + high) / 2
                if runs[mid].maxX < localMin { low = mid + 1 } else { high = mid }
            }
            var position = low
            while position < runs.count, runs[position].minX <= localMax {
                draw(runs[position].run, origin: origin, minX: localMin, maxX: localMax, in: context)
                position += 1
            }
        }
    }

    /// Draws the glyphs of `run` whose x positions (relative to the line) fall
    /// in `minX...maxX`, with one glyph of slack on each side.
    private func draw(_ run: CTRun, origin: CGPoint, minX: CGFloat, maxX: CGFloat, in context: CGContext) {
        let count = CTRunGetGlyphCount(run)
        var range = CFRange(location: 0, length: 0) // whole run
        if count > 64 {
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
            let start = max(0, lowerBound(positions, minX) - 1)
            let end = min(count, lowerBound(positions, maxX) + 1)
            guard start < end else { return }
            range = CFRange(location: start, length: end - start)
        }
        context.textPosition = origin
        CTRunDraw(run, context, range)
    }

    private func lowerBound(_ positions: [CGPoint], _ x: CGFloat) -> Int {
        var low = 0, high = positions.count
        while low < high {
            let mid = (low + high) / 2
            if positions[mid].x < x { low = mid + 1 } else { high = mid }
        }
        return low
    }
}
