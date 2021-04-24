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


class MyTextView: NSTextView {
    
    let textFinder = MyTextFinder()

    let textFinderClient = MyTextFinderClient()

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        //print("MyTextView.validateMenuItem():", menuItem, menuItem.action)
        if menuItem.title == "Find…" {
            return true
        }
        return super.validateMenuItem(menuItem)
    }

    override func performFindPanelAction(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else { return }
        print(menuItem.title)
        switch menuItem.title {
        case "Find…":
            self.enclosingScrollView!.isFindBarVisible = true
            
            textFinder.incrementalSearchingShouldDimContentView = true
            textFinder.isIncrementalSearchingEnabled = true
            textFinderClient.documentContainerView = self
            textFinderClient.dataSource = { return self.string }
            textFinderClient.updateClientString()

            textFinder.findBarContainer = self.enclosingScrollView!
            textFinder.client = textFinderClient
            
            textFinder.performAction(.showFindInterface)
        default:
            print("MyTextView.performFindPanelAction()")
        }
    }

    override func becomeFirstResponder() -> Bool {
        print("MyTextView().becomeFirstResponder()")
        textFinder.noteClientStringWillChange()
        textFinderClient.updateClientString()
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        print("MyTextView().resignFirstResponder()")
        return super.resignFirstResponder()
    }

    override func didChangeText() {
        print("MyTextView().didChangeText()")
        super.didChangeText()
        self.textFinder.noteClientStringWillChange()
        textFinderClient.updateClientString()
    }

}


class MyTextFinder: NSTextFinder {

    

    override func performAction(_ op: NSTextFinder.Action) {
        print("MyTextFinder().performAction()")
        super.performAction(op)
    }

    override func validateAction(_ op: NSTextFinder.Action) -> Bool {
        print("MyTextFinder().validateAction()")
        return super.validateAction(op)
    }

}


/// Refer:
/// https://blog.timschroeder.net/2012/01/12/nstextfinder-magic/
/// https://github.com/couchbaselabs/LogLady.git
///
class MyTextFinderClient: NSTextFinderClient {

    

    private var textView: NSTextView {
        guard let docView = self.documentContainerView as? NSTextView
            else { return NSTextView() }
        return docView
    }
    
    /// After: selectFindMatch:completionHandler:
    /// Refer: https://github.com/VirgilSecurity/virgil-mail/blob/master/apple-mail/VirgilSecurityMail/src/MailHeaders/Mavericks_10.9.3/MailUI/ConversationViewFindController.h
    @objc func scrollFindMatchToVisible(_ findMatch: Any) {
        print("MyTextFinderClient().scrollFindMatchToVisible:", findMatch)
    }
    
    /// After: documentContainerView
    /// Refer: https://opensource.apple.com/source/WebCore/WebCore-7606.2.104.0.1/PAL/pal/spi/mac/NSTextFinderSPI.h
    /// - (void)selectFindMatch:(id <NSTextFinderAsynchronousDocumentFindMatch>)findMatch completionHandler:(void (^)(void))completionHandler
    @objc func selectFindMatch(_ findMatch: Any, completionHandler: @escaping () -> Void ) {
        print("MyTextFinderClient().selectFindMatch:completionHandler:", findMatch)
        //completionHandler();
    }

    /// After: findMatchesForString:relativeToMatch:findOptions:maxResults:resultCollector:
    @objc var documentContainerView: NSView?


    /// methodSignatureForSelector
    /// Related Crash Bug: assertion failure: "_needsGeometryInWindowDidChangeNotificationCount > 0" -> 0
    @objc var scrollTrackingView: NSScrollView? {
        return self.documentContainerView?.enclosingScrollView
    }

    /** contentView -> **/
    func rects(forCharacterRange range: NSRange) -> [NSValue]? {
        print("MyTextFinderClient().rects(): <-", range)

        var values = [NSValue]()

        var rectCount = 0
        let textView = self.textView
        guard let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer,
            let textRects = layoutManager.rectArray(forCharacterRange: range, withinSelectedCharacterRange: range, in: textContainer, rectCount: &rectCount)
            else { return nil }
        for iii in 0..<rectCount {
            values.append(NSValue(rect: textRects[iii]))
        }

        print("MyTextFinderClient().rects(): ->", values)
        return values

    }

    /** After: rects(forCharacterRange:) **/
    func drawCharacters(in range: NSRange, forContentView view: NSView) {
        print("MyTextFinderClient().drawCharacters(): <-", range)
        guard let textView = view as? NSTextView
            else { return }
        textView.layoutManager?.drawGlyphs(forGlyphRange: range, at: NSMakePoint(0, 0))

    }

    /* isSelectable == false */
    func contentView(at index: Int, effectiveCharacterRange outRange: NSRangePointer) -> NSView {
        print("MyTextFinderClient().contentView():", index, outRange.pointee, "-> \(scrollTrackingView!.className)")
        var values = [NSRange]()
        for iii in 1..<self.clientString.count {
            let value = NSMakeRange(iii-1, 1)
            values.append(value)
        }

        var mutableRange = NSRange(location: index, length: self.clientString.count)
        /** execute outRange.assign(from:count:) to invoke self.rects(forCharacterRange:) **/
        outRange.assign(from: &mutableRange, count: 1)
        /** Return a view to drawCharacters(in:forContentView:) contentView: **/
        return documentContainerView!
    }

    /* When the searched result has been matched. */
    var isSelectable: Bool {
        return true
    }

    /* NSTextFinder.Action => hideFindInterface */
    @objc func firstResponderWhenDeactivated() {
        print("MyTextFinderClient().firstResponderWhenDeactivated()")
    }

    /* I have no idea about what is the specific selector required by text finder client, so I am guessing. */
    /**
     Search: "findMatchesForString:relativeToMatch:findOptions:maxResults:resultCollector:"
     Refer: https://opensource.apple.com/source/WebKit2/WebKit2-7602.1.50.1.2/UIProcess/mac/WKTextFinderClient.mm.auto.html
     (void)findMatchesForString:(NclientString *)targetString relativeToMatch:(id <NSTextFinderAsynchronousDocumentFindMatch>)relativeMatch findOptions:(NSTextFinderAsynchronousDocumentFindOptions)findOptions maxResults:(NSUInteger)maxResults resultCollector:(void (^)(NSArray *matches, BOOL didWrap))resultCollector
     **/
    @objc func findMatchesForString(_ targetString: String, relativeToMatch: NSRangePointer, findOptions: Int, maxResults: UInt, resultCollector: (_ matches: NSArray?, _ didWrap: Bool) -> Void) {
        print("findMatchesForString:relativeToMatch:findOptions:maxResults:resultCollector:", terminator: " <- ")
        print(targetString, relativeToMatch, findOptions, maxResults)
        
        var values = [NSValue]()
        for iii in 1..<self.clientString.count {
            let value = NSValue(range: NSMakeRange(iii-1, 1))
            values.append(value)
        }
        
        //resultCollector([NSValue(range: NSRange(location: 0, length: 1))], false);
        //resultCollector(nil, true);
    }

    var isEditable: Bool {
        print("MyTextFinderClient().isEditable ->", true)
        return true
    }
    
    /// PreferredTextFinderStyle
    ///
    /// Return 1 to additionally display`Replace` field.
    @objc var preferredTextFinderStyle: Int {
        print("MyTextFinderClient().preferredTextFinderStyle ->", 1)
        return 1
    }

    @objc var findBarDrawsBackground: Bool {
        print("MyTextFinderClient().findBarDrawsBackground ->", true)
        return true
    }
    
    @objc var findBarUsesRegularControls: Bool {
        print("MyTextFinderClient().findBarUsesRegularControls ->", false)
        return false
    }
    
    var allowsMultipleSelection: Bool {
        print("MyTextFinderClient().allowsMultipleSelection ->", true)
        return true
    }

    /// Jim's API
    /// After got a searched result.
    open var findTheString = { (at: NSRange) -> () in
        
    }

    /// Jim's API
    /// Get text for searching.
    open var dataSource = { () -> String in
        return ""
    }
    open func updateClientString() {
        self.clientString = dataSource()
    }

    private var clientString = ""

    func string(at characterIndex: Int, effectiveRange outRange: NSRangePointer, endsWithSearchBoundary outFlag: UnsafeMutablePointer<ObjCBool>) -> String {
        print("MyTextFinderClient().stringAtIndex:effectiveRange:endsWithSearchBoundary:", terminator: " <- ")
        print(characterIndex, outRange.pointee, outFlag.pointee)
        var mutableFlag = ObjCBool(booleanLiteral: false)
        outFlag.assign(from: &mutableFlag, count: 1)
        var mutableRange = NSRange(location: 0, length: self.clientString.count)
        outRange.assign(from: &mutableRange, count: 1)
        print(outFlag.pointee, outRange.pointee)

        return self.clientString
    }

    func stringLength() -> Int {
        NSLog("------------------------------------")
        let lenght = self.clientString.count
        print("MyTextFinderClient().stringLength ->", lenght)
        return lenght
    }
    
    /// When isSelectable == true, implement recognized selector -[setSelectedRanges:]
    var selectedRanges: [NSValue] {
        set {
            print("MyTextFinderClient().setSelectedRanges:<-", newValue)
            self.textView.selectedRanges = newValue
        }
        get {
            print("MyTextFinderClient().getSelectedRanges")
            return [NSValue(range: NSMakeRange(1, 1))]
        }
    }

    /// This property work when
    /// textFinder.incrementalSearchingShouldDimContentView = true
    /// textFinder.isIncrementalSearchingEnabled = true
    /// Return Values will be delivered one by one to self.rects(forCharacterRange:)
    ///
    var visibleCharacterRanges: [NSValue] {
        var values = [NSValue]()
        values = [NSValue(range: NSMakeRange(0, self.clientString.count))]
        print("MyTextFinderClient().visibleCharacterRanges ->", values)
        return values
    }


    var firstSelectedRange: NSRange {
        let range = textView.selectedRange()
        print("MyTextFinderClient().firstSelectedRange ->", range)
        return range
    }

    func scrollRangeToVisible(_ range: NSRange) {
        print("MyTextFinderClient().scrollRangeToVisible():<-", range)
        self.textView.scrollRangeToVisible(range)
        self.textView.selectedRanges = [NSValue(range: range)]
    }

    init() {
        self.hash = 0
        self.description = "Demo: TextFinderClient"
    }

    /* Protocol stubs as below: */

    func isEqual(_ object: Any?) -> Bool {
        print("MyTextFinderClient().isEqual()")
        return true
    }

    var hash: Int

    var superclass: AnyClass?
    
    func `self`() -> Self {
        print("MyTextFinderClient().`self`()")
        return self
    }
    
    func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
        print("MyTextFinderClient().perform()")
        let obj = NSObject()
        return Unmanaged.passRetained(obj)
    }
    
    func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        print("MyTextFinderClient().perform()")
        let obj = NSObject()
        return Unmanaged.passRetained(obj)
    }
    
    func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        print("MyTextFinderClient().perform()")
        let obj = NSObject()
        return Unmanaged.passRetained(obj)
    }

    func isProxy() -> Bool {
        print("MyTextFinderClient().isProxy()")
        return true
    }
    
    func isKind(of aClass: AnyClass) -> Bool {
        print("MyTextFinderClient().isKind()")
        return true
    }
    
    func isMember(of aClass: AnyClass) -> Bool {
        print("MyTextFinderClient().isMember()")
        return true
    }
    
    func conforms(to aProtocol: Protocol) -> Bool {
        print("MyTextFinderClient().conforms()")
        return true
    }

    func responds(to aSelector: Selector!) -> Bool {
        /** Here you can declare the selector which you have implemented. **/
        /** If most of selectors are still unimplemented, the application will not crash, which will cause the console to report an error at most. **/
        /** Tip: `Any` can be used when you are uncertain about the type of a selector argument. **/
        let specialDescriptions: [String] = [
            /** Called when the FindBar will appear **/
            "`allowsMultipleSelection",
            "`findBarUsesRegularControls",
            "`findBarDrawsBackground",
            "`preferredTextFinderStyle",
            "`isEditable",

            /** NSTextFinder().isIncrementalSearchingEnabled == true **/
            "`contentViewAtIndex:effectiveCharacterRange:",
            "`rectsForCharacterRange:",
            "`visibleCharacterRanges",
            "`drawCharactersInRange:forContentView:",
            "scrollTrackingView",
            /** A: **/
            "firstResponderWhenDeactivated",
            /** B: **/
            "findMatchesForString:relativeToMatch:findOptions:maxResults:resultCollector:",
            "`documentContainerView",
            "`selectFindMatch:completionHandler:",
            "`scrollFindMatchToVisible:"
        ]

        let hasSelector = !specialDescriptions.contains(aSelector.description)
        print("MyTextFinderClient().responds():", aSelector.description, hasSelector)
        return hasSelector
    }
    
    var description: String

}
