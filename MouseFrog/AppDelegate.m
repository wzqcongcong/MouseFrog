//
//  AppDelegate.m
//  MouseFrog
//
//  Created by GoKu on 25/11/2016.
//  Copyright © 2016 GoKuStudio. All rights reserved.
//

#import "AppDelegate.h"
#import "MoveWindow.h"

#define kValidMouseMoveDelta    100

@interface AppDelegate ()

@property (nonatomic, assign) BOOL isMonitoring;
@property (nonatomic, assign) NSPoint lastLocation;
@property(nonatomic,assign)BOOL isMovingWindow;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [self setLaunchAtLogin];

    self.isMonitoring = NO;
    self.lastLocation = [NSEvent mouseLocation];
    self.isMovingWindow = NO;
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^(NSEvent * _Nonnull event) {
        self.isMonitoring = (event.modifierFlags & NSFunctionKeyMask) ? YES : NO;
        self.isMovingWindow = (event.modifierFlags & NSCommandKeyMask) ? YES : NO;
    }];
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent * _Nonnull event) {
        if (([NSScreen screens].count > 1) && self.isMonitoring) {
            CGPoint toPoint = [self getToPoint];
            if (!CGPointEqualToPoint(toPoint, CGPointZero)) {
                [self moveMouseToPoint:toPoint];
            }
        }
        self.lastLocation = [NSEvent mouseLocation];
    }];
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent * _Nonnull event) {
        if (event.keyCode<=20) {
            if (event.keyCode>=18) {
                [self setCurrentWindow2Screen:event.keyCode-17];
            }
        }
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (CGPoint)getToPoint
{
    CGPoint toPoint = CGPointZero;

    NSArray *screens = [NSScreen screens];
    if (screens.count <= 1) {
        return toPoint;
    }
    
    uint32_t maxDisplays = (uint32_t)screens.count;
    CGDirectDisplayID activeDisplays[maxDisplays];
    uint32 displayCount;
    CGGetActiveDisplayList(maxDisplays, activeDisplays, &displayCount);
    if (displayCount != screens.count) {
        return toPoint;
    }
    
    NSPoint fromPoint = [NSEvent mouseLocation];
    CGFloat mouseDeltaX = fromPoint.x - self.lastLocation.x;
    CGFloat mouseDeltaY = fromPoint.y - self.lastLocation.y;
    if (![self isValidMouseMoveMouseDeltaX:mouseDeltaX mouseDeltaY:mouseDeltaY]) {
        return toPoint;
    }

    NSUInteger fromScreenIndex = [self locatePoint:fromPoint inScreens:screens];
    if (fromScreenIndex == NSNotFound) {
        return toPoint;
    }
    NSPoint fromScreenCenter = [self centerOfScreen:screens[fromScreenIndex]];
    
    for (NSUInteger i = 0; i < screens.count; ++i) {
        if (i == fromScreenIndex) {
            continue;
        }
        
        NSPoint screenCenter = [self centerOfScreen:screens[i]];
        CGFloat screenDeltaX = screenCenter.x - fromScreenCenter.x;
        CGFloat screenDeltaY = screenCenter.y - fromScreenCenter.y;

        BOOL similar = [self isSimilarDirectionForMouseDeltaX:mouseDeltaX
                                                  mouseDeltaY:mouseDeltaY
                                                 screenDeltaX:screenDeltaX
                                                 screenDeltaY:screenDeltaY];
        if (similar) {
            CGRect cgRect = CGDisplayBounds(activeDisplays[i]);
            toPoint = CGPointMake(cgRect.origin.x + cgRect.size.width / 2, cgRect.origin.y + cgRect.size.height / 2);
            break;
        }
    }
    
    return toPoint;
}

- (NSUInteger)locatePoint:(NSPoint)point inScreens:(NSArray *)screens
{
    NSUInteger which = NSNotFound;
    
    for (NSUInteger i = 0; i < screens.count; ++i) {
        NSScreen *screen = screens[i];
        if (NSPointInRect(point, screen.frame)) {
            which = i;
            break;
        }
    }
    
    return which;
}

- (NSPoint)centerOfScreen:(NSScreen *)screen
{
    return NSMakePoint(screen.frame.origin.x + screen.frame.size.width / 2,
                       screen.frame.origin.y + screen.frame.size.height / 2);
}

- (BOOL)isValidMouseMoveMouseDeltaX:(CGFloat)mouseDeltaX
                        mouseDeltaY:(CGFloat)mouseDeltaY
{
    if ((mouseDeltaX == 0) && (mouseDeltaY == 0)) {
        return NO;
    }
    
    if ((mouseDeltaX > kValidMouseMoveDelta) || (mouseDeltaY > kValidMouseMoveDelta)) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isSimilarDirectionForMouseDeltaX:(CGFloat)mouseDeltaX
                             mouseDeltaY:(CGFloat)mouseDeltaY
                            screenDeltaX:(CGFloat)screenDeltaX
                            screenDeltaY:(CGFloat)screenDeltaY
{
    if (![self isValidMouseMoveMouseDeltaX:mouseDeltaX mouseDeltaY:mouseDeltaY]) {
        return NO;

    } else if ((mouseDeltaX * screenDeltaX == 0) && (mouseDeltaY * screenDeltaY == 0)) {
        return NO;
        
    } else {
        return ((mouseDeltaX * screenDeltaX >= 0) && (mouseDeltaY * screenDeltaY >= 0));
    }
}

- (void)moveMouseToPoint:(CGPoint)point
{
    CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft);
    if (mouseEvent) {
        CGEventPost(kCGSessionEventTap, mouseEvent);
        CFRelease(mouseEvent);
    }
}

- (void)setLaunchAtLogin
{
    NSURL *itemURL = [[NSBundle mainBundle] bundleURL];

    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);

    LSSharedFileListItemRef foundItem = NULL;

    CFArrayRef listSnapshot = LSSharedFileListCopySnapshot(loginItems, NULL);
    for (id item in (__bridge NSArray *)listSnapshot) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
        UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
        CFURLRef currentItemURL = LSSharedFileListItemCopyResolvedURL(itemRef, resolutionFlags, NULL);

        if (currentItemURL && [(__bridge NSURL *)currentItemURL isEqual:itemURL]) {
            foundItem = itemRef;
        }

        if (currentItemURL) {
            CFRelease(currentItemURL);
        }

        if (foundItem) {
            break;
        }
    }
    CFRelease(listSnapshot);

    if (!foundItem) {
        LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, NULL, NULL, (__bridge CFURLRef)itemURL, NULL, NULL);
    }

    CFRelease(loginItems);
}
- (void)setCurrentWindow2Screen:(int)screenNumber
{
    if (screenNumber<= [[NSScreen screens]count]&&self.isMovingWindow) {
        MoveWindow* move = [[MoveWindow alloc]init];
        [move sortScreenByunID];
        [move goToScreen:screenNumber];
    }
}
@end
