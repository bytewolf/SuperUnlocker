//
//  MacGuarderHelper.m
//  MacGuarder
//
//  Created by user on 14-7-23.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import "MacGuarderHelper.h"
#import "ListenerManager.h"
#import "GuarderUserDefaults.h"

NSString *password = @"piupiu";

@implementation MacGuarderHelper

- (instancetype)initWithSettings:(GuarderUserDefaults *)aSettings
{
    if (self = [super init])
    {
        _userSettings = aSettings;
    }

    return self;
}

- (BOOL)isScreenLocked
{
    BOOL locked = NO;
    
    CFDictionaryRef CGSessionCurrentDictionary = CGSessionCopyCurrentDictionary();
    id o = ((__bridge NSDictionary *) CGSessionCurrentDictionary)[@"CGSSessionScreenIsLocked"];
    if (o) {
        locked = [o boolValue];
    }
    CFRelease(CGSessionCurrentDictionary);
    
    return locked;
}

- (void)lock
{
    if ([self isScreenLocked]) return;

    NSLog(@"lock");
    
    io_registry_entry_t r =	IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if(!r) return;
    IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);
    IOObjectRelease(r);
}

- (void)unlock
{
    NSLog(@"unlock");
    if (![self isScreenLocked]) return;
    
// wakeup display from idle status to show login window
    io_registry_entry_t r = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if (r) {
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanFalse);
        IOObjectRelease(r);
    }

// use Apple Script to input password and unlock Mac
    NSString *command = @"tell application \"System Events\" to keystroke \"%@\" \n tell application \"System Events\" to keystroke return";

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:command, password, nil]];
    [script executeAndReturnError:nil];

    [_lockDelegate unLockSuccess];
}

- (void)setPassword:(NSString*)p
{
    password = [p copy];
}
@end
