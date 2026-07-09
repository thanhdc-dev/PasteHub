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

    private init() {}

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
        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        return NSImage(contentsOf: fileURL)
    }

    func loadImageData(named filename: String) -> Data? {
        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }

    // MARK: - Delete

    func deleteImageFile(named filename: String) {
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
