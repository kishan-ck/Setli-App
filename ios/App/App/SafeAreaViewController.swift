//
//  SafeAreaViewController.swift
//  App
//
//  Created by MAC BOOK on 01/09/26.
//

import UIKit
import Capacitor
import WebKit

class SafeAreaViewController: CAPBridgeViewController {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let webView = webView else {
            return
        }

        let safeArea = view.safeAreaInsets

        webView.scrollView.contentInset = UIEdgeInsets(
            top: safeArea.top,
            left: safeArea.left,
            bottom: safeArea.bottom,
            right: safeArea.right
        )

        webView.scrollView.scrollIndicatorInsets = webView.scrollView.contentInset
    }
}
