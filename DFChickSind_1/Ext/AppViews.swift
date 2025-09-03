//
//  AppViews.swift
//  DFChickSind_1
//
//  Created by IGOR on 01/09/2025.
//

import SwiftUI
import WebKit
import UserNotifications

// MARK: - WebView Component
struct WebView: UIViewRepresentable {
    let url: String
    @Binding var isLoading: Bool
    
    var onNavigationAction: ((URL) -> Bool)?
    var onLoadFinished: (() -> Void)?
    var onLoadError: ((Error) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsPictureInPictureMediaPlayback = true
        
        let preferences = WKPreferences()
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            preferences.javaScriptEnabled = true
        }
        configuration.preferences = preferences
        
        configuration.allowsAirPlayForMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        webView.customUserAgent = DataManager.createCustomUserAgent()
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        
        // Поддержка загрузки файлов
        if #available(iOS 15.0, *) {
            webView.configuration.preferences.isElementFullscreenEnabled = true
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let targetURL = URL(string: url) else { return }
        
        // Загружаем только если URL действительно изменился и WebView не загружается
        if webView.url?.absoluteString != targetURL.absoluteString && !webView.isLoading {
            let request = URLRequest(url: targetURL)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createCustomUserAgent() -> String {
        let systemVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        
        return "Mozilla/5.0 (\(deviceModel); CPU OS \(systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(systemVersion) Mobile/15E148 Safari/604.1"
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Состояние загрузки больше не управляется - экран загрузки убран
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.onLoadFinished?()
                
                // Сохраняем последнюю успешно загруженную ссылку
                if let currentURL = webView.url?.absoluteString, !currentURL.isEmpty {
                    UserDefaults.standard.set(currentURL, forKey: "last_opened_url")
                    print("💾 Saved last opened URL: \(currentURL)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.onLoadError?(error)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                let nsError = error as NSError
                // Игнорируем отмену запросов (-999) и слишком много редиректов
                if nsError.code == NSURLErrorCancelled || nsError.code == NSURLErrorHTTPTooManyRedirects {
                    return
                }
                
                self.parent.onLoadError?(error)
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            if !url.absoluteString.hasPrefix("http") && !url.absoluteString.hasPrefix("https") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url) { _ in
                        DispatchQueue.main.async {
                            if webView.canGoBack {
                                webView.goBack()
                            }
                        }
                    }
                }
                decisionHandler(.cancel)
                return
            }
            
            if let shouldAllow = parent.onNavigationAction?(url), !shouldAllow {
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler()
            })
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            } else {
                completionHandler()
            }
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            } else {
                completionHandler(false)
            }
        }
        
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
    }
}

// MARK: - WebView Screen
struct WebViewScreen: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var configService = ConfigService.shared
    @State private var isLoading = false // Для тестирования начинаем с false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasAppeared = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let url = appState.currentURL, !url.isEmpty {
                    WebView(
                        url: url,
                    isLoading: $isLoading,
                    onNavigationAction: { url in
                        return true
                    },
                                            onLoadFinished: {
                            // WebView загружен
                        },
                    onLoadError: { error in
                        handleWebViewError(error)
                    }
                    )
                    .ignoresSafeArea(.keyboard) // Игнорируем только клавиатуру, но уважаем Safe Area
                    .id(url) // ID по URL
                } else {
                    LoadingOrErrorView(
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        onRetry: {
                            loadWebViewURL()
                        }
                    )
                }
                
                // Серый экран загрузки убран - мешает работе WebView
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                // Загружаем URL если его нет или он истек
                if appState.currentURL?.isEmpty != false || appState.isURLExpired() {
                    loadWebViewURL()
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                primaryButton: .default(Text("Повторить")) {
                    loadWebViewURL()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func loadWebViewURL() {
        guard !isLoading else { return }
        
        // Если есть валидный URL, не делаем ничего
        if let savedURL = appState.currentURL, !savedURL.isEmpty, !appState.isURLExpired() {
            return
        }
        
        isLoading = true
        showError = false
        
        guard let conversionData = appState.conversionData else {
            handleConfigError(.noData)
            return
        }
        
        configService.fetchConfig(
            conversionData: conversionData,
            appsflyerID: appState.appsflyerID,
            pushToken: appState.pushToken
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if let url = response.url, let expires = response.expires {
                        self.appState.saveURL(url, expires: expires)
                    } else {
                        self.handleConfigError(.invalidResponse)
                    }
                    
                case .failure(let error):
                    self.handleConfigError(error)
                }
            }
        }
    }
    
    private func handleConfigError(_ error: ConfigError) {
        switch error {
        case .noInternetConnection:
            if let savedURL = appState.currentURL, !savedURL.isEmpty {
                return
            } else if let lastURL = UserDefaults.standard.string(forKey: "last_opened_url"), !lastURL.isEmpty {
                print("🔄 Using last opened URL due to no internet: \(lastURL)")
                appState.currentURL = lastURL
                return
            } else {
                errorMessage = "No ethernet connection"
                showError = true
            }
            
        case .serverError(let code, _):
            if code == 404 || code >= 400 {
                appState.setAppMode(.game)
                return
            }
            fallthrough
            
        default:
            if let savedURL = appState.currentURL, !savedURL.isEmpty {
                return
            } else if let lastURL = UserDefaults.standard.string(forKey: "last_opened_url"), !lastURL.isEmpty {
                print("🔄 Using last opened URL due to server error: \(lastURL)")
                appState.currentURL = lastURL
                return
            }
            
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleWebViewError(_ error: Error) {
        let nsError = error as NSError
        
        if nsError.code == NSURLErrorCancelled {
            return
        }
        
        errorMessage = "Error while loading: \(error.localizedDescription)"
        showError = true
    }
}

// MARK: - Loading/Error View
struct LoadingOrErrorView: View {
    let isLoading: Bool
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                                            Text("Loading")
                            .font(.headline)
                            .foregroundColor(.primary)
                }
            } else if !errorMessage.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("No ethernet connection")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Check your connection and try again")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        onRetry()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct GameButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Notification Permission View
struct NotificationPermissionView: View {
    @EnvironmentObject var appState: AppState
    @State private var isAnimating = false
    
    var onPermissionGranted: () -> Void
    var onPermissionSkipped: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Иконка
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.yellow, .orange]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                            .offset(x: 35, y: -35)
                    }
                    .padding(.bottom, 40)
                    
                    // Заголовок и описание
                    VStack(spacing: 20) {
                        Text("Get Notifications")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 12) {
                            Text("Stay up to date with all events")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("Be among the first to receive gifts and bonuses")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 50)
                    
                    Spacer()
                    
                    // Кнопки
                    VStack(spacing: 16) {
                        Button(action: {
                            requestNotificationPermission()
                        }) {
                            HStack {
                                Image(systemName: "gift.fill")
                                    .font(.title3)
                                
                                Text("Enable Notifications")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        Button(action: {
                            skipNotificationPermission()
                        }) {
                            Text("Skip")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(22)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.onPermissionGranted()
                } else {
                    self.appState.saveNotificationPermissionDenied()
                    self.onPermissionSkipped()
                }
            }
        }
    }
    
    private func skipNotificationPermission() {
        appState.saveNotificationPermissionDenied()
        onPermissionSkipped()
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.05, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Логотип
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple, .pink]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(rotationAngle))
                    }
                    
                    // Индикатор загрузки
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .cyan, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(rotationAngle))
                    }
                    
                    // Текст
                    VStack(spacing: 8) {
                        Text(DataManager.currentAppName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Loading")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
            
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(buttonTitle) {
                action()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
