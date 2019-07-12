//
//  Hack.h
//  OSX
//
//  Created by Jeong YunWon on 15/06/2019.
//  Copyright © 2019 youknowone.org. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Hack)

+ (void)patchInfoDictionary;

@end

NS_ASSUME_NONNULL_END
