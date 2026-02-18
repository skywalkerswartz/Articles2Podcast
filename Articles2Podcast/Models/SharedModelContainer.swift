import SwiftData
import os.log

enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.lukeswartz.articles2podcast"
    private static let logger = Logger(subsystem: "com.lukeswartz.articles2podcast", category: "ModelContainer")

    static func create() -> ModelContainer {
        let schema = Schema([Article.self])

        // Try App Group container first (shared with Share Extension)
        do {
            let groupConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupIdentifier),
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: [groupConfig])
        } catch {
            logger.warning("App Group container unavailable, falling back to local store: \(error.localizedDescription)")
        }

        // Fall back to default local container (works on simulator without provisioning)
        do {
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
