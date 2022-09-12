//
//  PSignupViewController.h
//  Portl iOS Application
//
//  Created by Portl LLC on 6/10/16.
//  Copyright © 2016 Portl LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PSignupViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *buttonForSignup;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UITextField *textfieldEmailAddress;
@property (weak, nonatomic) IBOutlet UITextField *textfieldPassword;
@property (weak, nonatomic) IBOutlet UITextField *textfieldUsername;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* spinner;

- (IBAction)onLogin:(id)sender;

@end
