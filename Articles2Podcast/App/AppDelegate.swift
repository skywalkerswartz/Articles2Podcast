import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    static let processingTaskIdentifier = "com.lukeswartz.articles2podcast.processing"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else { return }
            self.handleBackgroundProcessing(processingTask)
        }
        return true
    }

    private func handleBackgroundProcessing(_ task: BGProcessingTask) {
        let processingQueue = ProcessingQueue.shared

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            await processingQueue.processNextArticle()
            task.setTaskCompleted(success: true)
            Self.scheduleBackgroundProcessing()
        }
    }

    static func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background task: \(error)")
        }
    }
}
