import SwiftUI
import TrailCore

struct OnboardingView: View {
    @AppStorage("nickname") private var nickname = ""
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                intro(
                    group: .butterfliesAndMoths,
                    title: "Welcome to TrailField",
                    text: "Spot insects around the Top End, find out what they are, and build your own field guide."
                ).tag(0)
                intro(
                    group: .beetles,
                    title: "Look, don't touch",
                    text: "Photograph from a safe distance. Never catch or handle insects, and keep away from water edges, snakes, spiders and stinging insects."
                ).tag(1)
                intro(
                    group: .ants,
                    title: "Private by design",
                    text: "Everything stays on your phone. You use a nickname only, locations are rounded to about 1 km, and photos of people are never saved."
                ).tag(2)
                nicknamePage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page < 3 ? "Next" : "Start exploring") {
                if page < 3 {
                    withAnimation { page += 1 }
                } else {
                    nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    hasOnboarded = true
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(page == 3 && !Nickname.isValid(nickname))
            .padding(TFLayout.screenPadding)
        }
        .paperBackground()
    }

    private func intro(group: SpeciesGroup, title: String, text: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            SilhouetteView(group: group).frame(width: 140, height: 140)
            Text(title).font(TFFont.heading(.largeTitle)).multilineTextAlignment(.center).foregroundStyle(Color.tfInk)
            Text(text).font(TFFont.body(.title3)).multilineTextAlignment(.center).foregroundStyle(Color.tfInk.opacity(0.9))
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
    }

    private var nicknamePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Pick a nickname").font(TFFont.heading(.largeTitle)).foregroundStyle(Color.tfInk)
            Text("This is the only thing other players would ever see. Please don't use your real name.")
                .font(TFFont.body()).multilineTextAlignment(.center).foregroundStyle(Color.tfInk.opacity(0.9))
            TextField("Nickname", text: $nickname)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(TFFont.body(.title3))
                .padding(14)
                .frame(minHeight: TFLayout.minTarget)
                .background(Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: TFLayout.cornerRadius).stroke(Color.tfInk.opacity(0.4), lineWidth: 1))
                .onChange(of: nickname) { _, new in
                    if new.count > Nickname.maxLength { nickname = String(new.prefix(Nickname.maxLength)) }
                }
            Text("2 to \(Nickname.maxLength) characters")
                .font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk.opacity(0.8))
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
