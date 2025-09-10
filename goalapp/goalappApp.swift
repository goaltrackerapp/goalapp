//
//  goalappApp.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI

@main
struct goalappApp: App {
    
    @StateObject private var store = GoalStore()
    @StateObject private var achievementsManagerRef: AchievementsManager

    @Environment(\.scenePhase) private var scenePhase
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        NotificationCenter.default.post(name: Notification.Name("art.icon.loading.start"), object: nil)
        IconSettings.shared.attach()
        // Инициализация AchievementsManager с доступом к GoalStore
        let tempStore = GoalStore()
        _store = StateObject(wrappedValue: tempStore)
        _achievementsManagerRef = StateObject(wrappedValue: AchievementsManager(store: tempStore))
    }

    var body: some Scene {
        WindowGroup {
            TabSettingsView{
                RootTabView(achievementsManager: achievementsManagerRef)
                    .environmentObject(store)
                
            }
            
            
                .onAppear {
                    OrientationGate.allowAll = false
                }
            
            
            
        }
        
    }
    
    
    
    
    
    
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            if OrientationGate.allowAll {
                return [.portrait, .landscapeLeft, .landscapeRight]
            } else {
                return [.portrait]
            }
        }
    }
    
    
}
