//
//  DateUtils.m
//
//  Created by Ichiro Iwai on 7/9/13.
//  Copyright (c) 2013 II. All rights reserved.
//

#import "DateUtility.h"

@implementation DateUtility

+(NSString *) stringFromString:(NSString *) orgString
                             fromFormat:(NSString *)fromFormat
                               toFormat:(NSString *)toFormat {
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:fromFormat];
    
    NSDate *dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:orgString];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:toFormat];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
    NSString *stringFromDate = [formatter stringFromDate:dateFromString];
    
    return  stringFromDate;
}

+(NSDate *) dateFromString:(NSString *)orgString fromFormat:(NSString *)fromFormat {
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:fromFormat];
    
    NSDate *dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:orgString];

    return dateFromString;
}

+(NSString *) stringFromTimeStamp:(NSString *)timeStamp toFormat:(NSString *)toFormat {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timeStamp intValue]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:toFormat];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}

+(NSString *) stringFromDate:(NSDate *)date toFormat:(NSString *)toFormat {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:toFormat];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}

+(NSTimeInterval) timeStampFromString:(NSString *)dateString fromFormat:(NSString *)fromFormat {
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:fromFormat];
    
    NSDate *dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:dateString];

    return [dateFromString timeIntervalSince1970];
}

+(NSInteger) calculateAgeForBirthDayFormatString:(NSString *)birthString format:(NSString *)format {
    NSDate *birth = [DateUtility dateFromString:birthString fromFormat:format];
    NSDate* now = [NSDate date];
    NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                       components:NSCalendarUnitYear
                                       fromDate:birth
                                       toDate:now
                                       options:0];
    NSInteger age = [ageComponents year];
    
    return age;
}

+(NSInteger) calculateAgeForBirthday:(NSDate *)date {
    NSDate* now = [NSDate date];
    NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                       components:NSCalendarUnitYear
                                       fromDate:date
                                       toDate:now
                                       options:0];
    NSInteger age = [ageComponents year];
    
    return age;
}

+ (NSDate *) dateByAddingCalendarUnits:(NSCalendarUnit)calendarUnit amount:(NSInteger)amount toDate:(NSDate *)toDate {
    
	NSDateComponents *components = [[NSDateComponents alloc] init];
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	NSDate *newDate;
	
	switch (calendarUnit) {
		case NSCalendarUnitSecond:
			[components setSecond:amount];
			break;
		case NSCalendarUnitMinute:
			[components setMinute:amount];
			break;
		case NSCalendarUnitHour:
			[components setHour:amount];
			break;
		case NSCalendarUnitDay:
			[components setDay:amount];
			break;
		case NSCalendarUnitWeekOfYear:
			[components setWeekOfYear:amount];
			break;
		case NSCalendarUnitMonth:
			[components setMonth:amount];
			break;
		case NSCalendarUnitYear:
			[components setYear:amount];
			break;
		default:
			NSLog(@"addCalendar does not support that calendarUnit!");
			break;
	}
	
	newDate = [gregorian dateByAddingComponents:components toDate:toDate options:0];
	return newDate;
    
}

+(NSTimeInterval) timeDifference:(NSDate *)date1 date2:(NSDate *)date2 unit:(NSString *)unit {
    NSTimeInterval time1 = [date1 timeIntervalSince1970];
    NSTimeInterval time2 = [date2 timeIntervalSince1970];
    
    if ([unit isEqualToString:@"ms"])
        return fabs(time2 - time1) * 1000;
    else if ([unit isEqualToString:@"s"]) {
        return fabs(time2 - time1);
    } else if ([unit isEqualToString:@"d"]) {
        return fabs(time2 - time1) / 3600.0f / 24.0f;
    } else {
        return fabs(time2 - time1);
    }
}

+ (NSDate *)dateWithYear:(int)year month:(int)month day:(int)day hour:(int)hour minute:(int)minute second:(int)second
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:year];
    [comps setMonth:month];
    [comps setDay:day];
    [comps setHour:hour];
    [comps setMinute:minute];
    [comps setSecond:second];
    
    return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

+ (NSDate *)createDate:(int)year month:(int)month day:(int)day hour:(int)hour minute:(int)minute second:(int)second
{
    NSLog(@"createDate:month:day:hour:minute:second has been deprecated. Use dateWithYear:month:day:hour:minute:second");
    return [self dateWithYear:year month:month day:day hour:hour minute:minute second:second];
}


#pragma mark -
#pragma mark Beginning of

+ (NSDate *)beginningOfDay:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    
    return [currentCalendar dateFromComponents:comps];
}

+ (NSDate *)beginningOfMonth:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setDay:1];
    [comps setHour:0];
    [comps setMinute:00];
    [comps setSecond:00];
    
    return [currentCalendar dateFromComponents:comps];
}

// 1st of january, april, july, october
+ (NSDate *)beginningOfQuarter:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    NSInteger month = [comps month];
    
    if (month < 4)
        [comps setMonth:1];
    else if (month < 7)
        [comps setMonth:4];
    else if (month < 10)
        [comps setMonth:7];
    else
        [comps setMonth:10];
    
    [comps setDay:1];
    [comps setHour:0];
    [comps setMinute:00];
    [comps setSecond:00];
    
    return [currentCalendar dateFromComponents:comps];
}

// Week starts on sunday for the gregorian calendar
+ (NSDate *)beginningOfWeek:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setWeekday:1];
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    
    return [currentCalendar dateFromComponents:comps];
}

+ (NSDate *)beginningOfYear:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setMonth:1];
    [comps setDay:1];
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    
    return [currentCalendar dateFromComponents:comps];
}

+ (NSDate *)dayOfWeek:(NSDate *)date weekDay:(WeekDay)weekDay {
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setWeekday:weekDay];
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    
    return [currentCalendar dateFromComponents:comps];
}

#pragma mark -
#pragma mark End of

+ (NSDate *)endOfDay:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    
    return [currentCalendar dateFromComponents:comps];
}

+ (NSDate *)endOfMonth:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setDay:[DateUtility daysInMonth:date]];
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    
    return [currentCalendar dateFromComponents:comps];
}

// 1st of january, april, july, october
+ (NSDate *)endOfQuarter:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    NSInteger month = [comps month];
    
    if (month < 4)
    {
        [comps setMonth:3];
        [comps setDay:31];
    }
    else if (month < 7)
    {
        [comps setMonth:6];
        [comps setDay:30];
    }
    else if (month < 10)
    {
        [comps setMonth:9];
        [comps setDay:30];
    }
    else
    {
        [comps setMonth:12];
        [comps setDay:31];
    }
    
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    
    return [currentCalendar dateFromComponents:comps];
}

+ (NSDate *)endOfWeek:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setWeekday:7];
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    
    return [currentCalendar dateFromComponents:comps];
}

+ (NSDate *)endOfYear:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    int calendarComponents = (NSCalendarUnitYear);
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    [comps setMonth:12];
    [comps setDay:31];
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    
    return [currentCalendar dateFromComponents:comps];
}

#pragma mark -
#pragma mark Other Calculations

+ (NSDate *)advanceFromDate:(NSDate *)fromDate years:(int)years months:(int)months weeks:(int)weeks days:(int)days
                      hours:(int)hours minutes:(int)minutes seconds:(int)seconds
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:years];
    [comps setMonth:months];
    [comps setWeekOfYear:weeks];
    [comps setDay:days];
    [comps setHour:hours];
    [comps setMinute:minutes];
    [comps setSecond:seconds];
    
    return [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:fromDate options:0];
}

+ (NSDate *)agoFromDate:(NSDate *)fromDate years:(int)years months:(int)months weeks:(int)weeks days:(int)days
                  hours:(int)hours minutes:(int)minutes seconds:(int)seconds
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:-years];
    [comps setMonth:-months];
    [comps setWeekOfYear:-weeks];
    [comps setDay:-days];
    [comps setHour:-hours];
    [comps setMinute:-minutes];
    [comps setSecond:-seconds];
    
    return [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:fromDate options:0];
}

+ (NSDate *)change:(NSDate *)date changes:(NSDictionary *)changes
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    
    int calendarComponents = (NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                              NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond |
                              NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday |  NSCalendarUnitWeekdayOrdinal |
                              NSCalendarUnitQuarter);
    
    NSDateComponents *comps = [currentCalendar components:calendarComponents fromDate:date];
    
    for (id key in changes) {
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"set%@:", [key capitalizedString]]);
        int value = [[changes valueForKey:key] intValue];
        
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[comps methodSignatureForSelector:selector]];
        [inv setSelector:selector];
        [inv setTarget:comps];
        [inv setArgument:&value atIndex:2]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv invoke];
    }
    
    return [currentCalendar dateFromComponents:comps];
}

+ (NSUInteger)daysInMonth:(NSDate *)date
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSRange days = [currentCalendar rangeOfUnit:NSCalendarUnitDay
                                         inUnit:NSCalendarUnitMonth
                                        forDate:date];
    return days.length;
}

+ (NSDate *)monthsSince:(NSDate *)date months:(int)months
{
    return [DateUtility advanceFromDate:date years:0 months:months weeks:0 days:0 hours:0 minutes:0 seconds:0];
}

+ (NSDate *)yearsSince:(NSDate *)date years:(int)years
{
    return [self advanceFromDate:date  years:years months:0 weeks:0 days:0 hours:0 minutes:0 seconds:0];
}

+ (NSDate *)nextMonth:(NSDate *)date
{
    return [self monthsSince:date months:1];
}

+ (NSDate *)nextWeek:(NSDate *)date
{
    return [self advanceFromDate:date years:0 months:0 weeks:1 days:0 hours:0 minutes:0 seconds:0];
}

+ (NSDate *)nextYear:(NSDate *)date
{
    return [self advanceFromDate:date years:1 months:0 weeks:0 days:0 hours:0 minutes:0 seconds:0];
}

+ (NSDate *)prevMonth:(NSDate *)date
{
    return [self monthsSince:date months:-1];
}

+ (NSDate *)prevYear:(NSDate *)date
{
    return [self yearsAgo:date years:1];
}

+ (NSDate *)yearsAgo:(NSDate *)date years:(int)years
{
    return [self advanceFromDate:date years:-years months:0 weeks:0 days:0 hours:0 minutes:0 seconds:0];
}

+ (NSDate *)yesterday:(NSDate *)date
{
    return [self advanceFromDate:date years:0 months:0 weeks:0 days:-1 hours:0 minutes:0 seconds:0];
}

+ (NSDate *)tomorrow:(NSDate *)date
{
    return [self advanceFromDate:date years:0 months:0 weeks:0 days:1 hours:0 minutes:0 seconds:0];
}

+ (BOOL)isFuture:(NSDate *)date
{
    return date == [date laterDate:[NSDate date]];
}

+(BOOL)isPast:(NSDate *)date
{
    return date == [date earlierDate:[NSDate date]];
}

+ (BOOL)isToday:(NSDate *)date
{
    return date == [date laterDate:[self beginningOfDay:[NSDate date]]] &&
    date == [date earlierDate:[self endOfDay:[NSDate date]]];
}

+ (BOOL)isSameDate:(NSDate *)date1 withDate:(NSDate *)date2 {
    return date1 == [date1 laterDate:[self beginningOfDay:date2]] &&
    date1 == [date1 earlierDate:[self endOfDay:date2]];
}

+ (NSInteger)weekDayOfDate:(NSDate *)date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [gregorian components:NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSInteger weekday = [comps weekday];
    return weekday;
}

+ (NSDate *)nearestPastMinuteTimeFor:(NSDate *)time {
    NSString *timeString = [DateUtility stringFromDate:time
                                              toFormat:@"yyyy-MM-dd HH:mm"];
    timeString = [timeString stringByAppendingString:@":00"];
    return [DateUtility dateFromString:timeString
                            fromFormat:@"yyyy-MM-dd HH:mm:ss"];
}

+ (NSDate *)nearestFutureMinuteTimeFor:(NSDate *)time {
    NSString *timeString = [DateUtility stringFromDate:time
                                              toFormat:@"yyyy-MM-dd HH"];

    int min = [[DateUtility stringFromDate:time toFormat:@"m"] intValue];
    int sec = [[DateUtility stringFromDate:time toFormat:@"s"] intValue];
    
    if (sec > 0) {
        
        return [DateUtility advanceFromDate:[DateUtility nearestPastHourTimeFor:time] years:0 months:0 weeks:0 days:0 hours:0 minutes:1 seconds:0];
        
    } else {
        
        timeString = [timeString stringByAppendingFormat:@":%02d", min];
        timeString = [timeString stringByAppendingString:@":00"];
        
        return [DateUtility dateFromString:timeString
                                fromFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
}

+ (NSDate *)nearestPastTenMinuteTimeFor:(NSDate *)time {
    NSString *timeString = [DateUtility stringFromDate:time
                                              toFormat:@"yyyy-MM-dd HH"];
    int min = [[DateUtility stringFromDate:time toFormat:@"m"] intValue];
    int nearstMinForTenMinute = ((int)(min / 10)) * 10;
    timeString = [timeString stringByAppendingFormat:@":%02d:00", nearstMinForTenMinute];
    
    return [DateUtility dateFromString:timeString
                            fromFormat:@"yyyy-MM-dd HH:mm:ss"];
}

+ (NSDate *)nearestFutureTenMinuteTimeFor:(NSDate *)time {
    
    int min = [[DateUtility stringFromDate:time toFormat:@"m"] intValue];
    int sec = [[DateUtility stringFromDate:time toFormat:@"s"] intValue];
    
    if (min % 10 > 0 || sec > 0) {
        
        return [DateUtility advanceFromDate:[DateUtility nearestPastTenMinuteTimeFor:time] years:0 months:0 weeks:0 days:0 hours:0 minutes:10 seconds:0];
        
    } else {
        
        return time;
    }
    
}

+ (NSDate *)nearestPastHourTimeFor:(NSDate *)time {
    NSString *timeString = [DateUtility stringFromDate:time
                                              toFormat:@"yyyy-MM-dd HH"];
    timeString = [timeString stringByAppendingString:@":00:00"];
    return [DateUtility dateFromString:timeString
                            fromFormat:@"yyyy-MM-dd HH:mm:ss"];
}

+ (NSDate *)nearestFutureHourTimeFor:(NSDate *)time {
    
    int min = [[DateUtility stringFromDate:time toFormat:@"m"] intValue];
    int sec = [[DateUtility stringFromDate:time toFormat:@"s"] intValue];
    
    if (min + sec > 0) {
        
        return [DateUtility advanceFromDate:[DateUtility nearestPastHourTimeFor:time] years:0 months:0 weeks:0 days:0 hours:1 minutes:0 seconds:0];
                
    } else {
        
        return time;
    }

}

@end
