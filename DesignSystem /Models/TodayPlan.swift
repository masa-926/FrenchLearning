// Models/TodayPlan.swift
import Foundation

public struct TodayPlan: Equatable, Codable {
    public var newIDs: [String]        // 今日はじめて学ぶ
    public var reviewIDs: [String]     // 期限が来た復習
    public var relearnIDs: [String]    // 間違えた語の再学習

    public init(newIDs: [String] = [], reviewIDs: [String] = [], relearnIDs: [String] = []) {
        self.newIDs = newIDs
        self.reviewIDs = reviewIDs
        self.relearnIDs = relearnIDs
    }

    public var isEmpty: Bool { newIDs.isEmpty && reviewIDs.isEmpty && relearnIDs.isEmpty }
}

