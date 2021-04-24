//
//  Document.swift
//  UseTextFinder
//
//  Created by jim on 2021/4/24.
//  Copyright © 2021 Jim. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    
    @objc var content = Content(contentString: "")
    var contentViewController: ViewController!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }
    
    // MARK: - Enablers
    
    // This enables auto save.
    override class var autosavesInPlace: Bool {
        return true
    }
    
    // This enables asynchronous-writing.
    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
        return true
    }
    
    // This enables asynchronous reading.
    override class func canConcurrentlyReadDocuments(ofType: String) -> Bool {
        return ofType == "public.plain-text"
    }
    
    // MARK: - User Interface
    
    /// - Tag: makeWindowControllersExample
    override func makeWindowControllers() {
        // Returns the storyboard that contains your document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        if let windowController =
            storyboard.instantiateController(
                withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as? NSWindowController {
            addWindowController(windowController)
            
            // Set the view controller's represented object as your document.
            if let contentVC = windowController.contentViewController as? ViewController {
                contentVC.representedObject = content
                contentViewController = contentVC
            }
        }
    }
    
    // MARK: - Reading and Writing
    
    /// - Tag: readExample
    override func read(from data: Data, ofType typeName: String) throws {
        content.read(from: data)
    }
    
    /// - Tag: writeExample
    override func data(ofType typeName: String) throws -> Data {
        return content.data()!
    }

}
