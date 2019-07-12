//
//  Hack.m
//  OSX
//
//  Created by Jeong YunWon on 15/06/2019.
//  Copyright © 2019 youknowone.org. All rights reserved.
//

@import FoundationExtension;

#import "Hack.h"

@interface NSBundle ()

- (id)originalInfoDictionary;

@end

@implementation NSBundle (Hack)

- (id)patchedInfoDictionary {
    if (self != [NSBundle mainBundle]) {
        return [self originalInfoDictionary];
    }
    
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:[self originalInfoDictionary]];
    NSMutableDictionary* components = info[@"ComponentInputModeDict"] = [NSMutableDictionary dictionaryWithDictionary:info[@"ComponentInputModeDict"]];
    NSMutableDictionary* modes = components[@"tsInputModeListKey"] = [NSMutableDictionary dictionaryWithDictionary:components[@"tsInputModeListKey"]];
    for (id modeKey in modes.keyEnumerator) {
        NSMutableDictionary* mode = modes[modeKey] = [NSMutableDictionary dictionaryWithDictionary:modes[modeKey]];
        NSAssert([mode[@"tsInputModeMenuIconFileKey"] hasSuffix:@".png"], @"");
        mode[@"TISIntendedLanguage"] = @"ja";
        mode[@"tsInputModeMenuIconFileKey"] = @"eng.png";
        mode[@"tsInputModePaletteIconFileKey"] = @"eng.png";
        mode[@"tsInputModeAlternateMenuIconFileKey"] = @"eng.png";
    }

    return info;
}

+ (void)patchInfoDictionary {
    NSAMethod *interface = [NSBundle methodObjectForSelector:@selector(infoDictionary)];
    NSAMethod *patched = [NSBundle methodObjectForSelector:@selector(patchedInfoDictionary)];
    
    [NSBundle addMethodForSelector:@selector(originalInfoDictionary) fromMethod:interface];
    interface.implementation = patched.implementation;
}

@end
