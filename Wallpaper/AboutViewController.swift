//
//  AboutViewController.swift
//  Wallpaper
//
//  Created by sl on 2018/6/7.
//  Copyright © 2018 shuliang. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {

    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var authorLabel: NSTextField!
    @IBOutlet weak var creditTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    private func configureUI() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        versionLabel.stringValue = "Version \(version)"
        
        authorLabel.isEditable = false
        let authorStr = NSMutableAttributedString(string: "Developed by ")
        guard let github = URL(string: "https://github.com/shuliang") else { return }
        let author = NSAttributedString.wp_linkedString(text: "@shuliang", url: github, font: NSFont.systemFont(ofSize: 12, weight: .light))
        authorStr.append(author)
        authorLabel.attributedStringValue = authorStr
    }
}

extension NSAttributedString {
    static func wp_linkedString(text: String, url: URL, font: NSFont = NSFont.systemFont(ofSize: 13)) -> NSAttributedString {
        let attrStr = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: attrStr.length)
        let attrs: [NSAttributedStringKey: Any] = [
            .link: url,
            .font: font,
            .foregroundColor: NSColor.blue
        ]
        attrStr.beginEditing()
        attrStr.addAttributes(attrs, range: range)
        attrStr.endEditing()
        
        return attrStr
    }
}
