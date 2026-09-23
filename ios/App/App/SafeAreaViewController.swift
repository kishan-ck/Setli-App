//
//  SafeAreaViewController.swift
//  App
//
//  Created by MAC BOOK on 01/09/26.
//

import UIKit
import Capacitor
import WebKit

class AppBridgeViewController: CAPBridgeViewController {
    weak var container: SafeAreaViewController?
    private var navigationProxy: DownloadNavigationDelegateProxy?

    override func webView(with frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        configuration.userContentController.addUserScript(DownloadManager.injectedUserScript)
        configuration.userContentController.add(DownloadManager.shared, name: "downloadHandler")
        let customWebView = AppWebView(frame: frame, configuration: configuration)
        customWebView.container = container
        return customWebView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let webView = self.webView, let original = webView.navigationDelegate {
            let proxy = DownloadNavigationDelegateProxy(originalDelegate: original)
            self.navigationProxy = proxy
            webView.navigationDelegate = proxy
        }
    }
}

class DownloadNavigationDelegateProxy: NSObject, WKNavigationDelegate {
    weak var originalDelegate: WKNavigationDelegate?

    init(originalDelegate: WKNavigationDelegate?) {
        self.originalDelegate = originalDelegate
        super.init()
    }

    // MARK: - WKNavigationDelegate Action Policy

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        let url = request.url
        let urlString = url?.absoluteString ?? ""

        // 1. Intercept data: URIs (Base64 PDF, CSV, Excel, Images, Zip, etc.)
        if urlString.hasPrefix("data:") {
            DownloadManager.shared.handleDownload(urlString: urlString)
            decisionHandler(.cancel)
            return
        }

        // 2. Intercept actions explicitly flagged for download
        if #available(iOS 14.5, *), navigationAction.shouldPerformDownload {
            decisionHandler(.download)
            return
        }

        // 3. Intercept direct downloadable links (e.g. .pdf, .csv, .xlsx, .zip)
        if let url = url, DownloadManager.shared.isDownloadableUrl(url) {
            if #available(iOS 14.5, *) {
                decisionHandler(.download)
                return
            }
        }

        // 4. Otherwise forward to original Capacitor delegation handler
        if let original = originalDelegate {
            let called: Void? = original.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
            if called == nil {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    // MARK: - WKNavigationDelegate Response Policy (Detect Export & File Downloads)

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            let headers = httpResponse.allHeaderFields
            let contentDisposition = (headers["Content-Disposition"] as? String ??
                                      headers["content-disposition"] as? String ?? "").lowercased()
            let mimeType = (httpResponse.mimeType ?? "").lowercased()
            let pathExt = (httpResponse.url?.pathExtension ?? "").lowercased()

            let isAttachment = contentDisposition.contains("attachment") ||
                (contentDisposition.contains("filename=") && !contentDisposition.contains("inline"))

            let isDownloadableExt = ["pdf", "csv", "xlsx", "xls", "zip", "doc", "docx"].contains(pathExt)

            let isDownloadableMime = [
                "text/csv",
                "application/csv",
                "application/zip",
                "application/x-zip-compressed",
                "application/vnd.ms-excel",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "application/octet-stream"
            ].contains(mimeType) || (mimeType == "application/pdf" && (isAttachment || isDownloadableExt))

            if isAttachment || isDownloadableMime || (isDownloadableExt && mimeType != "text/html") {
                if #available(iOS 14.5, *) {
                    decisionHandler(.download)
                    return
                } else {
                    decisionHandler(.cancel)
                    if let urlString = httpResponse.url?.absoluteString {
                        DownloadManager.shared.handleHttpDownload(urlString: urlString, customFilename: nil, customMimeType: mimeType)
                    }
                    return
                }
            }
        }

        if let original = originalDelegate {
            let called: Void? = original.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
            if called == nil {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    // MARK: - WKDownload Delegation Routing

    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = DownloadManager.shared
    }

    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = DownloadManager.shared
    }

    // MARK: - Forward Lifecycle Callbacks to Original Delegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        originalDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        originalDelegate?.webView?(webView, didFinish: navigation)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        originalDelegate?.webView?(webView, didFail: navigation, withError: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        originalDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        originalDelegate?.webViewWebContentProcessDidTerminate?(webView)
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let original = originalDelegate {
            let called: Void? = original.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
            if called == nil {
                completionHandler(.performDefaultHandling, nil)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // MARK: - Dynamic Objective-C Forwarding

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        return originalDelegate?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let original = originalDelegate, original.responds(to: aSelector) {
            return original
        }
        return super.forwardingTarget(for: aSelector)
    }
}

class AppWebView: WKWebView {
    weak var container: SafeAreaViewController?

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        // If an overlay view (e.g. Capacitor's SplashScreen) is added to the webview,
        // reparent it to the root container view controller so it covers the entire screen
        // and its icon is centered exactly without being offset by safe area insets.
        if subview !== self.scrollView && !(subview is UIScrollView) && !(subview is UIActivityIndicatorView),
           let container = container {
            container.view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = true
            subview.frame = container.view.bounds
            container.view.bringSubviewToFront(subview)
        }
    }
}

class SafeAreaViewController: UIViewController {

    public let bridgeViewController: CAPBridgeViewController
    private var onboardingViewController: OnboardingViewController?

    public var webView: WKWebView? {
        return bridgeViewController.webView
    }

    public var bridge: CAPBridgeProtocol? {
        return bridgeViewController.bridge
    }

    init() {
        let bridgeVC = AppBridgeViewController()
        self.bridgeViewController = bridgeVC
        super.init(nibName: nil, bundle: nil)
        bridgeVC.container = self
    }

    required init?(coder: NSCoder) {
        let bridgeVC = AppBridgeViewController()
        self.bridgeViewController = bridgeVC
        super.init(coder: coder)
        bridgeVC.container = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        DownloadManager.shared.configure(presentingViewController: self)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCapacitorNavigationAction(_:)),
            name: .capacitorDecidePolicyForNavigationAction,
            object: nil
        )

        // Background color behind the status bar and home indicator areas
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        // Embed Capacitor Bridge as a child view controller
        addChild(bridgeViewController)
        view.addSubview(bridgeViewController.view)
        bridgeViewController.view.translatesAutoresizingMaskIntoConstraints = false

        // Constrain the WKWebView to the safe area layout guide so it stays below the status bar / Dynamic Island
        NSLayoutConstraint.activate([
            bridgeViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bridgeViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bridgeViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bridgeViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        bridgeViewController.didMove(toParent: self)

        // Setup onboarding if not yet completed
        setupOnboardingIfNeeded()
    }

    @objc private func handleCapacitorNavigationAction(_ notification: Notification) {
        guard let navigationAction = notification.object as? WKNavigationAction,
              let url = navigationAction.request.url else { return }

        let urlString = url.absoluteString
        if urlString.hasPrefix("data:") {
            DownloadManager.shared.handleDownload(urlString: urlString)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupOnboardingIfNeeded() {
        let hasCompleted = UserDefaults.standard.bool(forKey: OnboardingViewController.onboardingCompletedKey)
        guard !hasCompleted else { return }

        let onboardingVC = OnboardingViewController()
        self.onboardingViewController = onboardingVC

        onboardingVC.onCompletion = { [weak self, weak onboardingVC] in
            guard let self = self, let onboardingVC = onboardingVC else { return }
            UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut], animations: {
                onboardingVC.view.alpha = 0
            }) { _ in
                onboardingVC.willMove(toParent: nil)
                onboardingVC.view.removeFromSuperview()
                onboardingVC.removeFromParent()
                self.onboardingViewController = nil
            }
        }

        addChild(onboardingVC)
        view.addSubview(onboardingVC.view)
        onboardingVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            onboardingVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            onboardingVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            onboardingVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            onboardingVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        onboardingVC.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure only unconstrained overlay splash views match full container bounds
        for subview in view.subviews where subview !== bridgeViewController.view && subview !== onboardingViewController?.view && subview.translatesAutoresizingMaskIntoConstraints {
            subview.frame = view.bounds
        }
    }

    // Forward status bar style and visibility
    override var childForStatusBarStyle: UIViewController? {
        return onboardingViewController ?? bridgeViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return bridgeViewController
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
        }
        return .default
    }

    override var prefersStatusBarHidden: Bool {
        return bridgeViewController.prefersStatusBarHidden
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return bridgeViewController.preferredStatusBarUpdateAnimation
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return bridgeViewController.supportedInterfaceOrientations
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsStatusBarAppearanceUpdate()
    }
}
