//
//  DateUtils.h
//  perkli
//
//  Created by Mountain on 7/9/13.
//  Copyright (c) 2013 FodLife. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _weekDay {
    WD_SUNDAY,
    WD_MONDAY,
    WD_TUESDAY,
    WD_WEDNESDAY,
    WD_THURSDAY,
    WD_FRIDAY,
    WD_SATURDAY,
} WeekDay;


@interface DateUtility : NSObject


+(NSString *) stringFromString:(NSString *) orgString
                             fromFormat:(NSString *)fromFormat
                               toFormat:(NSString *)toFormat;

+(NSDate *) dateFromString:(NSString *)orgString fromFormat:(NSString *)fromFormat;

+(NSString *) stringFromTimeStamp:(NSString *)timeStamp toFormat:(NSString *)toFormat;

+(NSString *) stringFromDate:(NSDate *)date toFormat:(NSString *)toFormat;

+(NSInteger) calculateAgeForBirthDayFormatString:(NSString *)birthString format:(NSString *)format;

+(NSInteger) calculateAgeForBirthday:(NSDate *)date;

+ (NSDate *) dateByAddingCalendarUnits:(NSCalendarUnit)calendarUnit amount:(NSInteger)amount toDate:(NSDate *)toDate;
+(NSTimeInterval) timeDifference:(NSDate *)date1 date2:(NSDate *)date2 unit:(NSString *)unit;

+(NSTimeInterval) timeStampFromString:(NSString *)dateString fromFormat:(NSString *)fromFormat;

#pragma mark Date calculations

+ (NSDate *)dateWithYear:(int)year month:(int)month day:(int)day hour:(int)hour minute:(int)minute second:(int)second;
+ (NSDate *)createDate:(int)year month:(int)month day:(int)day hour:(int)hour minute:(int)minute second:(int)second;

+ (NSDate *)beginningOfDay:(NSDate *)date;
+ (NSDate *)beginningOfMonth:(NSDate *)date;
+ (NSDate *)beginningOfQuarter:(NSDate *)date;
+ (NSDate *)beginningOfWeek:(NSDate *)date;
+ (NSDate *)beginningOfYear:(NSDate *)date;

+ (NSDate *)dayOfWeek:(NSDate *)date weekDay:(WeekDay)weekDay;

+ (NSDate *)endOfDay:(NSDate *)date;
+ (NSDate *)endOfMonth:(NSDate *)date;
+ (NSDate *)endOfQuarter:(NSDate *)date;
+ (NSDate *)endOfWeek:(NSDate *)date;
+ (NSDate *)endOfYear:(NSDate *)date;

+ (NSDate *)advanceFromDate:(NSDate *)fromDate years:(int)years months:(int)months weeks:(int)weeks days:(int)days
                      hours:(int)hours minutes:(int)minutes seconds:(int)seconds;
+ (NSDate *)agoFromDate:(NSDate *)fromDate years:(int)years months:(int)months weeks:(int)weeks days:(int)days
                  hours:(int)hours minutes:(int)minutes seconds:(int)seconds;
+ (NSDate *)change:(NSDate *)date changes:(NSDictionary *)changes;
+ (NSUInteger)daysInMonth:(NSDate *)date;
+ (NSDate *)monthsSince:(NSDate *)date months:(int)months;
+ (NSDate *)yearsSince:(NSDate *)date years:(int)years;
+ (NSDate *)nextMonth:(NSDate *)date;
+ (NSDate *)nextWeek:(NSDate *)date;
+ (NSDate *)nextYear:(NSDate *)date;
+ (NSDate *)prevMonth:(NSDate *)date;
+ (NSDate *)prevYear:(NSDate *)date;
+ (NSDate *)yearsAgo:(NSDate *)date years:(int)years;
+ (NSDate *)yesterday:(NSDate *)date;
+ (NSDate *)tomorrow:(NSDate *)date;
+ (BOOL)isFuture:(NSDate *)date;
+(BOOL)isPast:(NSDate *)date;
+ (BOOL)isToday:(NSDate *)date;
+ (BOOL)isSameDate:(NSDate *)date1 withDate:(NSDate *)date2;

+ (NSInteger)weekDayOfDate:(NSDate *)date;

+ (NSDate *)nearestPastHourTimeFor:(NSDate *)time;
+ (NSDate *)nearestFutureHourTimeFor:(NSDate *)time;
+ (NSDate *)nearestPastTenMinuteTimeFor:(NSDate *)time;
+ (NSDate *)nearestFutureTenMinuteTimeFor:(NSDate *)time;
+ (NSDate *)nearestPastMinuteTimeFor:(NSDate *)time;
+ (NSDate *)nearestFutureMinuteTimeFor:(NSDate *)time;

@end
