//
//  StarRelationView.swift
//  Yunseul
//
//  Created by wodnd on 4/12/26.
//

import SwiftUI

struct StarRelationView: View {
    
    let constellation: Constellation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 섹션 헤더
            HStack {
                Text("별자리 관계도")
                    .font(.Yunseul.caption)
                    .foregroundColor(Color.Yunseul.textTertiary)
                    .tracking(2)
                
                Spacer()
                
                Text(constellation.latinName)
                    .font(.custom("Georgia-Italic", size: 11))
                    .foregroundColor(Color.Yunseul.textTertiary)
                    .tracking(1)
            }
            
            // 관계 카드들
            VStack(spacing: 10) {
                ForEach(Array(constellation.relations.enumerated()), id: \.offset) { _, relation in
                    relationCard(relation: relation)
                }
            }
        }
    }
    
    // MARK: - 관계 카드
    private func relationCard(relation: StarRelation) -> some View {
        HStack(spacing: 14) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(Color.Yunseul.elevated)
                    .frame(width: 40, height: 40)
                
                Image(systemName: relation.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color.Yunseul.starBlue)
            }
            
            // 텍스트
            VStack(alignment: .leading, spacing: 3) {
                Text(relation.type)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.Yunseul.textTertiary)
                    .tracking(0.5)
                
                Text(relation.constellation)
                    .font(.custom("Georgia", size: 15))
                    .foregroundColor(Color.Yunseul.textPrimary)
                
                Text(relation.description)
                    .font(.custom("Georgia-Italic", size: 12))
                    .foregroundColor(Color.Yunseul.textSecondary)
                    .lineSpacing(3)
            }
            
            Spacer()
            
            // 연결선 장식
            VStack(spacing: 3) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.Yunseul.border.opacity(0.4))
                        .frame(width: 3, height: 3)
                }
            }
        }
        .padding(14)
        .background(Color.Yunseul.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Yunseul.border.opacity(0.3), lineWidth: 0.5)
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "04060E").ignoresSafeArea()
        ScrollView {
            StarRelationView(constellation: .aries)
                .padding(20)
        }
    }
}
