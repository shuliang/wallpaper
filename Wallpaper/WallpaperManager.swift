//
//  WallpaperManager.swift
//  Wallpaper
//
//  Created by sl on 2018/6/4.
//  Copyright © 2018 shuliang. All rights reserved.
//

import Foundation

class WallpaperManager {
    static let BASE_URL = "https://api.unsplash.com/photos/"
    static let CLIENT_ID = "e7c1d3097ab7e4779382d8b895bd9f0bd8d09e46dc52337f163d4d318ee0b493"
    
    static func fetchRandomPhotos(complete: @escaping (_ model: Wallpaper?) -> Void) -> Void {
        let url = BASE_URL + "random"
            + "?client_id=\(CLIENT_ID)"
            + "&count=20"
        guard let randomPhotoURL = URL(string: url) else { return }

        URLSession.shared.dataTask(with: randomPhotoURL) { (data, response, error) in
            guard let data = data else {
                print("fetch data error:", error ?? "unknown")
                return
            }
            do {
                let photos = try JSONDecoder().decode([Wallpaper].self, from: data)
                photos.forEach { print($0) }
                complete(photos.first)
            } catch let error {
                print("Decode error:", error)
            }
        }.resume()
    }
}
