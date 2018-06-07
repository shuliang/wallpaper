//
//  MainViewController.swift
//  Wallpaper
//
//  Created by sl on 2018/6/4.
//  Copyright © 2018 shuliang. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var setWallpaperButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var creatorButton: NSButton!
    @IBOutlet weak var downloadButton: NSButton!
    
    fileprivate var currentWallpaper: Wallpaper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNextPhoto(completion: nil)
    }
    
    // MARK: - Data Source
    
    private func loadNextPhoto(completion: ((NSImage?) -> Void)?) {
        disableUI()
        WallpaperManager.shared.fetchNextPhoto(.full) { (image, wallpaper, err) in
            guard let image = image, let wallpaper = wallpaper else {
                if completion != nil {
                    DispatchQueue.main.async {
                        completion?(nil)
                    }
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.enableUI()
                guard self != nil else { return }
                self!.imageView.image = image
                self!.creatorButton.attributedTitle = self!.genCreatorTitle(wallpaper)
                self!.currentWallpaper = wallpaper
                completion?(image)
            }
        }
    }
    
    // MARK: -  Event
    @IBAction func handleSetWallpaperButton(_ sender: Any) {
        guard let url = WallpaperManager.shared.saveImage(),
            let main = NSScreen.main else {
            return
        }
        do {
            let defaultOptions: [NSWorkspace.DesktopImageOptionKey: Any] = [
                .allowClipping: true,
                .fillColor: NSColor.black,
               .imageScaling: NSImageScaling.scaleAxesIndependently
            ]
            let opts = NSWorkspace.shared.desktopImageOptions(for: main) ?? defaultOptions
            try NSWorkspace.shared.setDesktopImageURL(url, for: main, options: opts)
        } catch let error {
            print("Set wallpaper error:", error)
        }
    }
    
    @IBAction func handleNextButton(_ sender: Any) {
        loadNextPhoto(completion: nil)
    }
    
    @IBAction func handleCreatorButton(_ sender: Any) {
        guard let url = currentWallpaper?.user?.links?.html else { return }
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func handleDownloadButton(_ sender: Any) {
        guard let url = WallpaperManager.shared.saveImage(toCache: false) else { return }
        NSWorkspace.shared.openFile(url.path)
    }
    
    // MARK: - Helper
    
    private func disableUI() {
        indicator.startAnimation(nil)
        indicator.isHidden = false
        let btns = [setWallpaperButton, nextButton, creatorButton, downloadButton]
        for btn in btns {
            btn?.isEnabled = false
        }
    }
    
    private func enableUI() {
        indicator.stopAnimation(nil)
        indicator.isHidden = true
        let btns = [setWallpaperButton, nextButton, creatorButton, downloadButton]
        for btn in btns {
            btn?.isEnabled = true
        }
    }
    
    private func genCreatorTitle(_ wallpaper: Wallpaper) -> NSAttributedString {
        let str = NSMutableAttributedString(string: "By ")
        let creator = wallpaper.user?.name ?? wallpaper.user?.username ?? "Anonymous"
        let attr = [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 13, weight: .semibold)]
        str.append(NSAttributedString(string: creator, attributes: attr))
        return str
    }
}

extension MainViewController {
    static func generateController() -> MainViewController {
        let sb = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let id = NSStoryboard.SceneIdentifier(rawValue: "MainViewController")
        guard let vc = sb.instantiateController(withIdentifier: id) as? MainViewController else {
            fatalError("Instantiate pop Controller failed.")
        }
        return vc
    }
}
