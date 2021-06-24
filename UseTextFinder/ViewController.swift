//
//  ViewController.swift
//  UseTextFinder
//
//  Created by jim on 2021/4/24.
//  Copyright © 2021 Jim. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextViewDelegate {

    /// - Tag: setRepresentedObjectExample
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }

    weak var document: Document? {
        if let docRepresentedObject = representedObject as? Document {
            return docRepresentedObject
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let textView = (self.view as? NSScrollView)?.documentView as? NSTextView {
            textView.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
            textView.layoutManager?.allowsNonContiguousLayout = true
            textView.textContainer?.containerSize = NSMakeSize(self.view.bounds.width, CGFloat.greatestFiniteMagnitude)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
    }

    // MARK: - NSTextViewDelegate

    func textDidBeginEditing(_ notification: Notification) {
        document?.objectDidBeginEditing(self)
    }

    func textDidEndEditing(_ notification: Notification) {
        document?.objectDidEndEditing(self)
    }

}
