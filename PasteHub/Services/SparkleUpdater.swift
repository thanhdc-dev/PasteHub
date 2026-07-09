import SwiftUI
import Sparkle
import Combine

final class UpdaterViewModel: ObservableObject {
    let updaterController: SPUStandardUpdaterController

    @Published var canCheckForUpdates = false

    init() {
        // startingUpdater: true -> Sparkle tự động bắt đầu lịch kiểm tra định kỳ
        // updaterDelegate/userDriverDelegate: để nil nếu không cần custom UI
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
