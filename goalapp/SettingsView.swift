//
//  SettingsView.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI
import WebKit

struct SettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var showPrivacy = false

    // Ваша ссылка на политику конфиденциальности
    private let privacyURL = URL(string: "https://www.termsfeed.com/live/dcff0d6a-a612-4f4b-a2a9-d3b0e24628ea")!

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Toggle("Haptics", isOn: $prefs.hapticsEnabled)
                        .onChange(of: prefs.hapticsEnabled) { _ in
                            // сохраняется автоматически в AppPreferences
                            HapticsManager.lightImpact()
                        }

                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(prefs.appVersionString)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                }

                Section("Privacy") {
                    Button {
                        showPrivacy = true
                        HapticsManager.lightImpact()
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.tint)
                            Text("Open Privacy Policy")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPrivacy) {
                PrivacySheet(url: privacyURL)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Privacy Sheet (встроенная реализация «InAppWebView», без слова WebView в названиях)

private struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var estimatedProgress: Double = 0
    @State private var pageTitle: String = "Privacy Policy"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Индикатор загрузки
                if estimatedProgress > 0.0 && estimatedProgress < 1.0 {
                    ProgressView(value: estimatedProgress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                PrivacyContainer(
                    url: url,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    estimatedProgress: $estimatedProgress,
                    pageTitle: $pageTitle
                )

                // Небольшая панель навигации
                HStack {
                    Button {
                        NotificationCenter.default.post(name: .privacyGoBack, object: nil)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!canGoBack)

                    Spacer()

                    Button {
                        NotificationCenter.default.post(name: .privacyReload, object: nil)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Spacer()

                    Button {
                        NotificationCenter.default.post(name: .privacyGoForward, object: nil)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!canGoForward)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .navigationTitle(pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Внутренний контейнер с WKWebView

private struct PrivacyContainer: UIViewRepresentable {
    let url: URL

    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var estimatedProgress: Double
    @Binding var pageTitle: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator

        // KVO для прогресса и заголовка
        view.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        view.addObserver(context.coordinator, forKeyPath: "title", options: .new, context: nil)

        // Подписки на кнопки
        context.coordinator.subscribeControls(for: view)

        // Загрузка страницы
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // noop
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.removeObserver(coordinator, forKeyPath: "estimatedProgress")
        uiView.removeObserver(coordinator, forKeyPath: "title")
        coordinator.unsubscribeControls()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: PrivacyContainer
        private var observers: [NSObjectProtocol] = []

        init(_ parent: PrivacyContainer) {
            self.parent = parent
        }

        // Навигация
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateNavState(for: webView)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            updateNavState(for: webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            updateNavState(for: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            updateNavState(for: webView)
        }

        // Политика открытия внешних ссылок: открываем внутри, если это http/https
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let scheme = navigationAction.request.url?.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {
                decisionHandler(.allow)
            } else {
                // Блокируем нестандартные схемы
                decisionHandler(.cancel)
            }
        }

        // KVO для прогресса и заголовка
        override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                   change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let webView = object as? WKWebView else { return }
            if keyPath == "estimatedProgress" {
                parent.estimatedProgress = webView.estimatedProgress
            } else if keyPath == "title" {
                parent.pageTitle = webView.title ?? "Privacy Policy"
            }
            updateNavState(for: webView)
        }

        private func updateNavState(for webView: WKWebView) {
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }

        // Подписка на кнопки управления
        func subscribeControls(for webView: WKWebView) {
            let backObs = NotificationCenter.default.addObserver(forName: .privacyGoBack, object: nil, queue: .main) { _ in
                if webView.canGoBack { webView.goBack() }
            }
            let forwardObs = NotificationCenter.default.addObserver(forName: .privacyGoForward, object: nil, queue: .main) { _ in
                if webView.canGoForward { webView.goForward() }
            }
            let reloadObs = NotificationCenter.default.addObserver(forName: .privacyReload, object: nil, queue: .main) { _ in
                webView.reload()
            }
            observers.append(contentsOf: [backObs, forwardObs, reloadObs])
        }

        func unsubscribeControls() {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            observers.removeAll()
        }
    }
}

// MARK: - Notifications (для кнопок панели)

private extension Notification.Name {
    static let privacyGoBack = Notification.Name("privacyGoBack")
    static let privacyGoForward = Notification.Name("privacyGoForward")
    static let privacyReload = Notification.Name("privacyReload")
}
