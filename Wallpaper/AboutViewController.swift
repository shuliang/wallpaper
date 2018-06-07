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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.styleMask.remove(.resizable)
    }
    
    private func configureUI() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        versionLabel.stringValue = "Version \(version)"        
    }
}

// MARK: - SubstringLinkedTextField

// workaround, see more:
// https://stackoverflow.com/questions/38340282/simple-clickable-link-in-cocoa-and-swift
// A text field that can contain a hyperlink within a range of characters in the text.
@IBDesignable
public class SubstringLinkedTextField: NSTextField {
    // the URL that will be opened when the link is clicked.
    public var link: String = ""
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'link' instead.")
    @IBInspectable public var HREF: String {
        get {
            return self.link
        }
        set {
            self.link = newValue
            self.needsDisplay = true
        }
    }
    
    // the substring within the field's text that will become an underlined link. if empty or no match found, the entire text will become the link.
    public var linkText: String = ""
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'linkText' instead.")
    @IBInspectable public var LinkText: String {
        get {
            return self.linkText
        }
        set {
            self.linkText = newValue
            self.needsDisplay = true
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        self.allowsEditingTextAttributes = true
        self.isSelectable = true
        
        let url = URL(string: self.link)
        let attributes: [NSAttributedStringKey: Any] = [
            .link: url as Any,
            .font: self.font as Any
        ]
        let attributedStr = NSMutableAttributedString(string: self.stringValue)
        
        if self.linkText.count > 0 {
            if let range = self.stringValue.range(of: self.linkText) {
                let nsRange = self.stringValue.nsRange(from: range)
                attributedStr.setAttributes(attributes, range: nsRange)
            } else {
                attributedStr.setAttributes(attributes, range: NSMakeRange(0, self.stringValue.count))
            }
        } else {
            attributedStr.setAttributes(attributes, range: NSMakeRange(0, self.stringValue.count))
        }
        self.attributedStringValue = attributedStr
    }
}

extension StringProtocol where Index == String.Index {
    func nsRange(from range: Range<Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}
