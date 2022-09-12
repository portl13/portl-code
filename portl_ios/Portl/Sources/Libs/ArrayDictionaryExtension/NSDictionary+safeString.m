//
//  UIImage+fixOrientation.m
//  Numbers
//
//  Created by Optiplex790 on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+safeString.h"

@implementation NSDictionary (safeString)

-(NSString *) safeStringForKey:(NSString *)key {
    if ([self objectForKey:key] == [NSNull null])
        return @"";
    else if ([self objectForKey:key] == nil)
        return @"";
    else if ([[self objectForKey:key] isKindOfClass:[NSNumber class]]) {
        return [[self objectForKey:key] stringValue];
    }
    else
        return [self objectForKey:key];
}

-(int)          safeIntegerValueForKey:(NSString *) key {
    if ([self objectForKey:key] == [NSNull null]) {
        return 0;
    } else if ([self objectForKey:key] == nil) {
        return 0;
    } else {
        return [[self objectForKey:key] intValue];
    }
}

-(double)          safeDoubleValueForKey:(NSString *) key {
    
    if (self == nil) return 0;
    
    if ([self objectForKey:key] == [NSNull null]) {
        return 0;
    } else if ([self objectForKey:key] == nil) {
        return 0;
    } else {
        return [[self objectForKey:key] doubleValue];
    }
}

-(float)safeFloatValueForKey:(NSString *) key {
    if (self == nil) return 0;
    
    if ([self objectForKey:key] == [NSNull null]) {
        return 0;
    } else if ([self objectForKey:key] == nil) {
        return 0;
    } else {
        return [[self objectForKey:key] floatValue];
    }
}


-(BOOL) safeBooleanValueForKey:(NSString *)key {
    if ([self objectForKey:key] == [NSNull null]) {
        return NO;
    } else if ([self objectForKey:key] == nil) {
        return NO;
    } else {
        return [[self objectForKey:key] boolValue];
    }
}

-(NSDictionary *)safeDictionaryForKey:(NSString *) key {
    
    if (self == nil) return nil;
    
    if ([self objectForKey:key] == [NSNull null]) {
        return nil;
    } else if ([self objectForKey:key] == nil) {
        return nil;
    } else {
        return [NSMutableDictionary dictionaryWithDictionary:[self objectForKey:key]];
    }
}

-(NSArray *)safeArrayForKey:(NSString *) key {
    if ([self objectForKey:key] == [NSNull null]) {
        return nil;
    } else if ([self objectForKey:key] == nil) {
        return nil;
    } else {
        return [self objectForKey:key];
    }
}


@end
