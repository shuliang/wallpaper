//
//  WallpaperManager.swift
//  Wallpaper
//
//  Created by sl on 2018/6/4.
//  Copyright © 2018 shuliang. All rights reserved.
//

import Foundation
import Cocoa

class WallpaperManager {
    private let BASE_URL = "https://api.unsplash.com/photos/"
    private let CLIENT_ID = "e7c1d3097ab7e4779382d8b895bd9f0bd8d09e46dc52337f163d4d318ee0b493"
    
    private let WALLPAPER_DIR = "Wallpapers"
    
    // user default
    private let PHOTO_JSON = "io.github.shuliang.photo_json"
    private let REFRESH_COUNT = "io.github.shuliang.refresh_count"
    
    private let BATCH_SIZE = 30
    
    private var currentWallpaper: Wallpaper?
    /// Hold current saved photo Url, avoid requesting same API twice.
    /// Reset to nil when loading next photo
    private var currentSavedPhotoUrl : URL?
    
    static let shared = WallpaperManager()
    private init() {}
    
    // MARK: - Fetch Data    
    
    /// Fetch next photo model from local or API,
    /// then download photo of particular size, hold it in memory.
    ///
    /// - Parameters:
    ///   - size: wallpaper size, default is `.small`
    ///   - completion: (image, wallpaper model, error or nil)
    func fetchNextPhoto(_ size: WallpaperSize = .small, completion: @escaping (NSImage?, Wallpaper?, Error?) -> Void) {
        currentSavedPhotoUrl = nil
        retrieveNextWallpaperModel { [weak self] (model, error) in
            self?.currentWallpaper = model
            guard self != nil, let wallpaper = model else {
                completion(nil, nil, error)
                return
            }
            self?.downloadPhoto(size, wallpaper) { (data, error) in
                guard data != nil, let image = NSImage(data: data!) else {
                    completion(nil, wallpaper, error)
                    return
                }
                completion(image, wallpaper, nil)
            }
        }
    }
    
    /// Save image data of particular size to local path,
    /// if `toCache = true`, save image to cache directory,
    /// otherwise save to `~/Pictures/Wallpaper/unsplash_uuid_name.png`.
    ///
    /// - Parameters:
    ///   - size: wallpaper size, default size is `.full`
    ///   - toCache: save to cache directory if true, default is `true`.
    ///   - completion: (url: local storage url, error or nil)
    /// - Returns: local image url or nil if failed.
    /// - Warning: Call `fetchNextPhoto` first to generate wallpaper model, or it returns nil.
    func savePhoto(_ size: WallpaperSize = .full, toCache: Bool = true, completion: @escaping ((URL?, Error?) -> Void)) {
        // check cached photo url
        if let url = currentSavedPhotoUrl,
            let _ = NSImage(contentsOf: url),
            let desUrl = createLocalWallpaperUrl(toCache: false) {
            do {
                try FileManager.default.copyItem(at: url, to: desUrl)
                completion(desUrl, nil)
                return
            } catch let error {
                print("Copy cached photo failed, try to download again:", error)
            }
            // no return here, download photo directly
        }
        
        // no cached photo url, download the photo
        guard let wallpaper = currentWallpaper else {
            let err = NSError(domain: "savePhoto", code: -1, userInfo: ["err": "No wallpaper model."])
            completion(nil, err)
            return
        }
        downloadPhoto(size, wallpaper) { [weak self] (data, error) in
            guard self != nil,
                let rawImage = data,
                let fileUrl = self?.createLocalWallpaperUrl(toCache: toCache) else {
                completion(nil, error)
                return
            }
            do {
                let imageData = NSBitmapImageRep(data: rawImage)?.representation(using: .png, properties: [:])
                try imageData?.write(to: fileUrl, options: .atomic)
                self?.currentSavedPhotoUrl = fileUrl
                completion(fileUrl, nil)
                return
            } catch let error {
                completion(nil, error)
                return
            }
        }
    }
    
    // MARK: - private
    
    private func retrieveNextWallpaperModel(completion: @escaping (Wallpaper?, Error?) -> Void) {
        var wallpaper: Wallpaper?
        // get wallpaper from local storage
        var refreshCount = UserDefaults.standard.integer(forKey: REFRESH_COUNT)
        refreshCount += 1
        if refreshCount < BATCH_SIZE {
            if let m = retrieveLocalWallpaper(refreshCount) {
                wallpaper = m
            } else {
                let begin = refreshCount
                var stop = refreshCount
                for i in begin..<BATCH_SIZE {
                    if let m = retrieveLocalWallpaper(i) {
                        wallpaper = m
                        stop = i
                        break
                    }
                }
                refreshCount = stop
            }
        }
        if wallpaper != nil {
            UserDefaults.standard.set(refreshCount, forKey: REFRESH_COUNT)
            completion(wallpaper, nil)
            return
        }
        
        // if getting local wallpaper failed, fetch from API
        fetchAndStoreRandomWallpapersJSON { [weak self] (photos, err) in
            guard self != nil, let wallpapers = photos else {
                completion(nil, err)
                return
            }
            wallpaper = wallpapers.first!
            UserDefaults.standard.set(0, forKey: self!.REFRESH_COUNT)
            completion(wallpaper, nil)
        }
    }
    
    private func retrieveLocalWallpaper(_ index: Int) -> Wallpaper? {
        guard let data = UserDefaults.standard.object(forKey: PHOTO_JSON) as? Data else {
            return nil
        }
        do {
            let wallpapers = try JSONDecoder().decode([Wallpaper].self, from: data)
            if index < wallpapers.count && index >= 0 {
                return wallpapers[index]
            }
        } catch let error {
            print("Decode local wallpapers error:", error)
        }
        return nil
    }
    
    private func fetchAndStoreRandomWallpapersJSON(completion: @escaping ([Wallpaper]?, Error?) -> Void) {
        let url = BASE_URL + "random"
            + "?client_id=\(CLIENT_ID)"
            + "&count=\(BATCH_SIZE)"
        guard let randomPhotoURL = URL(string: url) else { return }

        URLSession.shared.dataTask(with: randomPhotoURL) { [weak self] (data, response, error) in
            guard self != nil, let data = data else {
                completion(nil, error)
                return
            }
            do {
                let wallpapers = try JSONDecoder().decode([Wallpaper].self, from: data)
                UserDefaults.standard.set(data, forKey: self!.PHOTO_JSON)
                completion(wallpapers, nil)
            } catch let error {
                print("Decode error:", error)
            }
        }.resume()
    }
    
    /// download photo from URL
    private func downloadPhoto(_ size: WallpaperSize, _ wallpaper: Wallpaper, completion: @escaping (Data?, Error?) -> Void) {
        guard let photoURL = getPhotoUrl(size, wallpaper) else {
            let err = NSError(domain: "downloadPhoto", code: -1, userInfo: ["err": "wallpaper'url is empty."])
            completion(nil, err)
            return
        }
        URLSession.shared.dataTask(with: photoURL) { [weak self] (data, response, error) in
            guard self != nil, let data = data else {
                completion(nil, error)
                return
            }
            completion(data, nil)
        }.resume()
    }
    
    // MARK: helper
    
    private func createLocalWallpaperUrl(toCache: Bool) -> URL? {
        do {
            let baseDir: FileManager.SearchPathDirectory = toCache ? .cachesDirectory : .picturesDirectory
            let picDir = try FileManager.default.url(for: baseDir, in: .userDomainMask, appropriateFor: nil, create: true)
            let wallpaperDir = picDir.appendingPathComponent(WALLPAPER_DIR, isDirectory: true)
            var isDir = ObjCBool(true)
            if !FileManager.default.fileExists(atPath: wallpaperDir.path, isDirectory: &isDir)
                || !isDir.boolValue {
                do {
                    try FileManager.default.createDirectory(at: wallpaperDir, withIntermediateDirectories: true, attributes: nil)
                } catch let error {
                    print("Create wallpaper directory faild:", error)
                    return nil
                }
            }
            let uuid = NSUUID().uuidString
            let beginOffset = Int(arc4random_uniform(UInt32(uuid.count > 10 ? uuid.count - 10 : 0)))
            let begin = uuid.index(uuid.startIndex, offsetBy: beginOffset)
            let end = uuid.count > 10 ? uuid.index(begin, offsetBy: 10) : uuid.endIndex
            let filename = "unsplash_" + String(uuid[begin..<end]) + ".png"
            return wallpaperDir.appendingPathComponent(filename)
        } catch let error {
            print("Create wallpaper file path faild:", error)
            return nil
        }
    }
    
    private func getPhotoUrl(_ size: WallpaperSize, _ wallpaper: Wallpaper) -> URL? {
        switch size {
        case .raw:
            return wallpaper.urls?.raw
        case .full:
            return wallpaper.urls?.full
        case .regular:
            return wallpaper.urls?.regular
        case .small:
            return wallpaper.urls?.small
        case .thumb:
            return wallpaper.urls?.thumb
        }
    }
}
