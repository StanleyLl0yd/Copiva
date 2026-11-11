/// Stable identity selection for asynchronously refreshed history results.
public struct PickerSelection: Equatable, Sendable {
    public private(set) var selectedID: Int64?
    private var ids: [Int64] = []

    public init() {}

    public mutating func update(ids: [Int64]) {
        self.ids = ids
        if !ids.contains(where: { $0 == selectedID }) { selectedID = ids.first }
    }

    public mutating func select(_ id: Int64) {
        guard ids.contains(id) else { return }
        selectedID = id
    }

    public mutating func move(by offset: Int) {
        guard !ids.isEmpty else { selectedID = nil; return }
        let current = selectedID.flatMap { ids.firstIndex(of: $0) } ?? 0
        let bounded = max(-ids.count, min(offset, ids.count))
        selectedID = ids[max(0, min(ids.count - 1, current + bounded))]
    }
}
