//
//  Snackbar.swift
//  App
//
//  Created on 09/09/26.
//

import UIKit

public class Snackbar {

    private static var currentSnackbar: UIView?
    private static var dismissWorkItem: DispatchWorkItem?

    /// Shows a simple bottom snackbar with the given message
    public static func show(message: String, duration: TimeInterval = 2.5, in parentView: UIView? = nil) {
        DispatchQueue.main.async {
            // Find the best window / container view
            let targetView: UIView?
            if let parent = parentView {
                targetView = parent.window ?? parent
            } else if #available(iOS 13.0, *) {
                targetView = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow } ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            } else {
                targetView = UIApplication.shared.keyWindow
            }

            guard let containerView = targetView else { return }

            // Cancel any pending dismissal and remove existing snackbar
            dismissWorkItem?.cancel()
            dismissWorkItem = nil
            currentSnackbar?.removeFromSuperview()
            currentSnackbar = nil

            let snackbar = UIView()
            snackbar.backgroundColor = UIColor(red: 0x1E/255.0, green: 0x29/255.0, blue: 0x3B/255.0, alpha: 0.98) // Slate 800
            snackbar.layer.cornerRadius = 10
            snackbar.layer.shadowColor = UIColor.black.cgColor
            snackbar.layer.shadowOpacity = 0.25
            snackbar.layer.shadowOffset = CGSize(width: 0, height: 3)
            snackbar.layer.shadowRadius = 8
            snackbar.layer.zPosition = 9999
            snackbar.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = message
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            label.numberOfLines = 2
            label.textAlignment = .left

            snackbar.addSubview(label)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: snackbar.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: snackbar.trailingAnchor, constant: -16),
                label.topAnchor.constraint(equalTo: snackbar.topAnchor, constant: 14),
                label.bottomAnchor.constraint(equalTo: snackbar.bottomAnchor, constant: -14)
            ])

            containerView.addSubview(snackbar)
            containerView.bringSubviewToFront(snackbar)
            currentSnackbar = snackbar

            NSLayoutConstraint.activate([
                snackbar.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                snackbar.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                snackbar.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16)
            ])

            // Initial offscreen transform below the screen
            snackbar.transform = CGAffineTransform(translationX: 0, y: 100)
            snackbar.alpha = 0.0

            // Slide up animation
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.6,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    snackbar.transform = .identity
                    snackbar.alpha = 1.0
                },
                completion: nil
            )

            // Auto dismiss by sliding down
            let workItem = DispatchWorkItem { [weak snackbar] in
                guard let snackbar = snackbar, snackbar == currentSnackbar else { return }
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.curveEaseIn],
                    animations: {
                        snackbar.transform = CGAffineTransform(translationX: 0, y: 100)
                        snackbar.alpha = 0.0
                    },
                    completion: { _ in
                        if currentSnackbar == snackbar {
                            snackbar.removeFromSuperview()
                            currentSnackbar = nil
                        }
                    }
                )
            }

            dismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
        }
    }
}
