//
//  PassportView.swift
//  Yunseul
//
//  Created by wodnd on 4/10/26.
//

import SwiftUI
import ComposableArchitecture

struct TracesView: View {
    
    @State private var selectedTab: Int = 0
    @State private var trailEntries: [StarTrailEntry] = []
    
    var body: some View {
        ZStack {
            Color.Yunseul.background.ignoresSafeArea()
            NebulaView()
            
            VStack(spacing: 0) {
                // 헤더
                headerSection
                
                // 탭 선택
                tabSelector
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // 탭 컨텐츠
                if selectedTab == 0 {
                    globeSection
                } else {
                    ScrollView(showsIndicators: false) {
                        StarJournalView()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            trailEntries = CoreDataService.shared.fetchAllTrailEntries()
        }
    }
    
    // MARK: - 헤더
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("별자취")
                .font(.Yunseul.appTitle)
                .foregroundColor(Color.Yunseul.textPrimary)
                .tracking(6)
            
            Text("별이 지나온 길")
                .font(.Yunseul.captionLight)
                .foregroundColor(Color.Yunseul.textTertiary)
                .tracking(2)
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    // MARK: - 탭 선택
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "별의 궤적", index: 0)
            tabButton(title: "별빛 일기", index: 1)
        }
        .background(Color.Yunseul.elevated)
        .cornerRadius(12)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            Text(title)
                .font(.Yunseul.footnote)
                .foregroundColor(
                    selectedTab == index
                    ? Color.Yunseul.starBlue
                    : Color.Yunseul.textTertiary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedTab == index
                              ? Color.Yunseul.surface
                              : Color.clear)
                        .padding(3)
                )
        }
    }
    
    // MARK: - 지구본 섹션
    private var globeSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                
                // 지구본
                StarTrailGlobeView(trailEntries: trailEntries)
                    .frame(height: 360)
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                
                // 안내 텍스트
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.Yunseul.starBlue)
                        
                        Text("매일 밤 9시 기준으로 기록돼요")
                            .font(.Yunseul.captionLight)
                            .foregroundColor(Color.Yunseul.textSecondary)
                    }
                    
                    // 오늘 9시 이전이면 안내
                    if !isPast9PM() {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundColor(Color.Yunseul.textTertiary)
                            
                            Text("오늘 기록은 밤 9시에 추가돼요")
                                .font(.Yunseul.captionLight)
                                .foregroundColor(Color.Yunseul.textTertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                // 궤적 수
                HStack {
                    Text("✦ \(trailEntries.count)일의 궤적")
                        .font(.Yunseul.caption)
                        .foregroundColor(Color.Yunseul.textTertiary)
                        .tracking(2)
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // 월별 타임라인
                trailTimeline
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - 밤 9시 지났는지 확인
    private func isPast9PM() -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let hour = calendar.component(.hour, from: Date())
        return hour >= 21
    }

    // MARK: - 월별 타임라인
    private var trailTimeline: some View {
        let grouped = groupByMonth(entries: trailEntries)
        
        return VStack(alignment: .leading, spacing: 24) {
            ForEach(grouped.keys.sorted(by: >), id: \.self) { month in
                VStack(alignment: .leading, spacing: 12) {
                    // 월 헤더
                    Text(month)
                        .font(.Yunseul.caption)
                        .foregroundColor(Color.Yunseul.starBlue)
                        .tracking(2)
                    
                    // 날짜별 항목
                    VStack(spacing: 0) {
                        ForEach(grouped[month] ?? [], id: \.objectID) { entry in
                            timelineRow(entry: entry)
                        }
                    }
                    .background(Color.Yunseul.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.Yunseul.border.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
        }
    }

    // MARK: - 타임라인 행
    private func timelineRow(entry: StarTrailEntry) -> some View {
        HStack(spacing: 14) {
            // 날짜
            VStack(spacing: 2) {
                Text(dayString(from: entry.date ?? Date()))
                    .font(.Yunseul.title3)
                    .foregroundColor(Color.Yunseul.starBlue)
                
                Text(weekdayString(from: entry.date ?? Date()))
                    .font(.Yunseul.captionLight)
                    .foregroundColor(Color.Yunseul.textTertiary)
            }
            .frame(width: 36)
            
            // 점 + 선
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.Yunseul.starBlue.opacity(0.6))
                    .frame(width: 8, height: 8)
            }
            
            // 지역명
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.regionName ?? "")
                    .font(.Yunseul.footnote)
                    .foregroundColor(Color.Yunseul.textPrimary)
                
                Text(String(format: "%.1f°N  %.1f°E",
                            abs(entry.latitude),
                            abs(entry.longitude)))
                    .font(.Yunseul.captionLight)
                    .foregroundColor(Color.Yunseul.textTertiary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(Color.Yunseul.border.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - 월별 그룹화
    private func groupByMonth(entries: [StarTrailEntry]) -> [String: [StarTrailEntry]] {
        var grouped: [String: [StarTrailEntry]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        formatter.locale = Locale(identifier: "ko_KR")
        
        for entry in entries {
            let key = formatter.string(from: entry.date ?? Date())
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(entry)
        }
        
        // 각 월 내에서 날짜 내림차순 정렬
        for key in grouped.keys {
            grouped[key]?.sort { ($0.date ?? Date()) > ($1.date ?? Date()) }
        }
        
        return grouped
    }

    // MARK: - 날짜 포맷
    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }

    private func weekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

#Preview {
    TracesView()
}
