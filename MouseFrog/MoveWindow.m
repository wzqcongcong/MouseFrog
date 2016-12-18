//
//  MoveWindow.m
//  MouseFrog
//
//  Created by 王振西 on 2016/12/18.
//  Copyright © 2016年 GoKuStudio. All rights reserved.
//

#import "MoveWindow.h"

@implementation MoveWindow
bool amIAuthorized ()
{
    if (AXAPIEnabled() != 0) {
        return true;
    }
    if (AXIsProcessTrusted() != 0) {
        return true;
    }
    return false;
}
AXUIElementRef getFrontMostApp ()
{
    pid_t pid;
    ProcessSerialNumber psn;
    
    GetFrontProcess(&psn);
    GetProcessPID(&psn, &pid);
    
    return AXUIElementCreateApplication(pid);
}
-(void) getCurrentFrontMost
{
    AXValueRef temp;
    if (!amIAuthorized()) {
//        printf("Can't use accessibility API!\n");
        return ;
    }
    
    frontMostApp = getFrontMostApp();
    
    AXUIElementCopyAttributeValue(
                                  frontMostApp, kAXFocusedWindowAttribute, (CFTypeRef *)&frontMostWindow
                                  );
    
    AXUIElementCopyAttributeValue(
                                  frontMostWindow, kAXTitleAttribute, (CFTypeRef *)&windowTitle
                                  );
    
    AXUIElementCopyAttributeValue(
                                  frontMostWindow, kAXSizeAttribute, (CFTypeRef *)&temp
                                  );
    AXValueGetValue(temp, kAXValueCGSizeType, &windowSize);
    CFRelease(temp);
    
    AXUIElementCopyAttributeValue(
                                  frontMostWindow, kAXPositionAttribute, (CFTypeRef *)&temp
                                  );
    AXValueGetValue(temp, kAXValueCGPointType, &windowPosition);
    
//    NSLog(@"windowPostion: %f  %f",windowPosition.x,windowPosition.y);
    CFRelease(temp);
    
}
- (void) setWindowByPath:(CGPoint) path
{
    AXValueRef temp;
    windowPosition.x += path.x;
    windowPosition.y += path.y;
    temp = AXValueCreate(kAXValueCGPointType, &windowPosition);
    AXUIElementSetAttributeValue(frontMostWindow, kAXPositionAttribute, temp);
    CFRelease(temp);
    
    CFRelease(frontMostWindow);
    CFRelease(frontMostApp);
    
}
- (int) getPointLocateScreen:(CGPoint )point
{
    CGDisplayCount    displayCount, i;
    CGDisplayCount    maxDisplays = MaxDisplayScreens;
    CGDirectDisplayID onlineDisplays[MaxDisplayScreens];
    
    CGGetOnlineDisplayList( maxDisplays, onlineDisplays, &displayCount );
    
    for ( i=0; i<displayCount; i++ ) {
        CGDirectDisplayID dID = onlineDisplays[i];
        if(point.x>= CGRectGetMinX (CGDisplayBounds (dID))&&point.x<=CGRectGetMaxX (CGDisplayBounds (dID)))
        {
            if (point.y>= CGRectGetMinY (CGDisplayBounds (dID))&&point.y<=CGRectGetMaxY (CGDisplayBounds (dID)))
            {
                for (int i = 0; i<MaxDisplayScreens; i++) {
                    if (dID == sortByDID[i]) {
//                        NSLog(@"LocateScreenNumber:%d",i+1);
                        return i+1;
                    }
                }
            }
        }
    }
    
    return 0;
}
- (void) sortScreenByunID
{
    CGDisplayCount    displayCount, i,j;
    CGDisplayCount    maxDisplays = MaxDisplayScreens;
    CGDirectDisplayID onlineDisplays[MaxDisplayScreens];
    
    CGGetOnlineDisplayList( maxDisplays, onlineDisplays, &displayCount );
    for (i = 0; i<MaxDisplayScreens; i++) {
        CGDirectDisplayID dID_i = onlineDisplays[i];
        for (j = i+1; j<MaxDisplayScreens; j++) {
            CGDirectDisplayID dID_j = onlineDisplays[j];
            if ( (CGRectGetMinX (CGDisplayBounds (dID_j))+CGRectGetMinY (CGDisplayBounds (dID_j))) <  (CGRectGetMinX (CGDisplayBounds (dID_i))+CGRectGetMinY (CGDisplayBounds (dID_i)))           ) {
                onlineDisplays[j] = dID_i;
                onlineDisplays[i] = dID_j;
            }
        }
    }
    for (i = 0; i<MaxDisplayScreens; i++) {
        sortByunID[i] = CGDisplayUnitNumber(onlineDisplays[i]);
//        NSLog(@"sortByunID[%d]:%d",i,sortByunID[i]);
        sortByDID[i]   = onlineDisplays[i];
//        NSLog(@"sortByDID[%d]:%d",i,sortByDID[i]);
    }
}
- (void) goToScreen:(int)screenNumber
{
    [self getCurrentFrontMost];
    if (!(windowSize.width&&windowSize.height)) {
//        NSLog(@"Counldn't found front most app");
        return;
    }
    CGPoint windowCentral;
    windowCentral.x = windowPosition.x+ windowSize.width/2;
    windowCentral.y = windowPosition.y+windowSize.height/2;
    int currentWindowunID = [self getPointLocateScreen:windowCentral];
    CGDirectDisplayID currentWindowdID = sortByDID[currentWindowunID-1];
    CGDirectDisplayID targetWindowdID = sortByDID[screenNumber-1];
    CGPoint path;
    path = CGPointMake(CGRectGetMinX (CGDisplayBounds (targetWindowdID))-CGRectGetMinX (CGDisplayBounds (currentWindowdID)), CGRectGetMinY (CGDisplayBounds (targetWindowdID))-CGRectGetMinY (CGDisplayBounds (currentWindowdID)));
//    NSLog(@"path: %f %f",path.x,path.y);
    [self setWindowByPath:path];
    
}

@end

