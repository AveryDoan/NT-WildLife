import PhotosUI
import TrailCore
import SwiftUI
import UIKit

/// Holds one photo while it is checked and identified.
@Observable
final class CaptureDraft: Identifiable {
    let id = UUID()
    let photo: ImportedPhoto
    var faceStatus: FaceStatus = .checking
    var vision: VisionResult?

    init(photo: ImportedPhoto) {
        self.photo = photo
    }

    func runChecks() async {
        let image = photo.image
        let face = await Task.detached { FaceCheck.check(image) }.value
        faceStatus = face
        guard face == .clear else { return }
        vision = await Task.detached { VisionHintService.classify(image) }.value
    }
}

struct CaptureView: View {
    @Binding var selectedTab: AppTab

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var draft: CaptureDraft?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SafetyBanner(message: "Photograph from a safe distance. Never catch, handle or bait insects. Watch for stinging insects, snakes, spiders and crocodiles, and stay away from water edges and night-time tracks.")

                    VStack(spacing: 10) {
                        InsectSilhouette(group: .butterfliesAndMoths)
                            .fill(Color.tfMoss.opacity(0.85))
                            .frame(width: 96, height: 96)
                            .accessibilityHidden(true)
                        Text("Found something small?")
                            .font(TFFont.heading(.title2))
                            .foregroundStyle(Color.tfInk)
                        Text("Take a photo, or pick one you took in the last 72 hours. Photos stay on your phone.")
                            .font(TFFont.body())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.tfInk.opacity(0.85))
                    }
                    .padding(.vertical, 8)

                    VStack(spacing: 12) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take a photo", systemImage: "camera")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!cameraAvailable || isLoading)

                        if !cameraAvailable {
                            Text("This device has no camera (the simulator never does). Choose a photo instead.")
                                .font(TFFont.body(.footnote))
                                .foregroundStyle(Color.tfInk.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }

                        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                            Label("Choose from photos", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isLoading)
                    }

                    if isLoading {
                        ProgressView("Opening photo…")
                            .tint(Color.tfMoss)
                            .foregroundStyle(Color.tfInk)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(TFFont.body(.footnote))
                            .foregroundStyle(Color.tfInk)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
                            .overlay(RoundedRectangle(cornerRadius: TFLayout.cornerRadius).stroke(Color.tfClay, lineWidth: 1))
                    }
                }
                .padding(TFLayout.screenPadding)
            }
            .paperBackground()
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
        }
        #if DEBUG
        .task {
            // `-debugPhoto /path/to.jpg` feeds a file through the real import path (the simulator has no camera).
            guard let path = UserDefaults.standard.string(forKey: "debugPhoto"),
                  let data = FileManager.default.contents(atPath: path),
                  let photo = await Task.detached(operation: { PhotoImport.fromLibrary(data: data) }).value else { return }
            draft = CaptureDraft(photo: photo)
        }
        #endif
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                showCamera = false
                guard let image else { return }
                Task { await start(from: image) }
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $draft) { draft in
            CaptureFlowView(draft: draft) { destination in
                self.draft = nil
                if let destination { selectedTab = destination }
            }
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        errorMessage = nil
        isLoading = true
        defer {
            isLoading = false
            pickerItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            errorMessage = "Couldn't open that photo. Try another one."
            return
        }
        let photo = await Task.detached { PhotoImport.fromLibrary(data: data) }.value
        guard let photo else {
            errorMessage = "That file doesn't look like a photo we can read."
            return
        }
        draft = CaptureDraft(photo: photo)
    }

    private func start(from image: UIImage) async {
        errorMessage = nil
        guard let photo = await Task.detached(operation: { PhotoImport.fromCamera(image: image) }).value else {
            errorMessage = "Couldn't read the camera photo. Please try again."
            return
        }
        draft = CaptureDraft(photo: photo)
    }
}

/// System camera. Only offered when the device has one.
struct CameraPicker: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (UIImage?) -> Void
        init(onFinish: @escaping (UIImage?) -> Void) { self.onFinish = onFinish }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onFinish(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
    }
}
