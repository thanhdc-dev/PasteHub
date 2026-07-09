import SwiftUI
import Combine

enum FocusField: Hashable {
    case search
    case list
}

final class SelectionState: ObservableObject {
    @Published var index: Int = 0
    @Published var mode: FocusField? = .search
    @Published var isPreviewOpen: Bool = false
}
