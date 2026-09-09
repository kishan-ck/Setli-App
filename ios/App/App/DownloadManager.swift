//
//  DownloadManager.swift
//  App
//
//  Created on 09/09/26.
//

import UIKit
import Photos
import WebKit

@objc public class DownloadManager: NSObject, WKScriptMessageHandler {

    public static let shared = DownloadManager()
    private weak var presentingViewController: UIViewController?

    public func configure(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "downloadHandler" else { return }

        if let dict = message.body as? [String: Any] {
            let urlString = dict["url"] as? String ?? ""
            let filename = dict["filename"] as? String
            let mimeType = dict["mimeType"] as? String

            handleDownload(urlString: urlString, suggestedFilename: filename, mimeType: mimeType)
        } else if let urlString = message.body as? String {
            handleDownload(urlString: urlString, suggestedFilename: nil, mimeType: nil)
        }
    }

    // MARK: - Main Download Handler

    public func handleDownload(urlString: String, suggestedFilename: String? = nil, mimeType: String? = nil) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("data:image/") {
            handleBase64ImageDownload(dataUrl: trimmed, customFilename: suggestedFilename)
        } else if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            handleHttpDownload(urlString: trimmed, customFilename: suggestedFilename, customMimeType: mimeType)
        } else {
            print("[DownloadManager] Unsupported download URL scheme: \(trimmed.prefix(50))")
        }
    }

    // MARK: - Base64 Image Download (QR Code / Generated Images)

    private func handleBase64ImageDownload(dataUrl: String, customFilename: String? = nil) {
        let parts = dataUrl.components(separatedBy: ",")
        guard parts.count == 2 else {
            showSnackbar("Invalid image data")
            return
        }

        let header = parts[0].lowercased()
        let base64Data = parts[1]

        var imageType = "png"
        if header.contains("image/jpeg") || header.contains("image/jpg") {
            imageType = "jpg"
        } else if header.contains("image/webp") {
            imageType = "webp"
        } else if header.contains("image/gif") {
            imageType = "gif"
        }

        guard let data = Data(base64Encoded: base64Data, options: .ignoreUnknownCharacters),
              let image = UIImage(data: data) else {
            showSnackbar("Invalid image data")
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let finalFilename = (customFilename?.isEmpty == false ? customFilename! : "Setli_\(timestamp).\(imageType)")

        // 1. Save directly into Documents/Setli directory (accessible via Apple Files app)
        let savedUrl = saveToDocuments(data: data, filename: finalFilename)

        // 2. Also save to Photos Library (Photos app)
        saveImageToPhotoLibrary(image: image, data: data, filename: finalFilename, documentSaved: savedUrl != nil)
    }

    // MARK: - HTTP / HTTPS File Download

    private func handleHttpDownload(urlString: String, customFilename: String? = nil, customMimeType: String? = nil) {
        guard let url = URL(string: urlString) else {
            showSnackbar("Invalid download URL")
            return
        }

        showSnackbar("Download started")

        var request = URLRequest(url: url)
        request.setValue("SetliApp-WebView", forHTTPHeaderField: "User-Agent")

        let task = URLSession.shared.downloadTask(with: request) { [weak self] (tempLocalUrl, response, error) in
            guard let self = self else { return }

            if let error = error {
                print("[DownloadManager] HTTP download error: \(error.localizedDescription)")
                self.showSnackbar("Unable to download file")
                return
            }

            guard let tempLocalUrl = tempLocalUrl else {
                self.showSnackbar("Unable to download file")
                return
            }

            let httpResponse = response as? HTTPURLResponse
            let mimeType = customMimeType ?? httpResponse?.mimeType ?? ""

            // Determine filename
            var filename = customFilename
            if filename == nil || filename?.isEmpty == true {
                if let contentDisposition = httpResponse?.allHeaderFields["Content-Disposition"] as? String ?? httpResponse?.allHeaderFields["content-disposition"] as? String {
                    filename = self.extractFilename(from: contentDisposition)
                }
            }
            if filename == nil || filename?.isEmpty == true {
                filename = response?.suggestedFilename
            }
            if filename == nil || filename?.isEmpty == true {
                let lastComponent = url.lastPathComponent
                if !lastComponent.isEmpty && lastComponent != "/" {
                    filename = lastComponent
                } else {
                    let ext = self.fileExtension(for: mimeType)
                    filename = "Setli_\(Int(Date().timeIntervalSince1970 * 1000)).\(ext)"
                }
            }

            let finalFilename = filename ?? "Setli_download"

            do {
                let fileManager = FileManager.default
                let docsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let setliDirectory = docsDirectory.appendingPathComponent("Setli", isDirectory: true)

                if !fileManager.fileExists(atPath: setliDirectory.path) {
                    try fileManager.createDirectory(at: setliDirectory, withIntermediateDirectories: true, attributes: nil)
                }

                let destinationUrl = setliDirectory.appendingPathComponent(finalFilename)

                if fileManager.fileExists(atPath: destinationUrl.path) {
                    try? fileManager.removeItem(at: destinationUrl)
                }

                try fileManager.moveItem(at: tempLocalUrl, to: destinationUrl)
                print("[DownloadManager] Saved HTTP download to: \(destinationUrl.path)")

                DispatchQueue.main.async {
                    let isImage = mimeType.starts(with: "image/") ||
                        ["png", "jpg", "jpeg", "webp", "gif"].contains((finalFilename as NSString).pathExtension.lowercased())

                    if isImage, let image = UIImage(contentsOfFile: destinationUrl.path) {
                        let fileData = try? Data(contentsOf: destinationUrl)
                        self.saveImageToPhotoLibrary(image: image, data: fileData, filename: finalFilename, documentSaved: true)
                    } else {
                        self.showSnackbar("File downloaded successfully")
                    }
                }

            } catch {
                print("[DownloadManager] File save error: \(error.localizedDescription)")
                self.showSnackbar("Unable to download file")
            }
        }

        task.resume()
    }

    // MARK: - Save to Documents Directory

    @discardableResult
    private func saveToDocuments(data: Data, filename: String) -> URL? {
        do {
            let fileManager = FileManager.default
            let docsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let setliDirectory = docsDirectory.appendingPathComponent("Setli", isDirectory: true)

            if !fileManager.fileExists(atPath: setliDirectory.path) {
                try fileManager.createDirectory(at: setliDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            let destinationUrl = setliDirectory.appendingPathComponent(filename)
            try data.write(to: destinationUrl, options: .atomic)
            print("[DownloadManager] Saved file to Documents/Setli: \(destinationUrl.path)")
            return destinationUrl
        } catch {
            print("[DownloadManager] Failed to save to documents: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Save to Photos Library

    private func saveImageToPhotoLibrary(image: UIImage, data: Data?, filename: String, documentSaved: Bool = false) {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .authorized, .limited:
            self.performSaveImage(image: image, data: data, filename: filename)
        case .notDetermined:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                    if newStatus == .authorized || newStatus == .limited {
                        self?.performSaveImage(image: image, data: data, filename: filename)
                    } else {
                        DispatchQueue.main.async {
                            if documentSaved {
                                self?.showSnackbar("Image downloaded successfully")
                            } else {
                                self?.showSnackbar("Photo library permission denied")
                            }
                        }
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                    if newStatus == .authorized {
                        self?.performSaveImage(image: image, data: data, filename: filename)
                    } else {
                        DispatchQueue.main.async {
                            if documentSaved {
                                self?.showSnackbar("Image downloaded successfully")
                            } else {
                                self?.showSnackbar("Photo library permission denied")
                            }
                        }
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                if documentSaved {
                    self.showSnackbar("Image downloaded successfully")
                } else {
                    self.showSnackbar("Photo library permission denied")
                }
            }
        @unknown default:
            DispatchQueue.main.async {
                if documentSaved {
                    self.showSnackbar("Image downloaded successfully")
                } else {
                    self.showSnackbar("Unable to save image")
                }
            }
        }
    }

    private func performSaveImage(image: UIImage, data: Data?, filename: String) {
        PHPhotoLibrary.shared().performChanges({
            if let data = data {
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = filename
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: options)
            } else {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }) { [weak self] (success, error) in
            DispatchQueue.main.async {
                if success {
                    self?.showSnackbar("Image downloaded successfully")
                } else {
                    print("[DownloadManager] Photos save error: \(error?.localizedDescription ?? "unknown")")
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    self?.showSnackbar("Image downloaded successfully")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func showSnackbar(_ message: String) {
        Snackbar.show(message: message, in: presentingViewController?.view)
    }

    private func extractFilename(from contentDisposition: String) -> String? {
        let pattern = "filename[^;=\\n]*=((['\"]).*?\\2|[^;\\n]*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: contentDisposition, options: [], range: NSRange(location: 0, length: contentDisposition.utf16.count)),
              let range = Range(match.range(at: 1), in: contentDisposition) else {
            return nil
        }
        var filename = String(contentDisposition[range]).trimmingCharacters(in: .whitespaces)
        if (filename.hasPrefix("\"") && filename.hasSuffix("\"")) || (filename.hasPrefix("'") && filename.hasSuffix("'")) {
            filename = String(filename.dropFirst().dropLast())
        }
        return filename.isEmpty ? nil : filename
    }

    private func fileExtension(for mimeType: String) -> String {
        switch mimeType.lowercased() {
        case "image/png": return "png"
        case "image/jpeg", "image/jpg": return "jpg"
        case "image/webp": return "webp"
        case "image/gif": return "gif"
        case "application/pdf": return "pdf"
        case "text/csv": return "csv"
        case "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": return "xlsx"
        case "application/zip": return "zip"
        default: return "bin"
        }
    }

    // MARK: - User Script for WebKit Injection

    public static var injectedUserScript: WKUserScript {
        let js = """
        (function() {
            if (window.__setliDownloadInterceptorInjected) return;
            window.__setliDownloadInterceptorInjected = true;

            function triggerNativeDownload(url, filename, mimeType) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.downloadHandler) {
                    window.webkit.messageHandlers.downloadHandler.postMessage({
                        url: url,
                        filename: filename || '',
                        mimeType: mimeType || ''
                    });
                    return true;
                }
                return false;
            }

            document.addEventListener('click', function(e) {
                var target = e.target;
                while (target && target.tagName !== 'A') {
                    target = target.parentElement;
                }
                if (!target || !target.href) return;

                var href = target.href;
                var hasDownloadAttr = target.hasAttribute('download');
                var downloadName = target.getAttribute('download') || '';

                // Handle data:image/ (e.g. QR codes)
                if (href.startsWith('data:image/')) {
                    e.preventDefault();
                    e.stopPropagation();
                    triggerNativeDownload(href, downloadName, href.substring(5, href.indexOf(';')));
                    return;
                }

                // Handle blob: URLs
                if (href.startsWith('blob:')) {
                    e.preventDefault();
                    e.stopPropagation();
                    fetch(href)
                        .then(function(res) { return res.blob(); })
                        .then(function(blob) {
                            var reader = new FileReader();
                            reader.onloadend = function() {
                                triggerNativeDownload(reader.result, downloadName, blob.type);
                            };
                            reader.readAsDataURL(blob);
                        })
                        .catch(function(err) {
                            console.error('[SetliDownload] Blob download failed:', err);
                        });
                    return;
                }

                // Handle downloadable links or links with download attribute
                var isDownloadableFile = /\\.(pdf|png|jpe?g|webp|gif|csv|xlsx?|docx?|zip)(\\?.*)?$/i.test(href);
                if (hasDownloadAttr || isDownloadableFile) {
                    if (href.startsWith('http://') || href.startsWith('https://')) {
                        e.preventDefault();
                        e.stopPropagation();
                        triggerNativeDownload(href, downloadName, '');
                    }
                }
            }, true);
        })();
        """

        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}
