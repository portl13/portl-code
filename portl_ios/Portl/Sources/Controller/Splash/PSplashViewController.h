//
//  PSplashViewController.h
//  Portl iOS Application
//
//  Created by Portl LLC on 6/9/16.
//  Copyright © 2016 Portl LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PSplashViewController : UIViewController

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintForPostrLogoBottom;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewPostrLogo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;

@end
