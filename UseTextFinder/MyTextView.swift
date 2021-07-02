//
//  MyTextView.swift
//  UseTextFinder
//
//  Created by jim on 2021/5/17.
//  Copyright © 2021 Jim. All rights reserved.
//

import Cocoa

class MyTextView: NSTextView {

    let textFinder = NSTextFinder()

    let textFinderClient = MyTextFinderClient()

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        //print("MyTextView.validateMenuItem():", menuItem, menuItem.action)
        if menuItem.title.contains("Find") {
            return true
        }
        return super.validateMenuItem(menuItem)
    }

    override func performFindPanelAction(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else { return }
        print(menuItem.title)

        self.enclosingScrollView!.isFindBarVisible = true
        textFinder.incrementalSearchingShouldDimContentView = true
        textFinder.isIncrementalSearchingEnabled = true
        textFinderClient.documentContainerView = self
        textFinderClient.__clientDataSource = { () -> (NSMutableString, NSMutableIndexSet) in
            let clientString = NSMutableString(string: self.string)
            let charIndexes = NSMutableIndexSet(indexSet: [clientString.length])
            return (clientString, charIndexes)
        }

        _ = textFinderClient.reloadClientData()
        textFinder.findBarContainer = self.enclosingScrollView!
        textFinder.client = textFinderClient
        textFinderClient.textFinder = textFinder

        switch menuItem.title {
        case "Find…":
            textFinder.performAction(.showFindInterface)
        case "Find and Replace…":
            textFinder.performAction(.showReplaceInterface)
        case "Find Next":
            textFinder.performAction(.nextMatch)
        case "Find Previous":
            textFinder.performAction(.previousMatch)
        case "Use Selection for Find":
            _ = "Use Selection for Find"
        default:
            _ = "default"
            print("MyTextView.performFindPanelAction()")
        }
    }

    override func becomeFirstResponder() -> Bool {
        print("MyTextView().becomeFirstResponder()")
        textFinder.noteClientStringWillChange()
        _ = textFinderClient.reloadClientData()
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
        _ = textFinderClient.reloadClientData()
    }

}
