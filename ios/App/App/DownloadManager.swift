//
//  DownloadManager.swift
//  App
//
//  Created on 09/09/26.
//

import UIKit
import Photos
import WebKit

@objc public class DownloadManager: NSObject, WKScriptMessageHandler, WKDownloadDelegate {

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

        // 1. BASE64 / DATA URI DOWNLOAD (All file types: PDF, ZIP, Images, CSV, XLSX, etc.)
        if trimmed.hasPrefix("data:") {
            handleBase64Download(dataUrl: trimmed, customFilename: suggestedFilename, mimeType: mimeType)
        } else if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            // 2. REMOTE HTTP / HTTPS DOWNLOAD
            handleHttpDownload(urlString: trimmed, customFilename: suggestedFilename, customMimeType: mimeType)
        } else {
            print("[DownloadManager] Unsupported download URL scheme: \(trimmed.prefix(50))")
        }
    }

    // MARK: - Base64 Download (All file types: PDF, ZIP, Images, CSV, XLSX, DOCX)

    public func handleBase64Download(dataUrl: String, customFilename: String? = nil, mimeType: String? = nil) {
        guard let commaIndex = dataUrl.firstIndex(of: ",") else {
            showSnackbar("Invalid download data")
            return
        }

        let header = String(dataUrl[..<commaIndex]).lowercased()
        let dataString = String(dataUrl[dataUrl.index(after: commaIndex)...])

        var fileExt = "bin"
        var resolvedMime = mimeType ?? "application/octet-stream"

        if header.contains("pdf") || resolvedMime.contains("pdf") {
            fileExt = "pdf"
            resolvedMime = "application/pdf"
        } else if header.contains("zip") || resolvedMime.contains("zip") {
            fileExt = "zip"
            resolvedMime = "application/zip"
        } else if header.contains("csv") || resolvedMime.contains("csv") {
            fileExt = "csv"
            resolvedMime = "text/csv"
        } else if header.contains("sheet") || header.contains("excel") || header.contains("xlsx") ||
                    resolvedMime.contains("sheet") || resolvedMime.contains("excel") {
            fileExt = "xlsx"
            resolvedMime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        } else if header.contains("image/png") || resolvedMime.contains("image/png") {
            fileExt = "png"
            resolvedMime = "image/png"
        } else if header.contains("image/jpeg") || header.contains("image/jpg") ||
                    resolvedMime.contains("image/jpeg") || resolvedMime.contains("image/jpg") {
            fileExt = "jpg"
            resolvedMime = "image/jpeg"
        } else if header.contains("image/webp") || resolvedMime.contains("image/webp") {
            fileExt = "webp"
            resolvedMime = "image/webp"
        } else if header.contains("image/gif") || resolvedMime.contains("image/gif") {
            fileExt = "gif"
            resolvedMime = "image/gif"
        } else if header.contains("msword") || header.contains("wordprocessingml") || header.contains("docx") ||
                    resolvedMime.contains("msword") || resolvedMime.contains("wordprocessingml") {
            fileExt = "docx"
            resolvedMime = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        }

        // Decode data
        var fileData: Data?
        if header.contains(";base64") {
            fileData = Data(base64Encoded: dataString, options: [.ignoreUnknownCharacters])
        } else if let unencoded = dataString.removingPercentEncoding {
            fileData = unencoded.data(using: .utf8)
        } else {
            fileData = dataString.data(using: .utf8)
        }

        guard let data = fileData else {
            showSnackbar("Unable to save file")
            return
        }

        // Determine filename matching Android Setli_<timestamp>.<ext>
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        var fileName = "Setli_\(timestamp).\(fileExt)"

        if let custom = customFilename?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            if custom.contains(".") {
                fileName = custom
            } else {
                fileName = "\(custom).\(fileExt)"
            }
        }

        // Save directly into Documents/Setli directory (visible in Apple Files app)
        guard let _ = saveToDocuments(data: data, filename: fileName) else {
            showSnackbar("Unable to save file")
            return
        }

        let isImage = resolvedMime.starts(with: "image/") || ["png", "jpg", "jpeg", "webp", "gif"].contains(fileExt)
        if isImage, let image = UIImage(data: data) {
            saveImageToPhotoLibrary(image: image, data: data, filename: fileName, documentSaved: true)
        } else {
            showSnackbar("Downloaded \(fileName)")
        }
    }

    // MARK: - HTTP / HTTPS File Download

    public func handleHttpDownload(urlString: String, customFilename: String? = nil, customMimeType: String? = nil) {
        guard let url = URL(string: urlString) else {
            showSnackbar("Invalid download URL")
            return
        }

        var initialFilename = customFilename
        if initialFilename == nil || initialFilename?.isEmpty == true {
            let lastComp = url.lastPathComponent
            if !lastComp.isEmpty && lastComp != "/" && lastComp.contains(".") {
                initialFilename = lastComp
            }
        }

        if let name = initialFilename, !name.isEmpty {
            showSnackbar("Downloading \(name)...")
        } else {
            showSnackbar("Downloading file...")
        }

        // Retrieve session cookies from WKWebsiteDataStore to maintain authentication
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }

            var request = URLRequest(url: url)
            request.setValue("SetliApp-WebView", forHTTPHeaderField: "User-Agent")

            // Attach session cookies matching domain so authenticated files download properly (matches Android CookieManager)
            let host = url.host ?? ""
            let matchedCookies = cookies.filter { cookie in
                return host.contains(cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: "."))) ||
                       cookie.domain.contains(host)
            }
            if !matchedCookies.isEmpty {
                let cookieHeader = matchedCookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
            }

            // Bypass headers for local development & tunnels (matches Android MainActivity)
            request.setValue("true", forHTTPHeaderField: "bypass-tunnel-reminder")
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
            request.setValue("application/pdf, application/zip, text/csv, */*", forHTTPHeaderField: "Accept")

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

                // Determine filename from Content-Disposition, suggestedFilename, or URL
                var filename = customFilename
                if filename == nil || filename?.isEmpty == true {
                    if let contentDisposition = httpResponse?.allHeaderFields["Content-Disposition"] as? String ??
                                                httpResponse?.allHeaderFields["content-disposition"] as? String {
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

                var finalFilename = filename ?? "Setli_download"
                finalFilename = self.sanitizeAndFixExtension(filename: finalFilename, mimeType: mimeType, url: url)

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
                            self.showSnackbar("Downloaded \(finalFilename)")
                        }
                    }

                } catch {
                    print("[DownloadManager] File save error: \(error.localizedDescription)")
                    self.showSnackbar("Unable to download file")
                }
            }

            task.resume()
        }
    }

    // MARK: - WKDownloadDelegate (iOS 15+ Native WebKit Downloads)

    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        var finalName = suggestedFilename
        let mimeType = response.mimeType ?? ""

        if let httpResponse = response as? HTTPURLResponse {
            if let disp = httpResponse.allHeaderFields["Content-Disposition"] as? String ??
                          httpResponse.allHeaderFields["content-disposition"] as? String {
                if let extracted = self.extractFilename(from: disp) {
                    finalName = extracted
                }
            }
        }

        finalName = sanitizeAndFixExtension(filename: finalName, mimeType: mimeType, url: response.url)

        let fileManager = FileManager.default
        let docsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let setliDirectory = docsDirectory.appendingPathComponent("Setli", isDirectory: true)

        if !fileManager.fileExists(atPath: setliDirectory.path) {
            try? fileManager.createDirectory(at: setliDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        let destinationUrl = setliDirectory.appendingPathComponent(finalName)

        if fileManager.fileExists(atPath: destinationUrl.path) {
            try? fileManager.removeItem(at: destinationUrl)
        }

        print("[DownloadManager] WKDownload saving to: \(destinationUrl.path)")
        completionHandler(destinationUrl)
    }

    public func downloadDidFinish(_ download: WKDownload) {
        DispatchQueue.main.async {
            self.showSnackbar("File downloaded successfully")
        }
    }

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        print("[DownloadManager] WKDownload failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.showSnackbar("Unable to download file")
        }
    }

    // MARK: - Filename & URL Helpers (Matching Android Logic)

    public func isDownloadableUrl(_ url: URL) -> Bool {
        let pathExt = url.pathExtension.lowercased()
        let downloadableExtensions = ["pdf", "csv", "xlsx", "xls", "zip", "doc", "docx"]
        return downloadableExtensions.contains(pathExt)
    }

    public func sanitizeAndFixExtension(filename: String, mimeType: String, url: URL?) -> String {
        var resolvedName = filename
        let urlLower = url?.absoluteString.lowercased() ?? ""
        let nameLower = filename.lowercased()
        let mimeLower = mimeType.lowercased()

        if urlLower.contains(".pdf") || mimeLower.contains("pdf") || nameLower.hasSuffix(".pdf") {
            if !nameLower.hasSuffix(".pdf") {
                resolvedName = (resolvedName.hasSuffix(".bin") ? String(resolvedName.dropLast(4)) : resolvedName) + ".pdf"
            }
        } else if urlLower.contains(".zip") || mimeLower.contains("zip") || nameLower.hasSuffix(".zip") {
            if !nameLower.hasSuffix(".zip") {
                resolvedName = (resolvedName.hasSuffix(".bin") ? String(resolvedName.dropLast(4)) : resolvedName) + ".zip"
            }
        } else if urlLower.contains(".csv") || mimeLower.contains("csv") || nameLower.hasSuffix(".csv") {
            if !nameLower.hasSuffix(".csv") {
                resolvedName = (resolvedName.hasSuffix(".bin") ? String(resolvedName.dropLast(4)) : resolvedName) + ".csv"
            }
        } else if urlLower.contains(".xlsx") || mimeLower.contains("sheet") || mimeLower.contains("excel") || nameLower.hasSuffix(".xlsx") {
            if !nameLower.hasSuffix(".xlsx") && !nameLower.hasSuffix(".xls") {
                resolvedName = (resolvedName.hasSuffix(".bin") ? String(resolvedName.dropLast(4)) : resolvedName) + ".xlsx"
            }
        }

        return resolvedName
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

    public func showSnackbar(_ message: String) {
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

            function isDownloadableUrl(url) {
                if (!url || typeof url !== 'string') return false;
                var cleanUrl = url.split('?')[0].split('#')[0];
                return /\\.(pdf|png|jpe?g|webp|gif|csv|xlsx?|docx?|zip)$/i.test(cleanUrl);
            }

            function extractMimeFromDataUrl(dataUrl) {
                if (!dataUrl || !dataUrl.startsWith('data:')) return '';
                var semi = dataUrl.indexOf(';');
                if (semi > 5) {
                    return dataUrl.substring(5, semi);
                }
                var comma = dataUrl.indexOf(',');
                if (comma > 5) {
                    return dataUrl.substring(5, comma);
                }
                return '';
            }

            function handleDownloadItem(href, downloadName) {
                if (!href || typeof href !== 'string') return false;

                // 1. data: URIs (All data URIs: PDF, CSV, Excel, Images, Zip, etc.)
                if (href.startsWith('data:')) {
                    var mime = extractMimeFromDataUrl(href);
                    triggerNativeDownload(href, downloadName, mime);
                    return true;
                }

                // 2. blob: URLs (Convert blob to data URI and trigger native download)
                if (href.startsWith('blob:')) {
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
                    return true;
                }

                // 3. Downloadable HTTP / HTTPS URLs (links with download attribute or downloadable extensions)
                if (href.startsWith('http://') || href.startsWith('https://')) {
                    if (downloadName || isDownloadableUrl(href)) {
                        triggerNativeDownload(href, downloadName, '');
                        return true;
                    }
                }

                return false;
            }

            // Intercept clicks on <a> tags (including dynamically inserted links)
            document.addEventListener('click', function(e) {
                var target = e.target;
                while (target && target.tagName !== 'A') {
                    target = target.parentElement;
                }
                if (!target || !target.href) return;

                var href = target.href;
                var downloadName = target.getAttribute('download') || '';

                if (handleDownloadItem(href, downloadName)) {
                    e.preventDefault();
                    e.stopPropagation();
                }
            }, true);

            // Intercept programmatic a.click() for elements not attached to document DOM
            var origClick = HTMLAnchorElement.prototype.click;
            HTMLAnchorElement.prototype.click = function() {
                var href = this.href || '';
                var downloadName = this.getAttribute('download') || '';
                if (handleDownloadItem(href, downloadName)) {
                    return;
                }
                origClick.apply(this, arguments);
            };

            // Delay blob URL revocation so asynchronous fetch has time to read data
            var origRevoke = URL.revokeObjectURL;
            URL.revokeObjectURL = function(url) {
                setTimeout(function() {
                    try { origRevoke(url); } catch(e) {}
                }, 15000);
            };

            // Intercept window.open for direct file/blob/data downloads
            var origOpen = window.open;
            window.open = function(url, target, features) {
                if (typeof url === 'string') {
                    if (url.startsWith('data:') || url.startsWith('blob:') || isDownloadableUrl(url)) {
                        if (handleDownloadItem(url, '')) {
                            return null;
                        }
                    }
                }
                return origOpen.apply(window, arguments);
            };
        })();
        """

        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}
