import SwiftData
import SwiftUI
import TrailCore

/// Identify then Result, shown full screen over the tab bar.
struct CaptureFlowView: View {
    let draft: CaptureDraft
    /// Called when the player is done. Pass a tab to jump to it.
    let onFinish: (AppTab?) -> Void

    @State private var result: SaveResult?

    struct SaveResult {
        let sighting: Sighting?
        let breakdown: ScoreBreakdown
        let pinned: Bool
    }

    var body: some View {
        NavigationStack {
            IdentifyView(draft: draft, onCancel: { onFinish(nil) }) { saved in
                result = saved
            }
            .navigationDestination(isPresented: Binding(get: { result != nil }, set: { if !$0 { result = nil } })) {
                if let result {
                    ResultView(result: result, onFinish: onFinish)
                        .navigationBarBackButtonHidden()
                }
            }
        }
        .task { await draft.runChecks() }
    }
}
