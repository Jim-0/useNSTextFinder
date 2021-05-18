//
//  MyTextView+TextFinderClient.swift
//  UseTextFinder
//
//  Created by jim on 2021/5/17.
//  Copyright © 2021 Jim. All rights reserved.
//

import Cocoa

// MARK: - My Text Finder Client
/// Refer:
/// https://blog.timschroeder.net/2012/01/12/nstextfinder-magic/
/// https://github.com/couchbaselabs/LogLady.git
///
class MyTextFinderClient: NSTextFinderClient {

    open var textFinder: NSTextFinder?

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

        if let __rectsOfFindIndicator = self.__rectsOfFindIndicator {
            return __rectsOfFindIndicator(range)
        }

        var values = [NSValue]()

        var rectCount = 0

        guard let textView = self.documentContainerView as? NSTextView,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer,
            let textRects = layoutManager.rectArray(forCharacterRange: range, withinSelectedCharacterRange: range, in: textContainer, rectCount: &rectCount)
            else { return nil }
        for iii in 0..<rectCount {
            values.append(NSValue(rect: textRects[iii]))
        }

        print("MyTextFinderClient().rects(): ->", values)
        return values

    }

    /// External interface.
    open var __drawCharacters: ( (_ range: NSRange, _ forContentView: NSView) -> () )?
    /** After: rects(forCharacterRange:) **/
    func drawCharacters(in range: NSRange, forContentView view: NSView) {
        print("MyTextFinderClient().drawCharacters(): <-", range)
        if let __drawCharacters = self.__drawCharacters {
            __drawCharacters(range, view)
            return
        }
        if let textView = view as? NSTextView {
            textView.layoutManager?.drawGlyphs(forGlyphRange: range, at: NSMakePoint(0, 0))
        } else if let tableView = self.documentContainerView as? NSTableView {
            guard let rects = rects(forCharacterRange: range) as? [NSRect]
                else { return }
            for rect in rects {
                /** Draw for the rects. **/
                let image = NSImage(data: tableView.dataWithPDF(inside: rect))
                image?.draw(in: rect)

                /** Draw in rects. **/
                let targetRow = tableView.row(at: NSPoint(x: rect.midX, y: rect.midY))
                let targetColumn = tableView.column(at: NSPoint(x: rect.midX, y: rect.midY))
                guard targetRow > -1, targetColumn > -1,
                    let rowView = tableView.rowView(atRow: targetRow, makeIfNecessary: true),
                    let cellView = rowView.view(atColumn: targetColumn) as? NSTableCellView,
                    let textField = cellView.textField
                    else { return }

                if cellView.isHidden { return }

                let indexes = self.charIndexes
                for iii in 0..<(indexes.count-1) {
                    let lowerBound = indexes[iii]
                    let upperBound = indexes[iii+1]
                    let targetIndex = range.location
                    if targetIndex >= upperBound || targetIndex < lowerBound || lowerBound == upperBound {
                        continue
                    }
                    let subStringRange = NSMakeRange(targetIndex-lowerBound, range.length)
                    let oldAS = textField.attributedStringValue
                    let mutableAS = NSMutableAttributedString(attributedString: oldAS)
                    mutableAS.addAttributes([.foregroundColor: NSColor.clear], range: NSMakeRange(0, mutableAS.length))
                    mutableAS.addAttributes([.backgroundColor: NSColor.orange, .foregroundColor: NSColor.black], range: subStringRange)
                    mutableAS.draw(in: rect.insetBy(dx: 3.5, dy: 1))
                    break
                }
            }

        }
    }

    /* isSelectable == false */
    func contentView(at index: Int, effectiveCharacterRange outRange: NSRangePointer) -> NSView {
        print("MyTextFinderClient().contentView():", index, "-> \(documentContainerView!.className)")

        var mutableRange = NSRange(location: 0, length: self.clientString.count)
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
    @objc var firstResponderWhenDeactivated: Any? {
        print("MyTextFinderClient().firstResponderWhenDeactivated")
        let responder = self.documentContainerView
        return responder
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

    func didReplaceCharacters() {
        _ = self.reloadClientData()
    }

    /** Bug: Find indicator can not automatically step forward after replace to a `Same-Leading` string. **/
    func replaceCharacters(in range: NSRange, with string: String) {
        print("MyTextFinderClient().replaceCharactersInRange:withString: <-", range, string)
        if let textView = documentContainerView as? NSTextView {
            textView.replaceCharacters(in: range, with: string)
            let newRange = NSMakeRange(range.location, string.count)
            textView.selectedRanges = [NSValue(range: newRange)]
        }
    }

    /// External interface.
    open var __shouldReplaceCharacters: ( (_ inRanges: [NSValue], _ with: [String]) -> Bool )?

    func shouldReplaceCharacters(inRanges ranges: [NSValue], with strings: [String]) -> Bool {
        print("MyTextFinderClient().shouldReplaceCharactersInRanges:withStrings: <-", ranges, strings)
        if let __shouldReplace = self.__shouldReplaceCharacters {
            return __shouldReplace(ranges, strings)
        }
        if let ranges = ranges as? [NSRange],
            ranges.contains(where: {$0.length == 0}) {
            /** Xcode takes measures to disable the `Replace` button in tihs case. **/
            self.textFinder?.performAction(.nextMatch)
            return false
        }
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

    /// External interface.
    /// An array containing the located text in the content view’s coordinate system.
    ///
    /// - returns: An array containing the rectangles containing the located text in the content view object’s coordinate system and return that array. The rectangles are return wrapped as NSValue objects.
    open var __rectsOfFindIndicator: ( (_ for: NSRange) -> [NSValue]? )?

    /// External interface.
    /// Get text for searching.
    open var __clientDataSource = { () -> (String, [Int]) in
        return ("", [0, 0])
    }
    /// Returned client data can be reused by outer instance.
    open func reloadClientData() -> (String, [Int]) {
        let data = self.__clientDataSource()
        assert(data.1.count > 1, "Indexes must contain at least 2 elements!\n")
        self.clientString = data.0
        self.charIndexes = data.1
        return data
    }

    private var charIndexes = [Int]()
    private var clientString = ""

    private var recordedRange = NSRange(location: 0, length: 0)

    func string(at characterIndex: Int, effectiveRange outRange: NSRangePointer, endsWithSearchBoundary outFlag: UnsafeMutablePointer<ObjCBool>) -> String {
        print("MyTextFinderClient().stringAtIndex:effectiveRange:endsWithSearchBoundary: <-", characterIndex)
        var mutableFlag = ObjCBool(booleanLiteral: true)
        outFlag.assign(from: &mutableFlag, count: 1)
        var mutableRange = NSRange(location: 0, length: self.clientString.count)

        var subString = self.clientString
        for iii in 0..<(charIndexes.count-1) {
            let lowerBound = charIndexes[iii]
            let upperBound = charIndexes[iii+1]
            if lowerBound != characterIndex || lowerBound == upperBound { continue }
            mutableRange = NSMakeRange(lowerBound, upperBound-lowerBound)
            let wholeString = NSString(string: subString)
            subString = wholeString.substring(with: mutableRange)
            break
        }
        outRange.assign(from: &mutableRange, count: 1)
        print("MyTextFinderClient().stringAtIndex:effectiveRange:endsWithSearchBoundary: ->", outRange.pointee)

        return subString
    }

    func stringLength() -> Int {
        let lenght = self.clientString.count
        print("MyTextFinderClient().stringLength ----------------------------->", lenght)
        return lenght
    }

    /// When isSelectable == true, implement recognized selector -[setSelectedRanges:]
    var selectedRanges: [NSValue] {
        set {
            print("MyTextFinderClient().setSelectedRanges:<-", newValue)
            if let textView = self.documentContainerView as? NSTextView {
                textView.selectedRanges = newValue
            } else {
                guard let ranges = newValue as? [NSRange]
                    else { return }
                self.recordedRange = ranges[0]
            }
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

    /// External interface.
    open var __firstSelectedRange: ( () -> NSRange )?
    var firstSelectedRange: NSRange {
        var range = self.recordedRange
        if let __firstSelectedRange = self.__firstSelectedRange {
            range = __firstSelectedRange()
        } else if let textView = self.documentContainerView as? NSTextView {
            range = textView.selectedRange()
        }
        print("MyTextFinderClient().firstSelectedRange ->", range)
        return range
    }

    /// External interface.
    open var __scrollRangeToVisible: ( (_ range: NSRange) -> Void )?
    func scrollRangeToVisible(_ range: NSRange) {
        print("MyTextFinderClient().scrollRangeToVisible():<-", range)
        if let __scrollRangeToVisible = self.__scrollRangeToVisible {
            __scrollRangeToVisible(range)
            return
        }
        if let textView = self.documentContainerView as? NSTextView {
            textView.scrollRangeToVisible(range)
            textView.selectedRanges = [NSValue(range: range)]
        } else {
            guard let rects = rects(forCharacterRange: range) as? [NSRect],
                let documentView = self.documentContainerView
                else { return }
            for iii in rects {
                if !documentView.enclosingScrollView!.documentVisibleRect.contains(iii) {
                    documentView.scroll(NSPoint(x: iii.minX-documentView.visibleRect.width/2, y: iii.minY-documentView.visibleRect.height/2))
                }
                documentView.scrollToVisible(iii)
            }
        }
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
            "`firstResponderWhenDeactivated",
            /** B: **/
            "findMatchesForString:relativeToMatch:findOptions:maxResults:resultCollector:",
            "`documentContainerView",
            "`selectFindMatch:completionHandler:",
            "`scrollFindMatchToVisible:",
            /** Replace **/
            "`replaceCharactersInRange:withString:",
            "`shouldReplaceCharactersInRanges:withStrings:",
            "`didReplaceCharacters"
        ]

        let hasSelector = !specialDescriptions.contains(aSelector.description)
        print("MyTextFinderClient().responds():", aSelector.description, hasSelector)
        return hasSelector
    }

    var description: String

}
