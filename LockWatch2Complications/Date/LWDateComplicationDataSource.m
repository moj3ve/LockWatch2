//
// LWDateComplicationDataSource.m
// LockWatch
//
// Created by janikschmidt on 3/30/2020
// Copyright © 2020 Team FESTIVAL. All rights reserved
//

#import <objc/runtime.h>
#import <NanoTimeKitCompanion/NTKDateTimelineEntryModel.h>

#import "LWDateComplicationDataSource.h"

@implementation LWDateComplicationDataSource

+ (BOOL)acceptsComplicationFamily:(long long)family forDevice:(CLKDevice*)device {
	if (family == NTKComplicationFamilyDate) return NO;
	
	return [super acceptsComplicationFamily:family forDevice:device];
}

- (instancetype)initWithComplication:(NTKComplication*)complication family:(long long)family forDevice:(CLKDevice*)device {
	if (self = [super initWithComplication:complication family:family forDevice:device]) {
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_invalidate) name:UIApplicationSignificantTimeChangeNotification object:nil];
		// [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_invalidate) name:CalendarPreferencesNotification_OverlayCalendarID object:nil];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_invalidate) name:NSCurrentLocaleDidChangeNotification object:nil];
	}
	
	return self;
}

#pragma mark - Instance Methods

- (CLKComplicationTimelineEntry*)_currentTimelineEntry {
	NTKDateTimelineEntryModel* entryModel = [NTKDateTimelineEntryModel new];
	[entryModel setEntryDate:[NSCalendar.currentCalendar startOfDayForDate:NSDate.date]];
	
	NTKComplication* complication = (NTKComplication*)self.complication;
	if (complication.complicationType == NTKComplicationTypeLunarDate) {
		[entryModel setLunar:YES];
	}
	
	return [entryModel entryForComplicationFamily:self.family];
}

- (void)_invalidate {
	[self.delegate invalidateEntries];
}

#pragma mark - NTKComplicationDataSource

- (CLKComplicationTemplate*)currentSwitcherTemplate {
	return [[self _currentTimelineEntry] complicationTemplate];
}

- (void)getCurrentTimelineEntryWithHandler:(void (^)(CLKComplicationTimelineEntry* timelineEntry))handler {
	handler([self _currentTimelineEntry]);
}

- (Class)richComplicationDisplayViewClassForDevice:(CLKDevice*)device {
	switch (self.family) {
		case NTKComplicationFamilyGraphicCorner:
			return objc_getClass("NTKDateRichComplicationCornerView");
		case NTKComplicationFamilyGraphicBezel:
			return objc_getClass("NTKDateRichComplicationBezelCircularView");
		case NTKComplicationFamilyGraphicCircular:
			return objc_getClass("NTKDateRichComplicationCircularView");
		default: break;
	}
	
	return nil;
}

@end