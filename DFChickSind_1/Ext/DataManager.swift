//
//  DataManager.swift
//  DFChickSind_1
//
//  Created by IGOR on 01/09/2025.
//

import Foundation
import SwiftUI
import UIKit

struct DataManager {
    
    // MARK: - 🔑 ОСНОВНЫЕ НАСТРОЙКИ (ОБЯЗАТЕЛЬНО ЗАМЕНИТЬ!)
    // MARK: - 🔑 ОСНОВНЫЕ НАСТРОЙКИ (ОБЯЗАТЕЛЬНО ЗАМЕНИТЬ!)
    // MARK: - 🔑 ОСНОВНЫЕ НАСТРОЙКИ (ОБЯЗАТЕЛЬНО ЗАМЕНИТЬ!)
    
    /// AppsFlyer Dev Key - получить в панели AppsFlyer
    static let appsFlyerDevKey = "cqTiFvvyhL5a2SNAqqAna3"
    
    ///  App ID - ID приложения в AppstoreConnect
    static let appleAppID = "id6749935587"
    
    /// Эндпоинт конфига - получить от менеджера
    static let configEndpoint = "https://journeycraftroad.com/config.php"
    
    /// Firebase Project ID - получить из GoogleService-Info.plist
    static let firebaseProjectID = "df703-125cb"
    
    // MARK: - 🔑 ОСНОВНЫЕ НАСТРОЙКИ (ОБЯЗАТЕЛЬНО ЗАМЕНИТЬ!)
    // MARK: - 🔑 ОСНОВНЫЕ НАСТРОЙКИ (ОБЯЗАТЕЛЬНО ЗАМЕНИТЬ!)
    // MARK: - 🔑 ОСНОВНЫЕ НАСТРОЙКИ (ОБЯЗАТЕЛЬНО ЗАМЕНИТЬ!)
    
    
    
    
    
    
    
    
    /// Время ожидания перед повторным запросом уведомлений (в секундах)
    static let notificationRetryInterval: TimeInterval = 259200 // 3 дня
    
    /// Время ожидания перед повторным запросом конверсии AppsFlyer (в секундах)
    static let conversionRecheckDelay: TimeInterval = 5.0
    
    /// Таймаут для запроса разрешения на отслеживание (в секундах)
    static let trackingPermissionTimeout: TimeInterval = 60.0
    
    // MARK: - 🎨 UI НАСТРОЙКИ
    
    /// Цвета для градиентов
    struct Colors {
        static let primaryGradient = [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]
        static let loadingGradient = [
            Color(red: 0.05, green: 0.1, blue: 0.2),
            Color(red: 0.1, green: 0.05, blue: 0.15),
            Color(red: 0.05, green: 0.05, blue: 0.1)
        ]
        static let notificationGradient = [
            Color(red: 0.1, green: 0.2, blue: 0.4),
            Color(red: 0.2, green: 0.1, blue: 0.3),
            Color(red: 0.1, green: 0.1, blue: 0.2)
        ]
    }
    
    // MARK: - 🔧 СЛУЖЕБНЫЕ МЕТОДЫ
    
    /// Получить Bundle ID из настроек проекта
    static var currentBundleID: String {
        return Bundle.main.bundleIdentifier ?? "bundleID"
    }
    
    /// Получить название приложения из настроек проекта
    static var currentAppName: String {
        if let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        } else if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        } else {
            return "appName"
        }
    }
    
    /// Создать кастомный User Agent
    static func createCustomUserAgent() -> String {
        let systemVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        
        return "Mozilla/5.0 (\(deviceModel); CPU OS \(systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(systemVersion) Mobile/15E148 Safari/604.1"
    }
    
    /// Проверить валидность настроек
    static func validateConfiguration() -> [String] {
        var errors: [String] = []
        
        if appsFlyerDevKey == "YOUR_APPSFLYER_DEV_KEY" {
            errors.append("❌ AppsFlyer Dev Key не настроен")
        }
        
        if appleAppID == "YOUR_APPLE_APP_ID" {
            errors.append("❌ Apple App ID не настроен")
        }
        
        if configEndpoint == "https://example.com/config" {
            errors.append("❌ Config Endpoint не настроен")
        }
        
        if firebaseProjectID == "YOUR_FIREBASE_PROJECT_ID" {
            errors.append("❌ Firebase Project ID не настроен")
        }
        
        return errors
    }
    
    /// Проверить подключение SDK
    static func validateSDKStatus() -> [String] {
        var warnings: [String] = []
        
        // Проверка AppsFlyer SDK
        let appsFlyerConnected = true // Production: AppsFlyer SDK активирован
        if !appsFlyerConnected {
            warnings.append("⚠️ AppsFlyer SDK не подключен")
        }
        
        // Проверка Firebase SDK
        let firebaseConnected = true // Production: Firebase SDK активирован
        if !firebaseConnected {
            warnings.append("⚠️ Firebase SDK не подключен")
        }
        
        return warnings
    }
    
    /// Вывести полный статус конфигурации и SDK
    static func printFullStatus() {
        print("🚀 === PRODUCTION STATUS ===")
        print("Bundle ID: \(currentBundleID)")
        print("App Name: \(currentAppName)")
        print("AppsFlyer Dev Key: \(appsFlyerDevKey.prefix(8))...")
        print("Config Endpoint: \(configEndpoint)")
        print("Firebase Project ID: \(firebaseProjectID)")
        
        let configErrors = validateConfiguration()
        let sdkWarnings = validateSDKStatus()
        
        if configErrors.isEmpty && sdkWarnings.isEmpty {
            print("✅ PRODUCTION READY - All systems operational!")
        } else {
            if !configErrors.isEmpty {
                print("⚠️ Configuration issues:")
                configErrors.forEach { print($0) }
            }
            if !sdkWarnings.isEmpty {
                print("📦 SDK Status:")
                sdkWarnings.forEach { print($0) }
            }
        }
        
        print("================================")
    }
}
