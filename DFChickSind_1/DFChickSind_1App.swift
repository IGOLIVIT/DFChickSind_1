//
//  JourneyCraftApp.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
struct JourneyCraftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var locationService = LocationService()
    @StateObject private var userPreferences = UserPreferences()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationService)
                .environmentObject(userPreferences)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenNotificationURL"))) { notification in
                    if let url = notification.userInfo?["url"] as? String {
                        handleNotificationURL(url)
                    }
                }
        }
    }
    
    private func handleNotificationURL(_ url: String) {
        print("📲 ===== NOTIFICATION URL HANDLING =====")
        print("⏰ Handle Time: \(Date())")
        print("🔗 Notification URL: \(url)")
        
        let appState = AppState()
        print("📱 Current App Mode: \(appState.appMode.rawValue)")
        
        appState.currentURL = url
        print("💾 URL saved to AppState")
        
        if appState.appMode != .webView {
            print("🔄 Switching to WebView mode")
            appState.setAppMode(.webView)
        } else {
            print("✅ Already in WebView mode")
        }
        
        PushNotificationService.shared.clearPendingNotificationURL()
        print("🧹 Cleared pending notification URL")
        print("======================================")
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("🚀 ===== APP LAUNCH DEBUG =====")
        print("⏰ Launch Time: \(Date())")
        print("📱 App Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("📱 App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")")
        print("📱 Build Number: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")")
        
        if let launchOptions = launchOptions, !launchOptions.isEmpty {
            print("🔧 Launch Options:")
            for (key, value) in launchOptions {
                print("   \(key.rawValue): \(value)")
            }
        } else {
            print("🔧 No launch options")
        }
        
        // Печатаем конфигурацию из DataManager
        DataManager.printFullStatus()
        
        setupFirebase()
        setupPushNotifications()
        
        print("✅ App launch completed successfully")
        print("===============================")
        return true
    }
    
    private func setupFirebase() {
        print("🔥 ===== FIREBASE SETUP DEBUG =====")
        print("⏰ Setup Time: \(Date())")
        print("🔧 Firebase Project ID: \(DataManager.firebaseProjectID)")
        
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
        
        // Настройка Firebase Messaging
        Messaging.messaging().delegate = self
        print("✅ Firebase Messaging delegate set")
        print("===================================")
    }
    
    private func setupPushNotifications() {
        print("📱 ===== PUSH NOTIFICATIONS SETUP =====")
        print("⏰ Setup Time: \(Date())")
        
        UNUserNotificationCenter.current().delegate = PushNotificationService.shared
        print("✅ Notification center delegate set")
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📋 Current notification settings:")
            print("   Authorization: \(settings.authorizationStatus.rawValue)")
            print("   Alert: \(settings.alertSetting.rawValue)")
            print("   Badge: \(settings.badgeSetting.rawValue)")
            print("   Sound: \(settings.soundSetting.rawValue)")
            
            if settings.authorizationStatus == .authorized {
                print("✅ Notifications authorized - registering for remote notifications")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("⚠️ Notifications not authorized - status: \(settings.authorizationStatus.rawValue)")
            }
        }
        print("======================================")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ ===== REMOTE NOTIFICATIONS REGISTERED =====")
        print("⏰ Registration Time: \(Date())")
        print("📱 Device Token received in AppDelegate")
        print("🔄 Forwarding to PushNotificationService...")
        PushNotificationService.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        print("=============================================")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ ===== REMOTE NOTIFICATIONS REGISTRATION FAILED =====")
        print("⏰ Error Time: \(Date())")
        print("❌ Registration Error: \(error.localizedDescription)")
        print("❌ Error Domain: \((error as NSError).domain)")
        print("❌ Error Code: \((error as NSError).code)")
        print("🔄 Forwarding to PushNotificationService...")
        PushNotificationService.shared.didFailToRegisterForRemoteNotifications(withError: error)
        print("=======================================================")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📲 ===== REMOTE NOTIFICATION RECEIVED IN BACKGROUND =====")
        print("⏰ Receive Time: \(Date())")
        print("📦 Background notification payload: \(userInfo)")
        print("🔄 Forwarding to PushNotificationService...")
        PushNotificationService.shared.handlePushNotification(userInfo)
        print("✅ Completing with .newData")
        completionHandler(.newData)
        print("========================================================")
    }
}

// MARK: - Firebase Messaging Delegate
extension AppDelegate {
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 ===== FIREBASE FCM TOKEN RECEIVED =====")
        print("⏰ Token Time: \(Date())")
        print("🔧 FCM Token: \(fcmToken ?? "nil")")
        
        if let token = fcmToken {
            print("📏 Token Length: \(token.count) characters")
            print("✅ Valid FCM token received")
            print("🔄 Updating token in PushNotificationService...")
            // Сохраняем токен и отправляем на сервер
            PushNotificationService.shared.updateFCMToken(token)
        } else {
            print("❌ FCM token is nil")
        }
        print("=========================================")
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("🔄 ===== FIREBASE FCM TOKEN REFRESHED =====")
        print("⏰ Refresh Time: \(Date())")
        print("🔧 New FCM Token: \(fcmToken)")
        print("📏 Token Length: \(fcmToken.count) characters")
        print("🔄 Updating refreshed token in PushNotificationService...")
        
        // Обновляем токен на сервере
        PushNotificationService.shared.updateFCMToken(fcmToken)
        print("==========================================")
    }
}
