//
//  MeasureModifiers.swift
//  Scoop
//
//  Created by Art Ostin on 15/06/2026.
//

import SwiftUI
import CoreText

//Helpers that report a view's measured geometry into bound state.
extension View {
    
    func getHeight(_ height: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height.wrappedValue = $0 }
    }
    
    func getWidth(_ width: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width.wrappedValue = $0 }
    }
    
    func getRect(_ rect: Binding<CGRect>, coordSpace: String? = nil) -> some View {
        onGeometryChange(for: CGRect.self) { geo in
            geo.frame(in: coordSpace.map { CoordinateSpace.named($0) } ?? .global) }
        action: {
            rect.wrappedValue = $0
        }
    }
    
    func getBottom(coordinateSpace: String, bottom: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { geo in
            geo.frame(in: .named(coordinateSpace)).maxY
        } action: { bottomPosition in
            if bottom.wrappedValue < 25 { //Updates only once. If less than 25 it indicates still on transient
                bottom.wrappedValue = bottomPosition
            }
        }
    }
}

//Where a wrapped string's last line ends. View geometry only reports the bounding box,
//so anything that has to sit beside the final line has to lay the text out itself.
extension String {

    struct LineMetrics {
        let count: Int
        let lastLineWidth: CGFloat
    }

    //Font and lineSpacing must match the Text's exactly or the line breaks won't agree.
    func lineMetrics(font: UIFont, lineSpacing: CGFloat, width: CGFloat) -> LineMetrics {
        guard width > 0, width.isFinite, !isEmpty else { return LineMetrics(count: 0, lastLineWidth: 0) }

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing

        let attributed = NSAttributedString(
            string: self,
            attributes: [.font: font, .paragraphStyle: paragraph]
        )

        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)

        let lines = CTFrameGetLines(frame) as? [CTLine] ?? []
        guard let last = lines.last else { return LineMetrics(count: 0, lastLineWidth: 0) }

        //Trailing whitespace is laid out but not drawn, so it can't count towards the line's end
        let typographic = CGFloat(CTLineGetTypographicBounds(last, nil, nil, nil))
        return LineMetrics(
            count: lines.count,
            lastLineWidth: typographic - CTLineGetTrailingWhitespaceWidth(last)
        )
    }
}
