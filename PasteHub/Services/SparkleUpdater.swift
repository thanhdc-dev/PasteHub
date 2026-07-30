import SwiftUI
import Sparkle
import Combine
import Network

final class UpdaterViewModel: ObservableObject {
    let updaterController: SPUStandardUpdaterController

    @Published var canCheckForUpdates = false

    private var periodicCheckTimer: Timer?
    private let defaults = UserDefaults.standard
    private let monitor = NWPathMonitor()
    private var isNetworkAvailable = true

    init() {
        // startingUpdater: true -> Sparkle tự động bắt đầu lịch kiểm tra định kỳ
        // updaterDelegate/userDriverDelegate: để nil nếu không cần custom UI
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)

        startNetworkMonitoring()
        refreshPeriodicChecks()
    }

    deinit {
        stopPeriodicChecks()
        monitor.cancel()
    }

    func checkForUpdates() {
        guard isNetworkAvailable else { return }
        updaterController.checkForUpdates(nil)
    }

    func refreshPeriodicChecks() {
        stopPeriodicChecks()

        let isEnabled = defaults.bool(forKey: "autoCheckForUpdates")
        guard isEnabled else { return }

        let intervalHours = defaults.object(forKey: "updateCheckIntervalHours") as? Int ?? 24
        let interval = max(1, intervalHours) * 60 * 60

        periodicCheckTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
        if let timer = periodicCheckTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopPeriodicChecks() {
        periodicCheckTimer?.invalidate()
        periodicCheckTimer = nil
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
        }
        monitor.start(queue: .main)
    }
}
