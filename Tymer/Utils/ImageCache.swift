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
}
