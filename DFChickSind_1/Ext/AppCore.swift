import Foundation
import SwiftUI
import UIKit
import Network
import UserNotifications
import WebKit
import AppTrackingTransparency
import AppsFlyerLib // Раскомментируйте после добавления AppsFlyer SDK
import FirebaseCore // Раскомментируйте после добавления Firebase SDK
import FirebaseMessaging // Раскомментируйте после добавления Firebase SDK

// MARK: - App Modes
enum AppMode: String, Codable {
    case webView = "webview"
    case game = "game"
    case undefined = "undefined"
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var appMode: AppMode = .undefined
    @Published var isFirstLaunch: Bool = true
    @Published var currentURL: String?
    @Published var urlExpires: TimeInterval?
    @Published var hasInternetConnection: Bool = true
    @Published var showNotificationPermissionScreen: Bool = false
    @Published var notificationPermissionDeniedDate: Date?
    @Published var isLoading: Bool = false
    @Published var pushToken: String?
    @Published var appsflyerID: String?
    @Published var conversionData: [String: Any]?
    @Published var isPushTokenReady: Bool = false
    @Published var isWaitingForPushToken: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    // Keys для UserDefaults
    private let appModeKey = "app_mode"
    private let isFirstLaunchKey = "is_first_launch"
    private let currentURLKey = "current_url"
    private let urlExpiresKey = "url_expires"
    private let notificationDeniedDateKey = "notification_denied_date"
    private let pushTokenKey = "push_token"
    private let appsflyerIDKey = "appsflyer_id"
    
    init() {
        loadState()
    }
    
    func loadState() {
        if let modeString = userDefaults.string(forKey: appModeKey),
           let mode = AppMode(rawValue: modeString) {
            self.appMode = mode
        }
        
        self.isFirstLaunch = userDefaults.bool(forKey: isFirstLaunchKey)
        self.currentURL = userDefaults.string(forKey: currentURLKey)
        self.urlExpires = userDefaults.object(forKey: urlExpiresKey) as? TimeInterval
        self.pushToken = userDefaults.string(forKey: pushTokenKey)
        self.appsflyerID = userDefaults.string(forKey: appsflyerIDKey)
        
        // Если у нас уже есть сохраненный push токен, помечаем его как готовый
        if self.pushToken != nil && !self.pushToken!.isEmpty {
            self.isPushTokenReady = true
        }
        
        if let deniedDate = userDefaults.object(forKey: notificationDeniedDateKey) as? Date {
            self.notificationPermissionDeniedDate = deniedDate
        }
        
        if userDefaults.object(forKey: isFirstLaunchKey) == nil {
            self.isFirstLaunch = true
            saveState()
        }
    }
    
    func saveState() {
        userDefaults.set(appMode.rawValue, forKey: appModeKey)
        userDefaults.set(isFirstLaunch, forKey: isFirstLaunchKey)
        userDefaults.set(currentURL, forKey: currentURLKey)
        userDefaults.set(urlExpires, forKey: urlExpiresKey)
        userDefaults.set(pushToken, forKey: pushTokenKey)
        userDefaults.set(appsflyerID, forKey: appsflyerIDKey)
        
        if let deniedDate = notificationPermissionDeniedDate {
            userDefaults.set(deniedDate, forKey: notificationDeniedDateKey)
        }
    }
    
    func setAppMode(_ mode: AppMode) {
        self.appMode = mode
        self.isFirstLaunch = false
        
        // Если переходим в режим game, очищаем последнюю открытую ссылку
        if mode == .game {
            UserDefaults.standard.removeObject(forKey: "last_opened_url")
            print("🗑 Cleared last opened URL - switching to game mode")
        }
        
        saveState()
    }
    
    func saveURL(_ url: String, expires: TimeInterval) {
        self.currentURL = url
        self.urlExpires = expires
        saveState()
    }
    
    func isURLExpired() -> Bool {
        guard let expires = urlExpires else { return true }
        return Date().timeIntervalSince1970 > expires
    }
    
    func savePushToken(_ token: String) {
        self.pushToken = token
        self.isPushTokenReady = true
        self.isWaitingForPushToken = false
        saveState()
        print("📱 Push token saved and marked as ready")
    }
    
    func saveAppsFlyerID(_ id: String) {
        self.appsflyerID = id
        saveState()
    }
    
    func saveConversionData(_ data: [String: Any]) {
        self.conversionData = data
    }
    
    func shouldShowNotificationPermission() -> Bool {
        guard appMode == .webView else { return false }
        
        // Проверяем системные разрешения
        let center = UNUserNotificationCenter.current()
        var systemPermissionStatus: UNAuthorizationStatus = .notDetermined
        
        let semaphore = DispatchSemaphore(value: 0)
        center.getNotificationSettings { settings in
            systemPermissionStatus = settings.authorizationStatus
            semaphore.signal()
        }
        semaphore.wait()
        
        // Если системное разрешение уже получено или окончательно отклонено - не показываем
        if systemPermissionStatus == .authorized || systemPermissionStatus == .denied {
            return false
        }
        
        // Если кастомный экран уже показывался и пользователь отказался
        if let deniedDate = notificationPermissionDeniedDate {
            let retryDate = Date().addingTimeInterval(-DataManager.notificationRetryInterval)
            if deniedDate > retryDate {
                return false // Еще не прошло 3 дня
            }
        }
        
        return true
    }
    
    func saveNotificationPermissionDenied() {
        self.notificationPermissionDeniedDate = Date()
        saveState()
        print("📅 Notification permission denied - next attempt in 3 days")
    }
    
    func startWaitingForPushToken() {
        self.isWaitingForPushToken = true
        print("⏳ Started waiting for push token...")
        
        // Таймаут на случай, если токен не придет
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.isWaitingForPushToken && !self.isPushTokenReady {
                print("⏰ Push token timeout - proceeding without token")
                self.isWaitingForPushToken = false
                self.isPushTokenReady = true // Помечаем как готовый, чтобы разблокировать процесс
            }
        }
    }
}

// MARK: - Config Models
struct ConfigRequest: Encodable {
    let conversionData: [String: Any]
    let af_id: String?
    let bundle_id: String
    let os: String
    let store_id: String
    let locale: String
    let push_token: String?
    let firebase_project_id: String?
    
    init(conversionData: [String: Any], af_id: String?, bundle_id: String, store_id: String, locale: String, push_token: String?, firebase_project_id: String?) {
        self.conversionData = conversionData
        self.af_id = af_id
        self.bundle_id = bundle_id
        self.os = "iOS"
        self.store_id = store_id
        self.locale = locale
        self.push_token = push_token
        self.firebase_project_id = firebase_project_id
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        
        for (key, value) in conversionData {
            let codingKey = DynamicCodingKeys(stringValue: key)!
            try container.encodeAny(value, forKey: codingKey)
        }
        
        if let af_id = af_id {
            try container.encode(af_id, forKey: DynamicCodingKeys(stringValue: "af_id")!)
        }
        try container.encode(bundle_id, forKey: DynamicCodingKeys(stringValue: "bundle_id")!)
        try container.encode(os, forKey: DynamicCodingKeys(stringValue: "os")!)
        try container.encode(store_id, forKey: DynamicCodingKeys(stringValue: "store_id")!)
        try container.encode(locale, forKey: DynamicCodingKeys(stringValue: "locale")!)
        
        if let push_token = push_token {
            try container.encode(push_token, forKey: DynamicCodingKeys(stringValue: "push_token")!)
        }
        
        if let firebase_project_id = firebase_project_id {
            try container.encode(firebase_project_id, forKey: DynamicCodingKeys(stringValue: "firebase_project_id")!)
        }
    }
}

struct ConfigResponse: Codable {
    let ok: Bool
    let url: String?
    let expires: TimeInterval?
    let message: String?
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

extension KeyedEncodingContainer where Key == DynamicCodingKeys {
    mutating func encodeAny(_ value: Any, forKey key: DynamicCodingKeys) throws {
        switch value {
        case let string as String:
            try encode(string, forKey: key)
        case let int as Int:
            try encode(int, forKey: key)
        case let double as Double:
            try encode(double, forKey: key)
        case let bool as Bool:
            try encode(bool, forKey: key)
        case is NSNull:
            try encodeNil(forKey: key)
        default:
            try encode(String(describing: value), forKey: key)
        }
    }
}

struct DeviceInfo {
    let bundleId: String
    let storeId: String
    let locale: String
    let osVersion: String
    let deviceModel: String
    
    static func current() -> DeviceInfo {
        let bundleId = Bundle.main.bundleIdentifier ?? "BundleID"
        
        // Согласно документации, для iOS Store ID должен быть с префиксом "id"
        let storeId = DataManager.appleAppID.isEmpty ? bundleId : DataManager.appleAppID
        
        let locale = Locale.current.languageCode ?? "en"
        let osVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        
        // Логирование убрано для уменьшения дублирования в консоли
        
        return DeviceInfo(
            bundleId: bundleId,
            storeId: storeId,
            locale: locale,
            osVersion: osVersion,
            deviceModel: deviceModel
        )
    }
}

// MARK: - Config Service
class ConfigService: ObservableObject {
    static let shared = ConfigService()
    
    private let configEndpoint = DataManager.configEndpoint
    
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    
    private init() {
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    func fetchConfig(conversionData: [String: Any], appsflyerID: String?, pushToken: String?, completion: @escaping (Result<ConfigResponse, ConfigError>) -> Void) {
        guard isConnected else {
            completion(.failure(.noInternetConnection))
            return
        }
        
        let deviceInfo = DeviceInfo.current()
        let configRequest = ConfigRequest(
            conversionData: conversionData,
            af_id: appsflyerID,
            bundle_id: deviceInfo.bundleId,
            store_id: deviceInfo.storeId,
            locale: deviceInfo.locale,
            push_token: pushToken,
            firebase_project_id: DataManager.firebaseProjectID.isEmpty ? nil : DataManager.firebaseProjectID
        )
        
        sendConfigRequest(configRequest, completion: completion)
    }
    
    private func sendConfigRequest(_ request: ConfigRequest, completion: @escaping (Result<ConfigResponse, ConfigError>) -> Void) {
        guard let url = URL(string: configEndpoint) else {
            print("❌ Invalid URL: \(configEndpoint)")
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(DataManager.createCustomUserAgent(), forHTTPHeaderField: "User-Agent")
        
        // ДЕТАЛЬНОЕ ЛОГИРОВАНИЕ ЗАПРОСА
        print("🌐 ===== CONFIG SERVER REQUEST DEBUG =====")
        print("📍 Endpoint URL: \(configEndpoint)")
        print("📍 Full URL: \(url.absoluteString)")
        print("🔧 HTTP Method: \(urlRequest.httpMethod ?? "N/A")")
        print("⏰ Request Time: \(Date())")
        print("📱 Device Info:")
        let deviceInfo = DeviceInfo.current()
        print("   Bundle ID: \(deviceInfo.bundleId)")
        print("   Store ID: \(deviceInfo.storeId)")
        print("   Locale: \(deviceInfo.locale)")
        print("   OS Version: \(deviceInfo.osVersion)")
        print("   Device Model: \(deviceInfo.deviceModel)")
        print("📋 Request Headers:")
        if let headers = urlRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                print("   \(key): \(value)")
            }
        }
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📦 Request Body JSON:")
                print("\(jsonString)")
                print("📏 Request Body Size: \(jsonData.count) bytes")
            }
        } catch {
            print("❌ JSON Encoding Error: \(error)")
            completion(.failure(.encodingError(error)))
            return
        }
        print("==========================================")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                // ДЕТАЛЬНОЕ ЛОГИРОВАНИЕ ОТВЕТА
                print("📥 ===== CONFIG SERVER RESPONSE DEBUG =====")
                print("⏰ Response Time: \(Date())")
                
                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    print("❌ Error Code: \((error as NSError).code)")
                    print("❌ Error Domain: \((error as NSError).domain)")
                    print("===========================================")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid HTTP Response")
                    print("===========================================")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                print("📄 Response Headers:")
                for (key, value) in httpResponse.allHeaderFields {
                    print("   \(key): \(value)")
                }
                
                guard let data = data else {
                    print("❌ No Data in Response")
                    print("===========================================")
                    completion(.failure(.noData))
                    return
                }
                
                print("📏 Response Size: \(data.count) bytes")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📝 Response Body:")
                    print("\(responseString)")
                } else {
                    print("❌ Unable to decode response as UTF-8 string")
                }
                
                do {
                    let configResponse = try JSONDecoder().decode(ConfigResponse.self, from: data)
                    print("✅ JSON Decoded Successfully:")
                    print("   ok: \(configResponse.ok)")
                    print("   url: \(configResponse.url ?? "nil")")
                    print("   expires: \(configResponse.expires ?? 0)")
                    print("   message: \(configResponse.message ?? "nil")")
                    
                    if httpResponse.statusCode == 200 && configResponse.ok {
                        print("✅ Config Request Successful!")
                        print("===========================================")
                        completion(.success(configResponse))
                    } else {
                        print("❌ Server Error - Status: \(httpResponse.statusCode), Message: \(configResponse.message ?? "No message")")
                        print("===========================================")
                        completion(.failure(.serverError(httpResponse.statusCode, configResponse.message)))
                    }
                } catch {
                    print("❌ JSON Decoding Error: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("   Missing key: \(key.stringValue)")
                            print("   Context: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("   Type mismatch: expected \(type)")
                            print("   Context: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("   Value not found: \(type)")
                            print("   Context: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("   Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("   Unknown decoding error")
                        }
                    }
                    print("===========================================")
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    func shouldRecheckConversion(conversionData: [String: Any]) -> Bool {
        if let afStatus = conversionData["af_status"] as? String {
            return afStatus == "Organic"
        }
        return false
    }
    
    func recheckConversionData(appsflyerID: String, completion: @escaping (Result<[String: Any], ConfigError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + DataManager.conversionRecheckDelay) {
            completion(.failure(.appsflyerAPINotImplemented))
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

enum ConfigError: Error, LocalizedError {
    case noInternetConnection
    case invalidURL
    case encodingError(Error)
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(Int, String?)
    case appsflyerAPINotImplemented
    
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "Нет интернет-соединения"
        case .invalidURL:
            return "Некорректный URL"
        case .encodingError(let error):
            return "Ошибка кодирования: \(error.localizedDescription)"
        case .networkError(let error):
            return "Сетевая ошибка: \(error.localizedDescription)"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .noData:
            return "Нет данных в ответе"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Ошибка сервера (\(code)): \(message ?? "Неизвестная ошибка")"
        case .appsflyerAPINotImplemented:
            return "AppsFlyer API не реализован"
        }
    }
}

// MARK: - AppsFlyer Service
class AppsFlyerService: NSObject, ObservableObject {
    static let shared = AppsFlyerService()
    
    private let appsFlyerDevKey = DataManager.appsFlyerDevKey
    private let appleAppID = DataManager.appleAppID
    
    @Published var conversionData: [String: Any]?
    @Published var appsflyerUID: String?
    @Published var isInitialized = false
    
    private var conversionDataCallback: (([String: Any]) -> Void)?
    
    private override init() {}
    
    func initializeAppsFlyer() {
        print("🚀 ===== APPSFLYER INITIALIZATION DEBUG =====")
        print("📱 AppsFlyer Dev Key: \(DataManager.appsFlyerDevKey.prefix(8))...")
        print("📱 Apple App ID: \(DataManager.appleAppID)")
        print("⏰ Initialization Time: \(Date())")
        print("🔧 Debug Mode: false (Production)")
        
        AppsFlyerLib.shared().appsFlyerDevKey = DataManager.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = DataManager.appleAppID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().isDebug = false // Production mode
        
        // Запуск AppsFlyer
        AppsFlyerLib.shared().start { (dictionary, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ AppsFlyer initialization error: \(error)")
                    print("❌ Error domain: \((error as NSError).domain)")
                    print("❌ Error code: \((error as NSError).code)")
                    print("=============================================")
                } else {
                    print("✅ AppsFlyer initialized successfully")
                    self.isInitialized = true
                    self.appsflyerUID = AppsFlyerLib.shared().getAppsFlyerUID()
                    print("🆔 AppsFlyer UID: \(self.appsflyerUID ?? "N/A")")
                    if let dictionary = dictionary {
                        print("📊 Initialization Data: \(dictionary)")
                    }
                    print("=============================================")
                }
            }
        }
    }
    

    
    func getAppsFlyerUID() -> String? {
        return appsflyerUID
    }
    
    func setConversionDataCallback(_ callback: @escaping ([String: Any]) -> Void) {
        self.conversionDataCallback = callback
        
        if let data = conversionData {
            callback(data)
        }
    }
    
    func logEvent(eventName: String, eventValues: [String: Any]?) {
        AppsFlyerLib.shared().logEvent(eventName, withValues: eventValues)
        print("AppsFlyer Event logged: \(eventName)")
    }
    
    func requestTrackingPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        print("✅ Tracking permission granted")
                        completion(true)
                    case .denied, .restricted, .notDetermined:
                        print("❌ Tracking permission denied or restricted")
                        completion(false)
                    @unknown default:
                        print("⚠️ Unknown tracking permission status")
                        completion(false)
                    }
                }
            }
        } else {
            // iOS < 14.5 - разрешение не требуется
            completion(true)
        }
    }
}

// MARK: - AppsFlyer Delegate
extension AppsFlyerService: AppsFlyerLibDelegate {
    
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("📊 ===== APPSFLYER CONVERSION SUCCESS =====")
        print("⏰ Conversion Time: \(Date())")
        print("📦 Raw Conversion Info: \(conversionInfo)")
        
        if let conversionData = conversionInfo as? [String: Any] {
            print("✅ Conversion Data Parsed Successfully:")
            for (key, value) in conversionData {
                print("   \(key): \(value)")
            }
            
            // Анализ ключевых параметров
            if let afStatus = conversionData["af_status"] as? String {
                print("🎯 Attribution Status: \(afStatus)")
            }
            if let mediaSource = conversionData["media_source"] as? String {
                print("📺 Media Source: \(mediaSource)")
            }
            if let campaign = conversionData["campaign"] as? String {
                print("📢 Campaign: \(campaign)")
            }
            if let isFirstLaunch = conversionData["is_first_launch"] as? Bool {
                print("🚀 First Launch: \(isFirstLaunch)")
            }
            
            DispatchQueue.main.async {
                self.conversionData = conversionData
                self.conversionDataCallback?(conversionData)
                print("✅ Conversion data callback executed")
            }
        } else {
            print("❌ Failed to parse conversion data as [String: Any]")
        }
        print("==========================================")
    }
    
    func onConversionDataFail(_ error: Error) {
        print("❌ ===== APPSFLYER CONVERSION FAILED =====")
        print("⏰ Error Time: \(Date())")
        print("❌ Error: \(error.localizedDescription)")
        print("❌ Error Domain: \((error as NSError).domain)")
        print("❌ Error Code: \((error as NSError).code)")
        
        // При ошибке AppsFlyer используем минимальные органические данные
        let fallbackData: [String: Any] = [
            "af_status": "Organic", // Органическая установка при ошибке AppsFlyer
            "is_first_launch": true,
            "error_fallback": true
        ]
        
        print("🔄 Using fallback organic data: \(fallbackData)")
        print("⚠️ AppsFlyer fallback triggered - will show Game mode")
        
        DispatchQueue.main.async {
            self.conversionData = fallbackData
            self.conversionDataCallback?(fallbackData)
            print("✅ Fallback data callback executed")
        }
        print("==========================================")
    }
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        print("🔗 ===== APPSFLYER DEEP LINK SUCCESS =====")
        print("⏰ Attribution Time: \(Date())")
        print("📱 App Open Attribution Data: \(attributionData)")
        
        // Детальный анализ deep link данных
        if let link = attributionData["link"] as? String {
            print("🔗 Deep Link URL: \(link)")
        }
        if let scheme = attributionData["scheme"] as? String {
            print("📱 URL Scheme: \(scheme)")
        }
        if let host = attributionData["host"] as? String {
            print("🏠 Host: \(host)")
        }
        
        print("==========================================")
        // Обработка deep linking
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        print("❌ ===== APPSFLYER DEEP LINK FAILED =====")
        print("⏰ Error Time: \(Date())")
        print("❌ Deep Link Error: \(error.localizedDescription)")
        print("❌ Error Domain: \((error as NSError).domain)")
        print("❌ Error Code: \((error as NSError).code)")
        print("==========================================")
    }
}

// MARK: - Push Notification Service
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var pushToken: String?
    weak var appState: AppState?
    @Published var pendingNotificationURL: String?
    
    private override init() {
        super.init()
        setupNotificationCenter()
    }
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        print("📱 ===== PUSH NOTIFICATION TOKEN DEBUG =====")
        print("⏰ Token Registration Time: \(Date())")
        
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let apnsToken = tokenParts.joined()
        
        print("📱 APNS Token Received: \(apnsToken)")
        print("📏 APNS Token Length: \(apnsToken.count) characters")
        print("📦 Raw Token Data Length: \(deviceToken.count) bytes")
        
        // Передаем APNS токен в Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        print("🔄 APNS token passed to Firebase Messaging")
        
        // Получаем FCM токен
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM token: \(error)")
                print("❌ FCM Error Domain: \((error as NSError).domain)")
                print("❌ FCM Error Code: \((error as NSError).code)")
                print("==========================================")
                return
            } else if let token = token {
                print("✅ FCM Token Received: \(token)")
                print("📏 FCM Token Length: \(token.count) characters")
                DispatchQueue.main.async {
                    self.pushToken = token
                    self.appState?.savePushToken(token)
                    print("💾 FCM token saved to AppState")
                    self.updatePushTokenInConfig(token)
                    print("🔄 Updating FCM token in config...")
                }
                print("==========================================")
            }
        }
    }
    
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    private func updatePushTokenInConfig(_ token: String) {
        guard let appState = self.appState else {
            print("⚠️ AppState not available for push token update")
            return
        }
        
        guard let conversionData = appState.conversionData else { return }
        
        ConfigService.shared.fetchConfig(
            conversionData: conversionData,
            appsflyerID: appState.appsflyerID,
            pushToken: token
        ) { result in
            switch result {
            case .success:
                print("Push token successfully updated in config")
            case .failure(let error):
                print("Failed to update push token in config: \(error)")
            }
        }
    }
    
    func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        print("📲 ===== PUSH NOTIFICATION RECEIVED =====")
        print("⏰ Notification Time: \(Date())")
        print("📦 Full Notification Payload: \(userInfo)")
        
        // Анализ содержимого уведомления
        if let aps = userInfo["aps"] as? [String: Any] {
            print("📱 APS Data:")
            for (key, value) in aps {
                print("   \(key): \(value)")
            }
        }
        
        // Поиск URL в уведомлении
        var foundURL: String?
        if let urlString = userInfo["url"] as? String, !urlString.isEmpty {
            foundURL = urlString
            print("🔗 URL found in root: \(urlString)")
        } else if let aps = userInfo["aps"] as? [String: Any],
                  let urlString = aps["url"] as? String, !urlString.isEmpty {
            foundURL = urlString
            print("🔗 URL found in APS: \(urlString)")
        } else {
            print("❌ No URL found in notification payload")
            // Поиск других возможных ключей с URL
            for (key, value) in userInfo {
                if let stringValue = value as? String, stringValue.hasPrefix("http") {
                    print("🔍 Possible URL found in key '\(key)': \(stringValue)")
                }
            }
        }
        
        if let urlString = foundURL {
            print("✅ Processing notification URL: \(urlString)")
            DispatchQueue.main.async {
                self.pendingNotificationURL = urlString
                self.openNotificationURL(urlString)
                print("📱 Notification URL opened")
            }
        } else {
            print("⚠️ No valid URL to process in notification")
        }
        print("==========================================")
    }
    
    private func openNotificationURL(_ url: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenNotificationURL"),
            object: nil,
            userInfo: ["url": url]
        )
    }
    
    func clearPendingNotificationURL() {
        pendingNotificationURL = nil
    }
    
    func updateFCMToken(_ token: String) {
        DispatchQueue.main.async {
            self.pushToken = token
            self.appState?.savePushToken(token)
            self.updatePushTokenInConfig(token)
        }
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        handlePushNotification(userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handlePushNotification(userInfo)
        completionHandler()
    }
}
