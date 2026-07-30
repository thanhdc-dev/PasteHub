//
//  ImageStorageManager.swift
//  PasteHub
//
//  Quản lý lưu trữ ảnh clipboard ra file system.
//  Tách khỏi DatabaseManager để giữ Single Responsibility.
//

import AppKit

final class ImageStorageManager {
    static let shared = ImageStorageManager()

    private let appSupportURL: URL = {
        let urls = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        return urls[0].appendingPathComponent("PasteHub", isDirectory: true)
    }()

    private var imagesDirectoryURL: URL {
        appSupportURL.appendingPathComponent("images", isDirectory: true)
    }

    private let imageCache = NSCache<NSString, NSImage>()
    private let imageDataCache = NSCache<NSString, NSData>()

    private init() {
        imageCache.countLimit = 100
        imageDataCache.countLimit = 100
    }

    // MARK: - Setup

    func setupDirectories() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: appSupportURL,
                               withIntermediateDirectories: true)
        try fm.createDirectory(at: imagesDirectoryURL,
                               withIntermediateDirectories: true)
    }

    // MARK: - Save

    /// Lưu ảnh từ NSPasteboard ra disk, trả về filename.
    func saveImage(from pasteboard: NSPasteboard) -> String? {
        let imageData: Data?
        let ext: String

        if let png = pasteboard.data(forType: .png) {
            imageData = png
            ext = "png"
        } else if let tiff = pasteboard.data(forType: .tiff),
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) {
            imageData = png
            ext = "png"
        } else {
            return nil
        }

        guard let data = imageData else { return nil }

        let filename = "\(UUID().uuidString).\(ext)"
        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            print("Lỗi lưu ảnh: \(error)")
            return nil
        }
    }

    // MARK: - Load

    func loadImage(named filename: String) -> NSImage? {
        let cacheKey = filename as NSString
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }

        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        guard let image = NSImage(contentsOf: fileURL) else { return nil }

        imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    func loadImageData(named filename: String) -> Data? {
        let cacheKey = filename as NSString
        if let cachedData = imageDataCache.object(forKey: cacheKey) {
            return cachedData as Data
        }

        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        imageDataCache.setObject(data as NSData, forKey: cacheKey)
        return data
    }

    // MARK: - Delete

    func deleteImageFile(named filename: String) {
        let cacheKey = filename as NSString
        imageCache.removeObject(forKey: cacheKey)
        imageDataCache.removeObject(forKey: cacheKey)

        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Cleanup

    func cleanupOrphanedImages(referencedFiles: Set<String>) throws {
        let fm = FileManager.default
        let existingFiles = (try? fm.contentsOfDirectory(atPath: imagesDirectoryURL.path)) ?? []

        for file in existingFiles where !referencedFiles.contains(file) {
            let fileURL = imagesDirectoryURL.appendingPathComponent(file)
            try? fm.removeItem(at: fileURL)
        }
    }
}
