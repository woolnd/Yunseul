//
//  StarCompassFeature.swift
//  Yunseul
//
//  Created by wodnd on 4/13/26.
//

import ComposableArchitecture
import Photos
import UIKit
internal import CoreData

@Reducer
struct StarCompassFeature {
    
    @ObservableState
    struct State: Equatable {
        var isSaving: Bool = false
        var showSaveSuccess: Bool = false
        var showOverwriteOptions: Bool = false
        var capturedImage: UIImage? = nil
        
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.isSaving == rhs.isSaving &&
            lhs.showSaveSuccess == rhs.showSaveSuccess &&
            lhs.showOverwriteOptions == rhs.showOverwriteOptions &&
            (lhs.capturedImage == nil) == (rhs.capturedImage == nil)
        }
    }
    
    enum Action: Equatable {
        case captureAndSave(HomeFeature.State)
        case photoCaptured(UIImage, HomeFeature.State)
        case captureFailed
        case overwriteSelected(UIImage, HomeFeature.State)
        case imageOnlySelected(UIImage)
        case cancelSelected
        case albumSaveCompleted(Bool, UIImage?, HomeFeature.State?)
        case journalSaved
        case showSuccessBanner
        case hideSuccessBanner
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .captureAndSave:
                state.isSaving = true
                return .none
                
            case let .photoCaptured(image, homeState):
                state.isSaving = false
                state.capturedImage = image
                if CoreDataService.shared.fetchJournalEntry(for: Date()) != nil {
                    state.showOverwriteOptions = true
                    return .none
                }
                return .send(.albumSaveCompleted(false, image, homeState))
                
            case .captureFailed:
                state.isSaving = false
                return .none
                
            case let .overwriteSelected(image, homeState):
                state.showOverwriteOptions = false
                state.capturedImage = nil
                return .run { send in
                    // 기존 일기 삭제
                    if let existing = CoreDataService.shared.fetchJournalEntry(for: Date()) {
                        if let photoPath = existing.photoPath, !photoPath.isEmpty {
                            let url = FileManager.default.urls(
                                for: .documentDirectory,
                                in: .userDomainMask
                            )[0].appendingPathComponent(photoPath)
                            try? FileManager.default.removeItem(at: url)
                        }
                        await CoreDataService.shared.context.delete(existing)
                        try? CoreDataService.shared.context.save()
                    }
                    let success = await saveToAlbum(image: image)
                    await send(.albumSaveCompleted(success, image, homeState))
                }
                
            case let .imageOnlySelected(image):
                state.showOverwriteOptions = false
                state.capturedImage = nil
                return .run { send in
                    let success = await saveToAlbum(image: image)
                    await send(.albumSaveCompleted(success, nil, nil))
                }
                
            case .cancelSelected:
                state.showOverwriteOptions = false
                state.capturedImage = nil
                return .none
                
            case let .albumSaveCompleted(success, image, homeState):
                guard success else { return .none }
                if let image, let homeState {
                    return .run { send in
                        await saveJournalEntry(image: image, homeState: homeState)
                        await send(.journalSaved)
                        await send(.showSuccessBanner)
                    }
                }
                return .send(.showSuccessBanner)
                
            case .journalSaved:
                return .none
                
            case .showSuccessBanner:
                state.showSaveSuccess = true
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await send(.hideSuccessBanner)
                }
                
            case .hideSuccessBanner:
                state.showSaveSuccess = false
                return .none
            }
        }
    }
}

// MARK: - 헬퍼 함수
private func saveToAlbum(image: UIImage) async -> Bool {
    await withCheckedContinuation { continuation in
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                continuation.resume(returning: false)
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

private func saveJournalEntry(image: UIImage, homeState: HomeFeature.State) async {
    let astronomyService = AstronomyService.shared
    
    let distance = astronomyService.distanceKm(
        userLat: homeState.userLatitude,
        userLon: homeState.userLongitude,
        starLat: homeState.subStellarLatitude,
        starLon: homeState.subStellarLongitude
    )
    let direction = astronomyService.directionString(from: homeState.starAzimuth)
    let userRegion = await astronomyService.regionName(
        latitude: homeState.userLatitude,
        longitude: homeState.userLongitude
    )
    let starRegion = homeState.cachedRegionName.isEmpty
        ? await astronomyService.regionName(
            latitude: homeState.subStellarLatitude,
            longitude: homeState.subStellarLongitude
          )
        : homeState.cachedRegionName
    
    let photoPath = saveImageToDocuments(image: image) ?? ""
    
    CoreDataService.shared.saveJournalEntry(
        date: Date(),
        constellation: homeState.constellation.rawValue,
        starLatitude: homeState.subStellarLatitude,
        starLongitude: homeState.subStellarLongitude,
        starRegionName: starRegion,
        userLatitude: homeState.userLatitude,
        userLongitude: homeState.userLongitude,
        userRegionName: userRegion,
        starAltitude: homeState.starAltitude,
        starAzimuth: homeState.starAzimuth,
        distanceKm: distance,
        starDirection: direction,
        photoPath: photoPath,
        memo: nil
    )
    
    print("✦ [Journal] 저장 완료 - \(direction) / \(distance)km / \(photoPath)")
}

private func saveImageToDocuments(image: UIImage) -> String? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    let fileName = "journal_\(formatter.string(from: Date())).jpg"
    
    guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
    
    let url = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0].appendingPathComponent(fileName)
    
    try? data.write(to: url)
    return fileName
}
