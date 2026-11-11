import AppKit

public enum PickerPlacement {
    /// Pointer fallback; caret positioning is a later UX milestone.
    public static func frame(size: CGSize, pointer: CGPoint, visibleFrame: CGRect) -> CGRect {
        let width = min(size.width, visibleFrame.width)
        let height = min(size.height, visibleFrame.height)
        let x = max(visibleFrame.minX, min(pointer.x - 32, visibleFrame.maxX - width))
        let y = max(visibleFrame.minY, min(pointer.y - height - 12, visibleFrame.maxY - height))
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
