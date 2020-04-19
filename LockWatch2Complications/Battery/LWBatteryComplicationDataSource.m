//
// LWBatteryComplicationDataSource.m
// LockWatch
//
// Created by janikschmidt on 3/30/2020
// Copyright © 2020 Team FESTIVAL. All rights reserved
//

#import <ClockKit/CLKComplicationTimelineEntry.h>
#import <NanoTimeKitCompanion/NTKBatteryTimelineEntryModel.h>

#import "LWBatteryComplicationDataSource.h"

@implementation LWBatteryComplicationDataSource

- (id)initWithComplication:(id)complication family:(long long)family forDevice:(CLKDevice*)device {
	if (self = [super initWithComplication:complication family:family forDevice:device]) {
		UIDevice* currentDevice = [UIDevice currentDevice];
		[currentDevice setBatteryMonitoringEnabled:YES];
		
		_level = [self _currentBatteryLevelRounded];
		_state = [currentDevice batteryState];
		
		[self _startObserving];
	}
	
	return self;
}

#pragma mark - Instance Methods

- (CGFloat)_currentBatteryLevelRounded {
	return ([[UIDevice currentDevice] batteryLevel] * 100) / 100;
}

- (CLKComplicationTimelineEntry*)_currentTimelineEntry {
	NTKBatteryTimelineEntryModel* entryModel = [NTKBatteryTimelineEntryModel new];
	[entryModel setEntryDate:NSDate.date];
	
	[entryModel setLevel:_level];
	[entryModel setState:_state];
	
	return [entryModel entryForComplicationFamily:self.family];
}

- (void)_handleLocaleChange {
	[self.delegate invalidateEntries];
}

- (void)_levelDidChange:(NSNotification*)notification {
	CGFloat level = [self _currentBatteryLevelRounded];
	
	if (_level != level) {
		_level = level;
		
		[self.delegate invalidateEntries];
	}
}

- (void)_startObserving {
	if (!_listeningForNotifications) {
		_listeningForNotifications = YES;
		
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_levelDidChange:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_stateDidChange:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_handleLocaleChange) name:NSCurrentLocaleDidChangeNotification object:nil];
		
		[self.delegate invalidateEntries];
	}
}

- (void)_stateDidChange:(NSNotification*)notification {
	UIDeviceBatteryState state = [UIDevice.currentDevice batteryState];
	
	if (_state != state) {
		_state = state;
		
		[self.delegate invalidateEntries];
	}
}

- (void)_stopObserving {
	_listeningForNotifications = NO;
	
	[NSNotificationCenter.defaultCenter removeObserver:self];
}


#pragma mark - NTKComplicationDataSource

- (CLKComplicationTemplate*)currentSwitcherTemplate {
	return [[self _currentTimelineEntry] complicationTemplate];
}

- (void)getCurrentTimelineEntryWithHandler:(void (^)(id entry))handler {
	handler([self _currentTimelineEntry]);
}

@end