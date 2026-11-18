import Foundation
import SwiftUI

struct Preferences: Codable, Equatable {
    var theme: String = "tokyo-night"
    var fontSize: Double = 13
    var agentsRunOnSave = true
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var preferences = Preferences()
    private let url: URL

    init(directory: URL = .applicationSupportDirectory) {
        url = directory.appending(path: "unshell/settings.json")
    }

    func load() async throws {
        let data = try Data(contentsOf: url)
        preferences = try JSONDecoder().decode(Preferences.self, from: data)
    }

    func update(_ change: (inout Preferences) -> Void) {
        change(&preferences)
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
