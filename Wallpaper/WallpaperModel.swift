//
//  WallpaperModel.swift
//  Wallpaper
//
//  Created by sl on 2018/6/4.
//  Copyright © 2018 shuliang. All rights reserved.
//

import Foundation

struct Links: Decodable {
    // user personal home page
    let html: URL?
}

// creator of photo - JSON["user"]
struct User: Decodable {
    let id: String?
    let name: String?
    let username: String?
    let links: Links?
}

// photo download urls
struct URLs: Decodable {
    let raw: URL?
    let full: URL?
    let regular: URL?
    let small: URL?
    let thumb: URL?
}

struct Wallpaper: Decodable {
    let id: String?
    let description: String?
    let user: User?
    let urls: URLs?
    
    init() {
        id = nil
        description = nil
        user = nil
        urls = nil
    }
}

enum WallpaperSize {
    case raw, full, regular, small, thumb
}
