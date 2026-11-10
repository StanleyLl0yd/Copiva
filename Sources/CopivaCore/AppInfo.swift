public enum AppInfo {
    public static let displayName = "Copiva"
    public static let minimumMacOSMajorVersion = 26
}

public enum PasteMode: String, Codable, CaseIterable {
    case original
    case plainText
}
