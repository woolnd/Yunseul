//
//  SettingsView.swift
//  Yunseul
//
//  Created by wodnd on 4/10/26.
//

import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    
    @Bindable var store: Store<SettingsFeature.State, SettingsFeature.Action>
    @State private var isNicknameSheetPresented: Bool = false
    @State private var isBirthDateSheetPresented: Bool = false
    
    var body: some View {
        ZStack {
            Color.Yunseul.background.ignoresSafeArea()
            NebulaView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    profileSection
                    notificationSection
                    appInfoSection
                    Spacer().frame(height: 100)
                }
                .padding(.top, 60)
            }
        }
        .sheet(isPresented: $isNicknameSheetPresented) {
            nicknameSheet
        }
        .sheet(isPresented: $isBirthDateSheetPresented) {
            birthDateSheet
        }
        .onChange(of: store.isNicknameSheetPresented) { _, newValue in
            isNicknameSheetPresented = newValue
        }
        .onChange(of: store.isBirthDateSheetPresented) { _, newValue in
            isBirthDateSheetPresented = newValue
        }
        .onChange(of: isNicknameSheetPresented) { _, newValue in
            if !newValue { store.send(.nicknameSheetDismissed) }
        }
        .onChange(of: isBirthDateSheetPresented) { _, newValue in
            if !newValue { store.send(.birthDateSheetDismissed) }
        }
    }
    
    // MARK: - 헤더
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("설정")
                .font(.Yunseul.appTitle)
                .foregroundColor(Color.Yunseul.textPrimary)
                .tracking(6)
            
            Text("별과의 연결을 관리해요")
                .font(.Yunseul.captionLight)
                .foregroundColor(Color.Yunseul.textTertiary)
                .tracking(2)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - 프로필 섹션
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("✦ 프로필")
            
            VStack(spacing: 0) {
                settingRow(
                    icon: "person.fill",
                    title: "닉네임",
                    value: store.nickname.isEmpty ? "미설정" : store.nickname
                ) {
                    store.send(.nicknameEditTapped)
                }
                
                divider
                
                settingRow(
                    icon: "birthday.cake.fill",
                    title: "생일",
                    value: birthDateString(from: store.birthDate)
                ) {
                    store.send(.birthDateEditTapped)
                }
                
                divider
                
                // 수호성 (읽기 전용)
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.Yunseul.elevated)
                            .frame(width: 36, height: 36)
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(Color.Yunseul.starBlue)
                    }
                    
                    Text("수호성")
                        .font(.Yunseul.footnote)
                        .foregroundColor(Color.Yunseul.textTertiary)
                    
                    Spacer()
                    
                    Text(store.constellation.rawValue)
                        .font(.Yunseul.footnote)
                        .foregroundColor(Color.Yunseul.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color.Yunseul.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.Yunseul.border.opacity(0.3), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 알림 섹션
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("✦ 알림")
            
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.Yunseul.elevated)
                            .frame(width: 36, height: 36)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.Yunseul.starBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("매일 밤 9시 별빛 알림")
                            .font(.Yunseul.footnote)
                            .foregroundColor(Color.Yunseul.textPrimary)
                        Text("수호성이 하늘을 여행하는 시간을 알려드려요")
                            .font(.Yunseul.captionLight)
                            .foregroundColor(Color.Yunseul.textTertiary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { store.isNotificationEnabled },
                        set: { store.send(.notificationToggled($0)) }
                    ))
                    .tint(Color.Yunseul.starBlue)
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color.Yunseul.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.Yunseul.border.opacity(0.3), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 앱 정보 섹션
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("✦ 앱 정보")
            
            VStack(spacing: 0) {
                HStack {
                    Text("버전")
                        .font(.Yunseul.footnote)
                        .foregroundColor(Color.Yunseul.textTertiary)
                    Spacer()
                    Text(appVersion)
                        .font(.Yunseul.footnote)
                        .foregroundColor(Color.Yunseul.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                divider
                
                HStack {
                    Text("만든 사람")
                        .font(.Yunseul.footnote)
                        .foregroundColor(Color.Yunseul.textTertiary)
                    Spacer()
                    Text("wodnd")
                        .font(.Yunseul.footnote)
                        .foregroundColor(Color.Yunseul.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color.Yunseul.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.Yunseul.border.opacity(0.3), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 닉네임 시트
    private var nicknameSheet: some View {
        ZStack {
            Color.Yunseul.background.ignoresSafeArea()
            NebulaView()
            
            VStack(spacing: 24) {
                Text("닉네임 변경")
                    .font(.Yunseul.subheadline)
                    .foregroundColor(Color.Yunseul.textPrimary)
                    .tracking(2)
                    .padding(.top, 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("닉네임을 입력해주세요", text: Binding(
                        get: { store.editingNickname },
                        set: { store.send(.editingNicknameChanged($0)) }
                    ))
                    .font(.Yunseul.subheadline)
                    .foregroundColor(Color.Yunseul.textPrimary)
                    .padding(16)
                    .background(Color.Yunseul.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.Yunseul.starBlue.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 24)
                
                Button {
                    store.send(.saveNickname)
                } label: {
                    Text("저장")
                        .font(.Yunseul.callout)
                        .foregroundColor(Color.Yunseul.starBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.Yunseul.starBlue.opacity(0.3), lineWidth: 0.5)
                        )
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
    
    // MARK: - 생일 시트
    private var birthDateSheet: some View {
        ZStack {
            Color.Yunseul.background.ignoresSafeArea()
            NebulaView()
            
            VStack(spacing: 24) {
                Text("생일 변경")
                    .font(.Yunseul.subheadline)
                    .foregroundColor(Color.Yunseul.textPrimary)
                    .tracking(2)
                    .padding(.top, 32)
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: { store.editingBirthDate },
                        set: { store.send(.editingBirthDateChanged($0)) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))
                
                Button {
                    store.send(.saveBirthDate)
                } label: {
                    Text("저장")
                        .font(.Yunseul.callout)
                        .foregroundColor(Color.Yunseul.starBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.Yunseul.starBlue.opacity(0.3), lineWidth: 0.5)
                        )
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
    
    // MARK: - 공통 컴포넌트
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.Yunseul.caption)
            .foregroundColor(Color.Yunseul.textTertiary)
            .tracking(2)
            .padding(.horizontal, 4)
    }
    
    private func settingRow(
        icon: String,
        title: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.Yunseul.elevated)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.Yunseul.starBlue)
                }
                
                Text(title)
                    .font(.Yunseul.footnote)
                    .foregroundColor(Color.Yunseul.textTertiary)
                
                Spacer()
                
                Text(value)
                    .font(.Yunseul.footnote)
                    .foregroundColor(Color.Yunseul.textPrimary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(Color.Yunseul.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.Yunseul.border.opacity(0.2))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }
    
    // MARK: - 헬퍼
    private func birthDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

#Preview {
    SettingsView(store: Store(initialState: SettingsFeature.State()) {
        SettingsFeature()
    })
}
