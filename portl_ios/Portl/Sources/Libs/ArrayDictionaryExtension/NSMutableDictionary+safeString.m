//
//  UIImage+fixOrientation.m
//  Numbers
//
//  Created by Optiplex790 on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSMutableDictionary+safeString.h"
#import <QuartzCore/QuartzCore.h>


@implementation NSMutableDictionary (safeString)

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

-(double)safeDoubleValueForKey:(NSString *) key {
    
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

-(NSMutableDictionary *)safeDictionaryForKey:(NSString *) key {
    
    if (self == nil) return nil;
    
    if ([self objectForKey:key] == [NSNull null]) {
        return nil;
    } else if ([self objectForKey:key] == nil) {
        return nil;
    } else {
        return [NSMutableDictionary dictionaryWithDictionary:[self objectForKey:key]];
    }
}

-(NSMutableArray *)safeArrayForKey:(NSString *) key {
    if ([self objectForKey:key] == [NSNull null]) {
        return nil;
    } else if ([self objectForKey:key] == nil) {
        return nil;
    } else {
        return [self objectForKey:key];
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

-(void) putBooleanValueForKey:(NSString *)key value:(BOOL)value {
    [self setObject:[NSNumber numberWithBool:value] forKey:key];
}

-(void) putIntegerValueForKey:(NSString *)key value:(int)value {
    [self setObject:[NSNumber numberWithInt:value] forKey:key];
}

-(void) putDoubleValueForKey:(NSString *)key value:(double)value {
    [self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

-(NSMutableArray *) convertToArrayForIdDict {
    
    if (self == nil) return nil;
    
    NSMutableArray *resultArray = [NSMutableArray new];
    NSArray*keys=[self allKeys];
    
    for (NSString *key in keys) {
        NSMutableDictionary *dict = [self safeDictionaryForKey:key];
        [dict setObject:key forKey:@"id"];
        [resultArray addObject:dict];
    }
    
    return resultArray;

}

@end
