//
//  CameraManager.swift
//  Tymer
//
//  Created by Angel Geoffroy on 26/12/2025.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Camera Permission Manager
class CameraPermissionManager {
    static let shared = CameraPermissionManager()

    func checkPermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        let status = checkPermission()

        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

// MARK: - Image Storage Manager
class ImageStorageManager {
    static let shared = ImageStorageManager()

    private let fileManager = FileManager.default

    private var momentsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let momentsPath = documentsPath.appendingPathComponent("CapturedMoments", isDirectory: true)

        if !fileManager.fileExists(atPath: momentsPath.path) {
            try? fileManager.createDirectory(at: momentsPath, withIntermediateDirectories: true)
        }

        return momentsPath
    }

    /// Sauvegarde une image et retourne son identifiant unique
    func saveImage(_ image: UIImage) -> String? {
        let imageId = UUID().uuidString
        let fileName = "\(imageId).jpg"
        let fileURL = momentsDirectory.appendingPathComponent(fileName)

        // Compresser l'image en JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Erreur: Impossible de convertir l'image en JPEG")
            return nil
        }

        do {
            try imageData.write(to: fileURL)
            print("Image sauvegardée: \(fileName)")
            return imageId
        } catch {
            print("Erreur lors de la sauvegarde: \(error)")
            return nil
        }
    }

    /// Charge une image à partir de son identifiant
    func loadImage(withId imageId: String) -> UIImage? {
        let fileName = "\(imageId).jpg"
        let fileURL = momentsDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Image non trouvée: \(fileName)")
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    /// Supprime une image
    func deleteImage(withId imageId: String) {
        let fileName = "\(imageId).jpg"
        let fileURL = momentsDirectory.appendingPathComponent(fileName)

        try? fileManager.removeItem(at: fileURL)
    }
}

// MARK: - Camera Service (Live Preview + Capture)
class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false
    @Published var permissionGranted = false

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var photoOutput = AVCapturePhotoOutput()

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        default:
            permissionGranted = false
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoInput) else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(videoInput)

            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let imageData = photo.fileDataRepresentation() else {
            print("Erreur capture photo: \(error?.localizedDescription ?? "unknown")")
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = UIImage(data: imageData)
        }
    }
}

// MARK: - Camera Preview View (Live Feed)
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper - fallback)
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Extended PhotoLoader
extension PhotoLoader {
    /// Charge une image depuis le stockage des moments capturés
    static func loadCapturedImage(withId imageId: String) -> UIImage? {
        return ImageStorageManager.shared.loadImage(withId: imageId)
    }
}
