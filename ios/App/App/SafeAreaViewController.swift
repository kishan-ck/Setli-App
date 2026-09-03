//
//  SafeAreaViewController.swift
//  App
//
//  Created by MAC BOOK on 01/09/26.
//

import UIKit
import Capacitor
import WebKit

class SafeAreaViewController: UIViewController {

    public let bridgeViewController = CAPBridgeViewController()

    public var webView: WKWebView? {
        return bridgeViewController.webView
    }

    public var bridge: CAPBridgeProtocol? {
        return bridgeViewController.bridge
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
            bridgeViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bridgeViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bridgeViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        bridgeViewController.didMove(toParent: self)
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
