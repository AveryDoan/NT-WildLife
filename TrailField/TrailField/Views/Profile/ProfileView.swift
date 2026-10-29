import SwiftData
import SwiftUI

struct ProfileView: View {
    @AppStorage("nickname") private var nickname = ""
    @AppStorage("demoMode") private var demoMode = false
    @AppStorage("hasOnboarded") private var hasOnboarded = true

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(SpeciesStore.self) private var store
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Nickname", text: $nickname)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .frame(minHeight: TFLayout.minTarget)
                        .onChange(of: nickname) { _, new in
                            if new.count > Nickname.maxLength { nickname = String(new.prefix(Nickname.maxLength)) }
                        }
                } header: {
                    Text("Nickname")
                } footer: {
                    Text("A nickname only. Please don't use your real name.")
                }

                Section {
                    Toggle("Demo mode", isOn: $demoMode)
                        .frame(minHeight: TFLayout.minTarget)
                        .onChange(of: demoMode) { _, on in
                            if on { DemoData.enable(species: store, context: context) } else { DemoData.disable(context: context) }
                        }
                } footer: {
                    Text("Adds a few clearly labelled sample finds so the field guide and map look populated. Turning it off removes them.")
                }

                Section {
                    NavigationLink("About TrailField") { AboutView() }.frame(minHeight: TFLayout.minTarget)
                    NavigationLink("Privacy and safety") { PrivacySafetyView() }.frame(minHeight: TFLayout.minTarget)
                }

                Section {
                    Button("Delete all my data", role: .destructive) { confirmDelete = true }
                        .frame(minHeight: TFLayout.minTarget)
                } footer: {
                    Text("Removes every sighting, photo and your nickname from this phone.")
                }
            }
            .scrollContentBackground(.hidden)
            .paperBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.frame(minHeight: TFLayout.minTarget)
                }
            }
            .confirmationDialog("Delete everything?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete all my data", role: .destructive) {
                    SightingService.deleteAllData(context: context)
                    nickname = ""
                    demoMode = false
                    hasOnboarded = false
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
        }
    }
}

enum Nickname {
    static let maxLength = 20
    static let minLength = 2
    static func isValid(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minLength && trimmed.count <= maxLength
    }
}

struct AboutView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "1.0") (\(info?["CFBundleVersion"] as? String ?? "1"))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SpecimenCard(caption: "Work in progress") {
                    Text("TrailField").font(TFFont.heading(.title)).foregroundStyle(Color.tfInk)
                    Text("Version \(version)").font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk.opacity(0.8))
                    Text("An iPhone field guide for people in the Northern Territory: photograph insects from a safe distance, find out what they are, collect them in your own guide and compete with friends. Made for the CDU IT Code Fair.")
                        .font(TFFont.body()).foregroundStyle(Color.tfInk)
                }
                SpecimenCard(caption: "Where the facts come from") {
                    Text("Species facts are checked against pages we actually read: the Atlas of Living Australia, the Australian Museum and NT Government sources. Anything we couldn't check is left blank and tagged Unverified. The full log is in Docs/DATA_SOURCES.md in the project.")
                        .font(TFFont.body()).foregroundStyle(Color.tfInk)
                    Text("Traditional knowledge: to be added with community guidance")
                        .font(TFFont.body(.footnote)).italic().foregroundStyle(Color.tfInk.opacity(0.85))
                }
                SpecimenCard(caption: "Pictures") {
                    Text("The insect pictures are original silhouettes drawn for this app. No species photos are used. Photos you take stay on your phone.")
                        .font(TFFont.body()).foregroundStyle(Color.tfInk)
                }
                SpecimenCard(caption: "Sample data") {
                    Text("Anything marked \"Demo\" or \"Sample player\" is made up for demonstration.")
                        .font(TFFont.body()).foregroundStyle(Color.tfInk)
                }
            }
            .padding(TFLayout.screenPadding)
        }
        .paperBackground()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySafetyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SafetyBanner(message: "Never catch, handle, bait or collect insects. Keep away from stinging insects, snakes, spiders and crocodiles, stay back from water edges, and don't go out at night. Don't collect in national parks or restricted areas.")
                SpecimenCard(caption: "Privacy") {
                    bullet("Everything stays on this phone. There is no account and no server.")
                    bullet("Only a nickname. No chat, and no photos of people (we check every photo).")
                    bullet("Locations are rounded to about 1 km before they're saved, and rare species to about 11 km.")
                    bullet("Photos are saved without their location or camera details.")
                    bullet("\"Delete all my data\" in Profile removes everything.")
                }
            }
            .padding(TFLayout.screenPadding)
        }
        .paperBackground()
        .navigationTitle("Privacy and safety")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        Label {
            Text(text).font(TFFont.body()).foregroundStyle(Color.tfInk)
        } icon: {
            Image(systemName: "checkmark.circle").foregroundStyle(Color.tfMoss)
        }
    }
}
