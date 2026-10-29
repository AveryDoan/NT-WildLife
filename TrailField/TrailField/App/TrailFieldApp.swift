import SwiftData
import SwiftUI
import UIKit

@main
struct TrailFieldApp: App {
    @State private var species = SpeciesStore()

    init() {
        // Page dots default to white, which vanishes on Paper.
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(named: "Moss")
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(named: "Ink")?.withAlphaComponent(0.3)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(species)
                .tint(Color.tfMoss)
        }
        .modelContainer(for: Sighting.self)
    }
}

enum AppTab: Hashable {
    case today, guide, capture, map, ranks
}

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("demoMode") private var demoMode = false
    @Environment(\.modelContext) private var context
    @Environment(SpeciesStore.self) private var species

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task { syncDemoData() }
    }

    /// Keeps demo mode and the sample data in step (for example after a restore or a launch argument).
    private func syncDemoData() {
        let demoCount = (try? context.fetchCount(FetchDescriptor<Sighting>(predicate: #Predicate { $0.isDemo }))) ?? 0
        if demoMode && demoCount == 0 {
            DemoData.enable(species: species, context: context)
        } else if !demoMode && demoCount > 0 {
            DemoData.disable(context: context)
        }
    }
}

struct MainTabView: View {
    /// DEBUG only: `-initialTab guide` opens a tab straight away (used for simulator screenshots).
    static var initialTab: AppTab {
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "initialTab") {
        case "guide": return .guide
        case "capture": return .capture
        case "map": return .map
        case "ranks": return .ranks
        default: return .today
        }
        #else
        return .today
        #endif
    }

    @State private var selection: AppTab = MainTabView.initialTab

    var body: some View {
        TabView(selection: $selection) {
            TodayView(selectedTab: $selection)
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)
            GuideView()
                .tabItem { Label("Field Guide", systemImage: "book.closed") }
                .tag(AppTab.guide)
            CaptureView(selectedTab: $selection)
                .tabItem { Label("Capture", systemImage: "camera.fill") }
                .tag(AppTab.capture)
            MapTabView()
                .tabItem { Label("Map", systemImage: "map") }
                .tag(AppTab.map)
            RanksView()
                .tabItem { Label("Ranks", systemImage: "trophy") }
                .tag(AppTab.ranks)
        }
    }
}
