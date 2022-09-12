//
//  PLoginViewController.h
//  Portl iOS Application
//
//  Created by Portl LLC on 6/10/16.
//  Copyright © 2016 Portl LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *buttonForLogin;
@property (weak, nonatomic) IBOutlet UITextField *textfieldEmailAddress;
@property (weak, nonatomic) IBOutlet UITextField *textfieldPassword;
@property (weak, nonatomic) IBOutlet UIButton *buttonGuestLogin;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* spinner;

@end
