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

    override func webView(with frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        let customWebView = AppWebView(frame: frame, configuration: configuration)
        customWebView.container = container
        return customWebView
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure any overlay splash view matches the full container bounds on rotation/layout
        for subview in view.subviews where subview !== bridgeViewController.view {
            subview.frame = view.bounds
        }
    }

    // Forward status bar style and visibility
    override var childForStatusBarStyle: UIViewController? {
        return bridgeViewController
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
