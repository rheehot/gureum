//
//  InputViewController.swift
//  inputmethod
//
//  Created by Jeong YunWon on 2014. 6. 3..
//  Copyright (c) 2014년 youknowone.org. All rights reserved.
//

import Crashlytics
import Fabric
import UIKit

var crashlyticsInitialized = false

var globalInputViewController: InputViewController?
var sharedInputMethodView: InputMethodView?
var launchedDate: NSDate = NSDate()

class BasicInputViewController: UIInputViewController {
    lazy var inputMethodView: InputMethodView = { InputMethodView(frame: self.view.bounds) }()
    var willContextBeforeInput: String = ""
    var willContextAfterInput: String = ""
    var didContextBeforeInput: String = ""
    var didContextAfterInput: String = ""

    override func textWillChange(_ textInput: UITextInput?) {
        // self.log("text will change")
        super.textWillChange(textInput)
        let proxy = textDocumentProxy
        willContextBeforeInput = proxy.documentContextBeforeInput ?? ""
        willContextAfterInput = proxy.documentContextAfterInput ?? ""
    }

    override func textDidChange(_ textInput: UITextInput?) {
        // self.log("text did change")
        let proxy = textDocumentProxy
        didContextBeforeInput = proxy.documentContextBeforeInput ?? ""
        didContextAfterInput = proxy.documentContextAfterInput ?? ""
        super.textDidChange(textInput)
    }

    override func selectionDidChange(_: UITextInput?) {
        // self.log("selection did change:")
        inputMethodView.resetContext()
        //        self.keyboard.view.logTextView.backgroundColor = UIColor.redColor()
    }

    override func selectionWillChange(_: UITextInput?) {
        // self.log("selection will change:")
        inputMethodView.resetContext()
        //        self.keyboard.view.logTextView.backgroundColor = UIColor.blueColor()
    }

    lazy var logTextView: UITextView = {
        let rect = CGRect(x: 0, y: 0, width: 300, height: 200)
        let textView = UITextView(frame: rect)
        textView.backgroundColor = UIColor.clear
        textView.isUserInteractionEnabled = false
        textView.textColor = UIColor.red
        self.view.addSubview(textView)
        return textView
    }()

    func log(text: String) {
        #if DEBUG
            println(text)
            return;

            let diff = String(format: "%.3f", NSDate().timeIntervalSinceDate(launchedDate))
            logTextView.text = diff + "> " + text + "\n" + logTextView.text
            view.bringSubviewToFront(logTextView)
        #endif
    }

    func input(_: GRInputButton) {}

    func inputDelete(_: GRInputButton) {}

    func reloadInputMethodView() {}
}

class DebugInputViewController: BasicInputViewController {
    var initialized = false
    var modeDate = NSDate()

    override func loadView() {
        view = inputMethodView
    }

    override func viewDidLoad() {
        // assert(globalInputViewController == nil, "input view controller is set?? \(globalInputViewController)")
        log(text: "loaded: \(view.frame)")
        // globalInputViewController = self
        super.viewDidLoad()

        initialized = true
        let proxy = textDocumentProxy as UITextInputTraits
        log(text: "adding input method view")
        inputMethodView.loadCollections(traits: proxy)
        log(text: "added method view")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if initialized {
            // self.log("viewWillLayoutSubviews \(self.view.bounds)")
            inputMethodView.transitionViewToSize(size: view.bounds.size, withTransitionCoordinator: transitionCoordinator)
        }
    }

    override func viewDidLayoutSubviews() {
        if initialized {
            // self.log("viewDidLayoutSubviews \(self.view.bounds)")
            inputMethodView.transitionViewToSize(size: view.bounds.size, withTransitionCoordinator: transitionCoordinator)
        }
        super.viewDidLayoutSubviews()
    }
}

class InputViewController: BasicInputViewController {
    var initialized = false
    var modeDate = NSDate()
    var lastTraits: UITextInputTraits!

    // overriding `init` causes crash
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//    }
//
//    required init(coder: NSCoder) {
//        super.init(coder: coder)
//    }

    override func reloadInputMethodView() {
        let proxy = textDocumentProxy as UITextInputTraits
        inputMethodView.loadCollections(traits: proxy)
        // self.inputMethodView.adjustTraits(proxy)
        inputMethodView.adjustedSize = CGSize.zero
        // println("bounds: \(self.view.bounds)")
        inputMethodView.transitionViewToSize(size: view.bounds.size, withTransitionCoordinator: nil)
    }

    override func viewDidLoad() {
        if !crashlyticsInitialized {
            // Crashlytics().debugMode = true
//            Crashlytics.startWithAPIKey("1b5d8443c3eabba778b0d97bff234647af846181")
            Fabric.with([Crashlytics()])
            crashlyticsInitialized = true
        }
        // assert(globalInputViewController == nil, "input view controller is set?? \(globalInputViewController)")
        // self.log("loaded: \(self.view.frame)")
        super.viewDidLoad()

        globalInputViewController = self
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !initialized, view.bounds != CGRect.zero {
            view = inputMethodView
            let traits = textDocumentProxy as UITextInputTraits
            lastTraits = traits
            inputMethodView.loadCollections(traits: traits)

            if preferences.swipe {
                let leftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(InputViewController.leftForSwipeRecognizer(_:)))
                leftRecognizer.direction = .left
                let rightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(InputViewController.rightForSwipeRecognizer(_:)))
                rightRecognizer.direction = .right
                view.addGestureRecognizer(leftRecognizer)
                view.addGestureRecognizer(rightRecognizer)
            }

            initialized = true
        }
    }

    override func viewDidLayoutSubviews() {
        if initialized {
            inputMethodView.transitionViewToSize(size: view.bounds.size, withTransitionCoordinator: transitionCoordinator)
        }
        super.viewDidLayoutSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
//        self.keyboard.view.logTextView.text = ""
        super.textDidChange(textInput)
        if !initialized {
            return
        }

        if willContextBeforeInput != didContextBeforeInput || willContextAfterInput != didContextAfterInput {
            inputMethodView.resetContext()
            inputMethodView.selectedCollection.selectLayoutIndex(index: 0)
            inputMethodView.selectedLayout.view.shiftButton?.isSelected = false
            inputMethodView.selectedLayout.helper.updateCaptionLabel()
        }
        if let traits = textInput as UITextInput? {
            lastTraits = traits // for app
        } else {
            lastTraits = textDocumentProxy as UITextInputTraits // for keyboard
        }
        adjustTraits(traits: lastTraits)
    }

    func adjustTraits(traits: UITextInputTraits) {
        var textColor: UIColor
        if traits.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }

        inputMethodView.adjustTraits(traits: traits)
        inputMethodView.transitionViewToSize(size: view.bounds.size, withTransitionCoordinator: nil)

        let selectedLayout = inputMethodView.selectedLayout
        let proxy = textDocumentProxy

        if traits.enablesReturnKeyAutomatically ?? false, (didContextBeforeInput.count + didContextAfterInput.count) == 0 {
            selectedLayout.view.doneButton.isEnabled = false
        } else {
            selectedLayout.view.doneButton.isEnabled = true
        }

        if type(of: selectedLayout).capitalizable {
            if selectedLayout.shift == .Auto {
                selectedLayout.shift = .Off
            }
            if type(of: selectedLayout).capitalizable, selectedLayout.shift != .Auto {
                var needsShift = false
                switch traits.autocapitalizationType! {
                case .allCharacters:
                    needsShift = true
                case .words:
                    if didContextBeforeInput.count == 0 {
                        needsShift = true
                    } else {
                        let whitespaces = NSCharacterSet.whitespacesAndNewlines
                        let lastCharacter = didContextBeforeInput.unicodeScalars.last!
                        needsShift = whitespaces.contains(lastCharacter)
                    }
                case .sentences:
                    let whitespaces = NSCharacterSet.whitespaces

                // FIXME: porting
                /*
                 let punctuations = NSCharacterSet(charactersIn: ".!?")
                 let utf16 = self.didContextBeforeInput.utf16
                 var index = utf16.endIndex
                 needsShift = true
                 while index != utf16.startIndex {
                 index = index.predecessor()
                 let code = utf16[index]
                 if punctuations.characterIsMember(code) || code == 10 {
                 let nextIndex = index.successor()
                 if utf16.endIndex != nextIndex && utf16[nextIndex] == 32 {
                 break
                 }
                 }
                 if !whitespaces.characterIsMember(code) {
                 needsShift = false
                 break
                 }
                 }
                 */
                default: break
                }
                if needsShift {
                    selectedLayout.shift = .Auto
                }
            }
        }
        // self.keyboard.view.nextKeyboardButton.setTitleColor(textColor, forState: .Normal)
    }

    @objc override func input(_ sender: GRInputButton) {
        // Crashlytics().crash()
        let proxy = textDocumentProxy
        log(text: "before: \(proxy.documentContextBeforeInput)")

        let selectedLayout = inputMethodView.selectedLayout
        for collection in inputMethodView.collections {
            for layout in collection.layouts {
                if selectedLayout.context != layout.context, layout.context != nil {
                    context_truncate(layout.context)
                }
            }
        }

        if sender.sequence != nil {
            (textDocumentProxy as UIKeyInput).insertText(sender.sequence)
            return
        }

        let context = selectedLayout.context
        let shiftButton = selectedLayout.view.shiftButton

        let keycode: UInt32
        if sender.keycodes.count > 1 && shiftButton?.isSelected ?? false {
            keycode = UInt32(sender.keycodes[1] as! UInt)
        } else {
            keycode = sender.keycode
        }

        if type(of: selectedLayout).autounshift && shiftButton?.isSelected ?? false {
            shiftButton?.isSelected = false
            selectedLayout.helper.updateCaptionLabel()
        }

        selectedLayout.view.doneButton.isEnabled = true

        // assert(selectedLayout.view.spaceButton != nil)
        // assert(selectedLayout.view.doneButton != nil)
        if sender == selectedLayout.view.spaceButton ?? nil || sender == selectedLayout.view.doneButton ?? nil {
            inputMethodView.selectedCollection.selectLayoutIndex(index: 0)
            inputMethodView.resetContext()
            // FIXME: dirty solution
            if sender == selectedLayout.view.spaceButton {
                proxy.insertText(" ")
            } else if sender == selectedLayout.view.doneButton {
                proxy.insertText("\n")
            }

            return
        }

        let precomposed = context_get_composed_unicodes(context: context!)
        let processed = context_put(context, UInt32(keycode))
        // self.log("processed: \(processed) / precomposed: \(precomposed)")

        if processed == 0 {
            inputMethodView.resetContext()

            if let code = UnicodeScalar(keycode) {
                proxy.insertText("\(code)")
            } else {
                print("Optional clear fail!")
            }
            // self.log("truncate and insert: \(UnicodeScalar(keycode))")

        } else {
            let commited = context_get_commited_unicodes(context: context!)
            let composed = context_get_composed_unicodes(context: context!)
            let combined = commited + composed
            // self.log("combined: \(combined)")
            var sharedLength = 0
            for (i, char) in precomposed.enumerated() {
                if char == combined[i] {
                    sharedLength = i + 1
                } else {
                    break
                }
            }

            let unsharedPrecomposed = Array(precomposed[sharedLength ..< precomposed.count])
            let unsharedCombined = Array(combined[sharedLength ..< combined.count])

            // self.log("-- deleting")
            for _ in unsharedPrecomposed {
                proxy.deleteBackward()
            }
            // self.log("-- deleted")

            // self.log("-- inserting")
            // self.log("shared length: \(sharedLength) unshared text: \(unsharedCombined)")
            if unsharedCombined.count > 0 {
                let string = unicodes_to_string(unicodes: unsharedCombined)
                proxy.insertText(string)
            }
            // self.log("-- inserted")
            log(text: "commited: \(commited) / composed: \(composed)")

            /*
             let NFDPrecomposed = unicodes_nfc_to_nfd(unsharedPrecomposed)
             let NFDCombined = unicodes_nfc_to_nfd(unsharedCombined)

             var NFDSharedLength = 0
             for (i, char) in enumerate(NFDPrecomposed) {
             if char == NFDCombined[i] {
             NFDSharedLength = i + 1
             } else {
             break
             }
             }

             let NFDUnsharedPrecomposed = Array(NFDPrecomposed[NFDSharedLength..<NFDPrecomposed.count])
             let NFDUnsharedCombined = Array(NFDCombined[NFDSharedLength..<NFDCombined.count])

             if NFDUnsharedPrecomposed.count == 0 {
             if NFDUnsharedCombined.count > 0 {
             let string = unicodes_to_string(NFDUnsharedCombined)
             proxy.insertText(string)
             }
             } else {
             //self.log("-- deleting")
             for _ in unsharedPrecomposed {
             proxy.deleteBackward()
             }
             self.needsProtection = !proxy.hasText()
             //self.log("-- deleted")

             //self.log("-- inserting")
             //self.log("shared length: \(sharedLength) unshared text: \(unsharedCombined)")
             if unsharedCombined.count > 0 {
             let string = unicodes_to_string(NFDCombined)
             proxy.insertText(string)
             }
             //self.log("-- inserted")
             self.log("commited: \(commited) / composed: \(composed)")
             }
             */
        }
        log(text: "input done")
        // self.log("after: \(proxy.documentContextAfterInput)")
    }

    @objc override func inputDelete(_ sender: GRInputButton) {
        let proxy = textDocumentProxy
        let context = inputMethodView.selectedLayout.context
        let precomposed = context_get_composed_unicodes(context: context!)
        if precomposed.count > 0 {
            let processed = context_put(context, InputSource(sender.keycode))
            let proxy = textDocumentProxy as UIKeyInput
            if processed > 0 {
                // self.log("start deleting")
                let commited = context_get_commited_unicodes(context: context!)
                let composed = context_get_composed_unicodes(context: context!)
                let combined = commited + composed
                // self.log("combined: \(combined)")
                var sharedLength = 0
                for (i, char) in combined.enumerated() {
                    if char == precomposed[i] {
                        sharedLength = i + 1
                    } else {
                        break
                    }
                }
                let unsharedPrecomposed = Array(precomposed[sharedLength ..< precomposed.count])
                let unsharedCombined = Array(combined[sharedLength ..< combined.count])

                for _ in unsharedPrecomposed {
                    proxy.deleteBackward()
                }

                if unsharedCombined.count > 0 {
                    let composed = unicodes_to_string(unicodes: unsharedCombined)
                    proxy.insertText("\(composed)")
                }
                // self.log("end deleting")
            } else {
                proxy.deleteBackward()
            }
            // self.log("deleted and add \(UnicodeScalar(composed))")
        } else {
            (textDocumentProxy as UIKeyInput).deleteBackward()
            // self.log("deleted")
        }
    }

    @objc func space(_ sender: GRInputButton) {
        let proxy = textDocumentProxy
        input(sender)
    }

    @objc func shift(_ sender: GRInputButton) {
        inputMethodView.selectedLayout.shift = sender.isSelected ? .Off : .On
    }

    @objc func toggleLayout(_: GRInputButton) {
        inputMethodView.selectedLayout.shift = .Off
        let collection = inputMethodView.selectedCollection
        collection.switchLayout()
        collection.selectedLayout.view.toggleKeyboardButton.isSelected = collection.selectedLayoutIndex != 0
        inputMethodView.selectedLayout.helper.updateCaptionLabel()
        adjustTraits(traits: lastTraits)
    }

    @objc func selectLayout(_ sender: GRInputButton) {
        let collection = inputMethodView.selectedCollection
        collection.selectLayoutIndex(index: sender.tag)
        inputMethodView.selectedLayout.helper.updateCaptionLabel()
        adjustTraits(traits: lastTraits)
    }

    @objc func done(_ sender: GRInputButton) {
        inputMethodView.resetContext()
        sender.keycode = 13
        input(sender)
    }

    @objc func mode(_: GRInputButton) {
        let now = NSDate()
        var needsNextInputMode = false
        if preferences.inglobe {
            if now.timeIntervalSince(modeDate as Date) < 0.5 {
                needsNextInputMode = true
            }
        } else {
            needsNextInputMode = true
        }
        if needsNextInputMode {
            advanceToNextInputMode()
        } else {
            let newIndex = inputMethodView.selectedCollectionIndex == 0 ? 1 : 0
            inputMethodView.selectCollectionByIndex(index: newIndex, animated: true)
            modeDate = now
            adjustTraits(traits: lastTraits)
        }
    }

    @objc func leftForSwipeRecognizer(_: UISwipeGestureRecognizer!) {
        let index = inputMethodView.selectedCollectionIndex
        if index < inputMethodView.collections.count - 1 {
            inputMethodView.selectCollectionByIndex(index: index + 1, animated: true)
            adjustTraits(traits: lastTraits)
        } else {
            inputMethodView.selectCollectionByIndex(index: 0, animated: true)
        }
    }

    @objc func rightForSwipeRecognizer(_: UISwipeGestureRecognizer!) {
        let index = inputMethodView.selectedCollectionIndex
        if index > 0 {
            inputMethodView.selectCollectionByIndex(index: index - 1, animated: true)
            adjustTraits(traits: lastTraits)
        } else {
            inputMethodView.selectCollectionByIndex(index: inputMethodView.collections.count - 1, animated: true)
        }
    }

//    func untouch(sender: UIButton) {
//        context_put(self.inputMethodView.selectedLayout.context, InputSource(0))
//    }

    @objc func error(_ sender: UIButton) {
        inputMethodView.resetContext()
        let proxy = textDocumentProxy
        #if DEBUG
            proxy.insertText("<error: \(sender.tag)>")
        #endif
    }
}
