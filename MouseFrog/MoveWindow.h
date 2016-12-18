//
//  MoveWindow.h
//  MouseFrog
//
//  Created by 王振西 on 2016/12/18.
//  Copyright © 2016年 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#define MaxDisplayScreens 3

@interface MoveWindow : NSObject{
    int  sortByDID[MaxDisplayScreens];
    CGDirectDisplayID  sortByunID[MaxDisplayScreens];
    CGSize windowSize;
    CGPoint windowPosition;
    CFStringRef windowTitle;
    AXUIElementRef frontMostApp;
    AXUIElementRef frontMostWindow;
}
- (void) sortScreenByunID;
- (void) goToScreen:(int)screenNumber;
@end
