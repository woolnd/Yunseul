//
//  StarCompassView.swift
//  Yunseul
//
//  Created by wodnd on 4/12/26.
//

import SwiftUI
import AVFoundation
import Photos
import Combine
import ComposableArchitecture
internal import CoreData

// MARK: - 카메라 매니저
final class CameraManager: NSObject, ObservableObject {
    
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    var onPhotoCaptured: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    print("[앨범] 권한 상태: \(status.rawValue)")
                }
            }
            
            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ),
            let input = try? AVCaptureDeviceInput(device: device) else { return }
            
            self.session.addInput(input)
            self.session.addOutput(self.photoOutput)
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        onPhotoCaptured = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            onPhotoCaptured?(nil)
            return
        }
        onPhotoCaptured?(image)
    }
}

// MARK: - 카메라 뷰
struct CameraView: UIViewRepresentable {
    
    let manager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: manager.session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - StarCompassView
struct StarCompassView: View {
    
    let homeViewStore: ViewStore<HomeFeature.State, HomeFeature.Action>
    @Bindable var store: Store<StarCompassFeature.State, StarCompassFeature.Action>
    var onJournalSaved: (() -> Void)? = nil
    
    @StateObject private var cameraManager = CameraManager()
    @State private var starOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var showOverwriteOptions: Bool = false
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                CameraView(manager: cameraManager)
                    .ignoresSafeArea()
                
                overlayContent
                
                VStack {
                    headerSection
                    Spacer()
                    bottomSection
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) { starOpacity = 1 }
            withAnimation(.easeIn(duration: 1.2).delay(0.5)) { textOpacity = 1 }
        }
        .onChange(of: store.showOverwriteOptions) { _, newValue in
            showOverwriteOptions = newValue
        }
        .onChange(of: store.showSaveSuccess) { old, new in
            if old == true && new == false {
                onJournalSaved?()
            }
        }
        .confirmationDialog(
            "오늘의 별빛이 이미 기록됐어요",
            isPresented: $showOverwriteOptions,
            titleVisibility: .visible
        ) {
            Button("이미지만 저장") {
                if let image = store.capturedImage {
                    store.send(.imageOnlySelected(image))
                }
            }
            Button("일기 덮어쓰기") {
                if let image = store.capturedImage {
                    store.send(.overwriteSelected(image, homeViewStore.state))
                }
            }
            Button("취소", role: .cancel) {
                store.send(.cancelSelected)
            }
        } message: {
            Text("어떻게 할까요?")
        }
    }
    
    // MARK: - 감성 오버레이
    var overlayContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image(homeViewStore.constellation.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: Color.Yunseul.starBlue.opacity(0.8), radius: 20)
                .opacity(starOpacity)
            
            Spacer().frame(height: 24)
            
            VStack(spacing: 6) {
                Text(homeViewStore.constellation.rawValue)
                    .font(.Yunseul.constellationName)
                    .foregroundColor(.white)
                    .tracking(6)
                    .shadow(color: Color.Yunseul.starBlue.opacity(0.6), radius: 8)
                
                Text(homeViewStore.constellation.latinName)
                    .font(.Yunseul.constellationSub)
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(4)
            }
            .opacity(textOpacity)
            
            Spacer().frame(height: 20)
            
            Text(homeViewStore.briefingText)
                .font(.Yunseul.briefingSmall)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)
                .opacity(textOpacity)
            
            Spacer().frame(height: 16)
            
            Text(currentDateString)
                .font(.Yunseul.captionLight)
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
                .opacity(textOpacity)
            
            Spacer().frame(height: 180)
        }
    }
    
    // MARK: - 헤더
    private var headerSection: some View {
        ZStack {
            Text("별과 함께 하늘 찍기")
                .font(.Yunseul.callout)
                .foregroundColor(.white)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack {
                Button {
                    homeViewStore.send(.compassModeClose)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(8)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 60)
        .padding(.bottom, 16)
    }
    
    // MARK: - 하단 버튼
    private var bottomSection: some View {
        VStack(spacing: 12) {
            if store.showSaveSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.Yunseul.liveGreen)
                    Text("앨범에 저장됐어요")
                        .font(.Yunseul.footnote)
                        .foregroundColor(.white)
                }
                .transition(.opacity)
            }
            
            Button {
                captureAndSave()
            } label: {
                HStack(spacing: 8) {
                    if store.isSaving {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                    }
                    Text(store.isSaving ? "저장 중..." : "앨범 저장")
                        .font(.Yunseul.callout)
                        .tracking(1)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.Yunseul.starBlue.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.Yunseul.starBlue.opacity(0.6), lineWidth: 0.5)
                        )
                )
            }
            .disabled(store.isSaving)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - 촬영 후 저장 분기
    private func captureAndSave() {
        store.send(.captureAndSave(homeViewStore.state))
        
        cameraManager.capturePhoto { cameraImage in
            DispatchQueue.main.async {
                guard let cameraImage else {
                    self.store.send(.captureFailed)
                    return
                }
                let final = self.compositeImage(cameraPhoto: cameraImage)
                self.store.send(.photoCaptured(final, self.homeViewStore.state))
            }
        }
    }
    
    // MARK: - 사진 + 오버레이 합성
    private func compositeImage(cameraPhoto: UIImage) -> UIImage {
        let screenSize = UIScreen.main.bounds.size
        let renderer = UIGraphicsImageRenderer(size: screenSize)
        
        return renderer.image { _ in
            let photoAspect = cameraPhoto.size.width / cameraPhoto.size.height
            let screenAspect = screenSize.width / screenSize.height
            
            var drawRect = CGRect.zero
            if photoAspect > screenAspect {
                let drawHeight = screenSize.height
                let drawWidth = drawHeight * photoAspect
                drawRect = CGRect(
                    x: -(drawWidth - screenSize.width) / 2,
                    y: 0, width: drawWidth, height: drawHeight
                )
            } else {
                let drawWidth = screenSize.width
                let drawHeight = drawWidth / photoAspect
                drawRect = CGRect(
                    x: 0,
                    y: -(drawHeight - screenSize.height) / 2,
                    width: drawWidth, height: drawHeight
                )
            }
            cameraPhoto.draw(in: drawRect)
            
            let overlayVC = UIHostingController(
                rootView: OverlaySnapshotView(
                    constellation: homeViewStore.constellation,
                    briefingText: homeViewStore.briefingText,
                    dateString: currentDateString
                )
            )
            overlayVC.view.frame = CGRect(origin: .zero, size: screenSize)
            overlayVC.view.backgroundColor = .clear
            
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first
            
            window?.addSubview(overlayVC.view)
            overlayVC.view.drawHierarchy(
                in: CGRect(origin: .zero, size: screenSize),
                afterScreenUpdates: true
            )
            overlayVC.view.removeFromSuperview()
        }
    }
    
    // MARK: - 날짜
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }
}

// MARK: - 오버레이 전용 뷰
struct OverlaySnapshotView: View {
    let constellation: Constellation
    let briefingText: String
    let dateString: String
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                
                Image(constellation.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 120)
                    .shadow(color: Color.Yunseul.starBlue.opacity(0.9), radius: 24)
                
                Spacer().frame(height: 24)
                
                Text(constellation.rawValue)
                    .font(.Yunseul.constellationName)
                    .foregroundColor(.white)
                    .tracking(6)
                    .shadow(color: Color.Yunseul.starBlue.opacity(0.8), radius: 12)
                
                Text(constellation.latinName)
                    .font(.Yunseul.constellationSub)
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(4)
                    .padding(.top, 6)
                
                Spacer().frame(height: 20)
                
                Rectangle()
                    .frame(width: 0.5, height: 30)
                    .foregroundColor(.white.opacity(0.3))
                
                Spacer().frame(height: 20)
                
                Text(briefingText)
                    .font(.Yunseul.briefingSmall)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 40)
                
                Spacer().frame(height: 20)
                
                VStack(spacing: 6) {
                    Text(dateString)
                        .font(.Yunseul.captionLight)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)
                    
                    Text("✦ YUNSEUL")
                        .font(.Yunseul.captionLight)
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(4)
                }
                
                Spacer().frame(height: 100)
            }
        }
        .background(Color.clear)
    }
}
