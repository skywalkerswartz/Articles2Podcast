import SwiftUI

struct ContentView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer
    @State private var selectedTab: Tab = .queue

    enum Tab {
        case queue, settings
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    QueueView()
                }
                .tag(Tab.queue)
                .tabItem {
                    Label("Queue", systemImage: "list.bullet")
                }

                NavigationStack {
                    SettingsView()
                }
                .tag(Tab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }

            if audioPlayer.currentArticleId != nil {
                MiniPlayerView()
                    .padding(.bottom, 49) // Tab bar height
                    .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: Bindable(audioPlayer).showFullPlayer) {
            FullPlayerView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Article.self, inMemory: true)
        .environment(AudioPlayerService.shared)
        .environment(ProcessingQueue.shared)
}
