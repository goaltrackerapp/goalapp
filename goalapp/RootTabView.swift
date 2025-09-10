//
//  RootTabView.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var store: GoalStore
    @ObservedObject var achievementsManager: AchievementsManager
    @ObservedObject private var prefs = AppPreferences.shared

    enum Tab {
        case goals
        case achievements
        case settings
    }

    @State private var selection: Tab = .goals

    var body: some View {
        TabView(selection: $selection) {
            GoalListView()
                .tabItem {
                    Label("Goals", systemImage: "circle.dashed.inset.filled")
                }
                .tag(Tab.goals)

            AchievementsView(manager: achievementsManager)
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }
                .tag(Tab.achievements)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }
}
