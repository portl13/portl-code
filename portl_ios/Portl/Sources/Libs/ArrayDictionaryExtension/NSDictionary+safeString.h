//
//  UIImage+fixOrientation.h
//  Numbers
//
//  Created by Optiplex790 on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSDictionary (safeString)

-(NSString *)       safeStringForKey:(NSString *)key;
-(int)              safeIntegerValueForKey:(NSString *) key;
-(double)           safeDoubleValueForKey:(NSString *) key;
-(float)            safeFloatValueForKey:(NSString *) key;
-(BOOL)             safeBooleanValueForKey:(NSString *)key;
-(NSMutableDictionary *)    safeDictionaryForKey:(NSString *) key;
-(NSMutableArray *)         safeArrayForKey:(NSString *) key;
@end
