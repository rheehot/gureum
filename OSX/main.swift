//
//  main.swift
//  Gureum
//
//  Created by Jeong YunWon on 2018. 9. 26..
//  Copyright © 2018 youknowone.org. All rights reserved.
//

import Cocoa

// _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

let mainNibName = Bundle.main.infoDictionary!["NSMainNibFile"] as! String
let nib = NSNib(nibNamed: NSNib.Name(mainNibName), bundle: Bundle.main)!
if nib.instantiate(withOwner: NSApplication.shared, topLevelObjects: nil) == false {
    dlog(true, "!! Gureum fails to load Main Nib File !!")
}

dlog(true, "****   Main bundle \(mainNibName) loaded   ****")
var bundle = Bundle.main
//bundle.infoDictionary!.removeValue(forKey: "ComponentInputModeDict")
Bundle.patchInfoDictionary()
print(bundle.infoDictionary!)
print(bundle.infoDictionary!["ComponentInputModeDict"])
NSApplication.shared.run()
dlog(true, "******* Gureum finalized! *******")
