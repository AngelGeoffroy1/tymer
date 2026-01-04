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

// MARK: - Video Storage Manager
class VideoStorageManager {
    static let shared = VideoStorageManager()

    private let fileManager = FileManager.default

    private var videosDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosPath = documentsPath.appendingPathComponent("CapturedVideos", isDirectory: true)

        if !fileManager.fileExists(atPath: videosPath.path) {
            try? fileManager.createDirectory(at: videosPath, withIntermediateDirectories: true)
        }

        return videosPath
    }

    /// Génère une URL temporaire pour l'enregistrement vidéo
    func generateTempVideoURL() -> URL {
        let videoId = UUID().uuidString
        return videosDirectory.appendingPathComponent("\(videoId).mp4")
    }

    /// Sauvegarde une vidéo depuis une URL temporaire et retourne son identifiant
    func saveVideo(from tempURL: URL) -> String? {
        let videoId = UUID().uuidString
        let fileName = "\(videoId).mp4"
        let destinationURL = videosDirectory.appendingPathComponent(fileName)

        do {
            // Si le fichier existe déjà à destination, le supprimer
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Déplacer le fichier temp vers la destination finale
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            print("🎬 Vidéo sauvegardée: \(fileName)")
            return videoId
        } catch {
            print("🎬 Erreur lors de la sauvegarde vidéo: \(error)")
            return nil
        }
    }

    /// Récupère l'URL d'une vidéo sauvegardée
    func getVideoURL(withId videoId: String) -> URL? {
        let fileName = "\(videoId).mp4"
        let fileURL = videosDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("🎬 Vidéo non trouvée: \(fileName)")
            return nil
        }

        return fileURL
    }

    /// Supprime une vidéo
    func deleteVideo(withId videoId: String) {
        let fileName = "\(videoId).mp4"
        let fileURL = videosDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }

    /// Génère une thumbnail à partir d'une vidéo
    func generateThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 600, height: 600)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("🎬 Erreur génération thumbnail: \(error)")
            return nil
        }
    }

    /// Récupère la durée d'une vidéo
    func getVideoDuration(from videoURL: URL) -> TimeInterval {
        let asset = AVAsset(url: videoURL)
        return CMTimeGetSeconds(asset.duration)
    }
}

// MARK: - Flash Mode
enum FlashMode: Int, CaseIterable {
    case off = 0
    case on = 1
    case auto = 2

    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }

    var iconName: String {
        switch self {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        }
    }

    func next() -> FlashMode {
        let allCases = FlashMode.allCases
        let nextIndex = (self.rawValue + 1) % allCases.count
        return allCases[nextIndex]
    }
}

// MARK: - Capture Mode
enum CaptureMode: String, CaseIterable {
    case photo
    case video
    
    var displayName: String {
        switch self {
        case .photo: return "PHOTO"
        case .video: return "VIDÉO"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .photo: return .yellow
        case .video: return .red
        }
    }
}

// MARK: - Camera Service (Live Preview + Capture)
class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var capturedVideoURL: URL?
    @Published var capturedVideoDuration: TimeInterval = 0
    @Published var isSessionRunning = false
    @Published var permissionGranted = false
    @Published var microphonePermissionGranted = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var isUltraWideActive = false
    @Published var flashMode: FlashMode = .off
    @Published var isCapturing = false
    @Published var captureMode: CaptureMode = .photo
    @Published var isRecordingVideo = false
    @Published var videoRecordingProgress: Double = 0  // 0.0 à 1.0 (3 secondes)
    
    static let maxVideoDuration: TimeInterval = 3.0  // Durée max vidéo

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var photoOutput = AVCapturePhotoOutput()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var currentVideoInput: AVCaptureDeviceInput?
    private var currentAudioInput: AVCaptureDeviceInput?
    private var videoRecordingTimer: Timer?
    private var recordingStartTime: Date?

    override init() {
        super.init()
        checkPermission()
        checkMicrophonePermission()
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

    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                }
            }
        default:
            microphonePermissionGranted = false
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            
            // Utiliser un preset qui supporte à la fois photo et vidéo
            self.session.sessionPreset = .high

            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoInput) else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(videoInput)
            self.currentVideoInput = videoInput

            // Add audio input for video recording
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
                self.currentAudioInput = audioInput
            }

            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            // Add movie output
            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
                // Configurer la durée maximale
                self.movieOutput.maxRecordedDuration = CMTime(seconds: CameraService.maxVideoDuration + 0.5, preferredTimescale: 600)
            }

            self.session.commitConfiguration()
        }
    }

    // MARK: - Switch Camera (Front/Back)
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            // Remove current input
            if let currentInput = self.currentVideoInput {
                self.session.removeInput(currentInput)
            }

            // Toggle position
            let newPosition: AVCaptureDevice.Position = self.currentCameraPosition == .back ? .front : .back

            // Get new device
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice),
                  self.session.canAddInput(newInput) else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(newInput)
            self.currentVideoInput = newInput

            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.currentCameraPosition = newPosition
                self.isUltraWideActive = false
            }

            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
            DispatchQueue.main.async {
                impactGenerator.impactOccurred()
            }
        }
    }

    // MARK: - Switch to Ultra Wide Angle
    func switchToUltraWide() {
        // Ultra wide only available on back camera
        guard currentCameraPosition == .back else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            // Remove current input
            if let currentInput = self.currentVideoInput {
                self.session.removeInput(currentInput)
            }

            // Try to get ultra wide camera
            let deviceType: AVCaptureDevice.DeviceType = self.isUltraWideActive ? .builtInWideAngleCamera : .builtInUltraWideCamera

            guard let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: .back),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice),
                  self.session.canAddInput(newInput) else {
                // Fallback to wide angle if ultra wide not available
                if let wideDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                   let wideInput = try? AVCaptureDeviceInput(device: wideDevice),
                   self.session.canAddInput(wideInput) {
                    self.session.addInput(wideInput)
                    self.currentVideoInput = wideInput
                }
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(newInput)
            self.currentVideoInput = newInput

            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.isUltraWideActive = !self.isUltraWideActive
            }

            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
            DispatchQueue.main.async {
                impactGenerator.impactOccurred()
            }
        }
    }

    // MARK: - Check if Ultra Wide is Available
    var isUltraWideAvailable: Bool {
        return AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil
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

    // MARK: - Flash Control
    func toggleFlash() {
        flashMode = flashMode.next()

        // Haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
    }

    var isFlashAvailable: Bool {
        guard let device = currentVideoInput?.device else { return false }
        return device.hasFlash && device.isFlashAvailable
    }

    func capturePhoto() {
        guard !isCapturing else { return }

        DispatchQueue.main.async {
            self.isCapturing = true
        }

        let settings = AVCapturePhotoSettings()

        // Set flash mode based on current setting
        if photoOutput.supportedFlashModes.contains(flashMode.avFlashMode) {
            settings.flashMode = flashMode.avFlashMode
        } else {
            settings.flashMode = .off
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Video Recording
    
    func startVideoRecording() {
        guard captureMode == .video else { return }
        guard !isRecordingVideo else { return }
        guard !movieOutput.isRecording else { return }
        
        let outputURL = VideoStorageManager.shared.generateTempVideoURL()
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Configure torch for video if flash is on
            if self.flashMode == .on, let device = self.currentVideoInput?.device {
                try? device.lockForConfiguration()
                if device.hasTorch && device.isTorchAvailable {
                    device.torchMode = .on
                }
                device.unlockForConfiguration()
            }
            
            self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            
            DispatchQueue.main.async {
                self.isRecordingVideo = true
                self.recordingStartTime = Date()
                self.videoRecordingProgress = 0
                
                // Haptic feedback
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
                
                // Start progress timer
                self.videoRecordingTimer?.invalidate()
                self.videoRecordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                    guard let self = self, let startTime = self.recordingStartTime else { return }
                    let elapsed = Date().timeIntervalSince(startTime)
                    self.videoRecordingProgress = min(elapsed / CameraService.maxVideoDuration, 1.0)
                    
                    // Auto-stop after max duration
                    if elapsed >= CameraService.maxVideoDuration {
                        self.stopVideoRecording()
                    }
                }
            }
        }
    }
    
    func stopVideoRecording() {
        guard isRecordingVideo else { return }
        
        videoRecordingTimer?.invalidate()
        videoRecordingTimer = nil
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
            
            // Turn off torch
            if let device = self.currentVideoInput?.device {
                try? device.lockForConfiguration()
                if device.hasTorch {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            }
        }
        
        DispatchQueue.main.async {
            self.isRecordingVideo = false
            self.videoRecordingProgress = 0
            self.recordingStartTime = nil
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    func toggleCaptureMode() {
        let newMode: CaptureMode = captureMode == .photo ? .video : .photo
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            captureMode = newMode
        }
        
        // Haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
    }
    
    /// Reset captured media
    func resetCapture() {
        capturedImage = nil
        capturedVideoURL = nil
        capturedVideoDuration = 0
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            self.isCapturing = false
        }

        guard error == nil, let imageData = photo.fileDataRepresentation() else {
            print("Erreur capture photo: \(error?.localizedDescription ?? "unknown")")
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = UIImage(data: imageData)
        }
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecordingVideo = false
            self.videoRecordingProgress = 0
        }
        
        if let error = error {
            print("🎬 Erreur enregistrement vidéo: \(error.localizedDescription)")
            return
        }
        
        // Calculer la durée réelle de la vidéo
        let duration = VideoStorageManager.shared.getVideoDuration(from: outputFileURL)
        
        DispatchQueue.main.async {
            self.capturedVideoURL = outputFileURL
            self.capturedVideoDuration = min(duration, CameraService.maxVideoDuration)
            print("🎬 Vidéo capturée: \(outputFileURL.lastPathComponent), durée: \(String(format: "%.1f", duration))s")
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("🎬 Enregistrement démarré: \(fileURL.lastPathComponent)")
    }
}

// MARK: - Camera Preview View (Live Feed)
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var onDoubleTap: (() -> Void)?
    var onPinchOut: (() -> Void)?

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        // Double tap gesture for switching camera
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        // Pinch gesture for ultra wide
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch))
        view.addGestureRecognizer(pinchGesture)

        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDoubleTap: onDoubleTap, onPinchOut: onPinchOut)
    }

    class Coordinator: NSObject {
        var onDoubleTap: (() -> Void)?
        var onPinchOut: (() -> Void)?
        private var hasTriggered = false

        init(onDoubleTap: (() -> Void)?, onPinchOut: (() -> Void)?) {
            self.onDoubleTap = onDoubleTap
            self.onPinchOut = onPinchOut
        }

        @objc func handleDoubleTap() {
            onDoubleTap?()
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                hasTriggered = false
            case .changed:
                // Detect pinch in (zoom out / dezoom) - like BeReal
                // When fingers come together, scale decreases below 1.0
                if gesture.scale < 0.75 && !hasTriggered {
                    hasTriggered = true
                    onPinchOut?()
                }
            case .ended, .cancelled:
                hasTriggered = false
            default:
                break
            }
        }
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
