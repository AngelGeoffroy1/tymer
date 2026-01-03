//
//  ImageCache.swift
//  Tymer
//
//  Created by Angel Geoffroy on 03/01/2026.
//

import UIKit

// MARK: - Image Cache for faster loading

/// Singleton cache for storing loaded images in memory.
/// Used for avatar images and moment photos to avoid repeated network requests.
final class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    private var preloadingTasks: Set<String> = []
    private let preloadQueue = DispatchQueue(label: "com.tymer.imagePreload", attributes: .concurrent)
    private let lock = NSLock()

    private init() {
        cache.countLimit = 100  // Max 100 images
        cache.totalCostLimit = 150 * 1024 * 1024 // 150 MB
    }

    /// Get an image from the cache
    /// - Parameter key: The cache key (typically the image URL)
    /// - Returns: The cached UIImage if available, nil otherwise
    func get(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    /// Store an image in the cache
    /// - Parameters:
    ///   - image: The UIImage to cache
    ///   - key: The cache key (typically the image URL)
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    /// Remove an image from the cache
    /// - Parameter key: The cache key to remove
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Clear all cached images
    func clearAll() {
        cache.removeAllObjects()
    }
    
    /// Check if an image is already cached
    func contains(key: String) -> Bool {
        cache.object(forKey: key as NSString) != nil
    }
    
    // MARK: - Preloading
    
    /// Preload images from Supabase paths in the background
    /// - Parameter paths: Array of Supabase storage paths to preload
    func preloadImages(paths: [String]) {
        for path in paths {
            preloadImage(path: path)
        }
    }
    
    /// Preload a single image in the background
    /// - Parameter path: The Supabase storage path
    private func preloadImage(path: String) {
        // Skip if already cached or already preloading
        guard !contains(key: path) else { return }
        
        lock.lock()
        guard !preloadingTasks.contains(path) else {
            lock.unlock()
            return
        }
        preloadingTasks.insert(path)
        lock.unlock()
        
        // Load in background
        Task.detached(priority: .background) { [weak self] in
            guard let url = await SupabaseManager.shared.getMomentImageURL(path) else {
                await MainActor.run { self?.removeFromPreloading(path) }
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run { self?.set(image, forKey: path) }
                }
            } catch {
                // Silently fail for preloading
            }
            
            await MainActor.run { self?.removeFromPreloading(path) }
        }
    }
    
    private func removeFromPreloading(_ path: String) {
        lock.lock()
        preloadingTasks.remove(path)
        lock.unlock()
    }
    
    /// Preload images for a list of moments
    /// - Parameter moments: Array of moments to preload images for
    func preloadMomentImages(_ moments: [Moment]) {
        let supabasePaths = moments.compactMap { moment -> String? in
            guard let path = moment.imageName,
                  PhotoLoader.isSupabasePath(path) else { return nil }
            return path
        }
        preloadImages(paths: supabasePaths)
    }
}
