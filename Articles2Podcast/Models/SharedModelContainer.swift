import SwiftData

enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.lukeswartz.articles2podcast"

    static func create() -> ModelContainer {
        let schema = Schema([Article.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
