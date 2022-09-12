//
//  RootTabBarController.h
//  Portl iOS Application
//  Created by Portl LLC on 2017/04/11.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootTabBarController : UITabBarController

- (void)presentViewController:(UIViewController *)controller;
- (void)dismissViewController;

@end
