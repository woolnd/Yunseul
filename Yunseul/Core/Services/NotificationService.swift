//
//  NotificationService.swift
//  Yunseul
//
//  Created by wodnd on 4/12/26.
//

import Foundation
import UserNotifications

final class NotificationService {
    
    static let shared = NotificationService()
    private init() {}
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            print("🔔 [Notification] 권한 허용: \(granted)")
            return granted
        } catch {
            print("🔴 [Notification] 권한 요청 실패: \(error)")
            return false
        }
    }
    
    // MARK: - 권한 상태 확인
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - 매일 밤 9시 별빛 알림 스케줄링
    func scheduleDailyStarNotification(
        constellation: Constellation,
        nickname: String
    ) {
        // 기존 알림 제거
        center.removePendingNotificationRequests(
            withIdentifiers: ["daily_star"]
        )
        
        let content = UNMutableNotificationContent()
        
        let localizedStar = NSLocalizedString("constellation.\(constellation.rawValue).name", comment: "")
        
        content.title = NSLocalizedString("notification.daily.title", comment: "")
        let bodyFormat = NSLocalizedString("notification.daily.body", comment: "")
        content.body = String(format: bodyFormat, nickname, localizedStar)
        content.sound = .default
        
        // 매일 밤 9시
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_star",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("🔴 [Notification] 일일 알림 등록 실패: \(error)")
            } else {
                print("🔔 [Notification] 일일 알림 등록 성공 - 매일 밤 9시")
            }
        }
    }
    
    // MARK: - 사용자의 현재 위치 근처일 때 특별 알림
    func scheduleStarProximityNotification(
        constellation: Constellation,
        nickname: String,
        userLatitude: Double,    // 사용자 위도 추가
        userLongitude: Double,   // 사용자 경도 추가
        subStellarLatitude: Double,
        subStellarLongitude: Double
    ) {
        // 사용자의 현재 위치로부터 반경 약 5도(약 500km) 이내인지 체크
        // 이 정도 범위면 사용자 하늘(천정 근처)에 별이 있다고 볼 수 있습니다.
        let latDiff = abs(userLatitude - subStellarLatitude)
        let lonDiff = abs(userLongitude - subStellarLongitude)
        
        // 경도 180도 경계선 처리 (날짜변경선 근처 보정)
        let adjustedLonDiff = lonDiff > 180 ? 360 - lonDiff : lonDiff
        
        let isNearMe = latDiff < 5.0 && adjustedLonDiff < 5.0
        
        guard isNearMe else { return }
        
        // 중복 알림 방지 (동일 아이디로 등록 시 기존 알림 교체)
        let content = UNMutableNotificationContent()
        let localizedStar = NSLocalizedString("constellation.\(constellation.rawValue).name", comment: "")
        
        content.title = NSLocalizedString("notification.proximity.title", comment: "")
        let bodyFormat = NSLocalizedString("notification.proximity.body", comment: "")
        content.body = String(format: bodyFormat, nickname, localizedStar)
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "star_proximity", // 아이디도 범용적으로 변경
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - 모든 알림 제거
    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("🔔 [Notification] 모든 알림 제거")
    }
}
