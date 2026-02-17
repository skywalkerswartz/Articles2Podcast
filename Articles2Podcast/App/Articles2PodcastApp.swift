import SwiftUI
import SwiftData

@main
struct Articles2PodcastApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let modelContainer = SharedModelContainer.create()
    @State private var audioPlayer = AudioPlayerService.shared
    @State private var processingQueue = ProcessingQueue.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioPlayer)
                .environment(processingQueue)
        }
        .modelContainer(modelContainer)
    }
}
