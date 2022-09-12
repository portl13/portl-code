//
//  PLoginViewController.m
//  Portl iOS Application
//
//  Created by Portl LLC on 6/10/16.
//  Copyright © 2016 Portl LLC. All rights reserved.
//

#import "PLoginViewController.h"
#import "RootTabBarController.h"
#import "NSDictionary+safeString.h"

#import "FIRFriends.h"
#import "Portl-Swift.h"

const CGFloat kSignupButtonBottomMargin = 10;
const CGFloat kSignupButtonBottomConstant = 194;

@interface PLoginViewController () <UIScrollViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *dismissKeyboardButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *statusBarTintView;

@end

@implementation PLoginViewController {
	FriendsController* friendsController;
	FCMTokenManagerController* fcmTokenManagerController;
	BOOL openedAsGuest;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	if (@available(iOS 13.0, *)) {
		self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
	}
	
    // Do any additional setup after loading the view.
	friendsController = [[FriendsController alloc] init];
	fcmTokenManagerController = [[FCMTokenManagerController alloc] init];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    }

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	openedAsGuest = [[FIRPortlAuthenticator sharedAuthenticator] isGuestLogin];
}

// MARK: UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    UIResponder* nextResponder = [textField.superview viewWithTag:textField.tag + 1];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}

// MARK: UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat alphaCalc = 0.0;
    if (scrollView.contentOffset.y > 0.0) {
        alphaCalc = MIN(scrollView.contentOffset.y * 1/100.0, 1.0);
    }
    self.statusBarTintView.alpha = alphaCalc;
}

// MARK: Notifications (Keyboard)

- (void)keyboardWillShow:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.1 animations:^{
        [self.scrollView setContentInset:UIEdgeInsetsMake(0, 0, kbSize.height, 0)];
        [self.view layoutIfNeeded];
    }];
    
    [self.dismissKeyboardButton setHidden:NO];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    [self.dismissKeyboardButton setHidden:YES];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.scrollView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)dismissKeyboard:(id)sender {
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (IBAction)onSignIn:(id)sender {
    [self dismissKeyboard:(self)];
    
    if ([self.textfieldEmailAddress.text isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Please enter your E-mail address." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    if ([self.textfieldPassword.text isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Please enter your password." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    
	[self setBusyLoggingIn:YES];
	
    [[FIRPortlAuthenticator sharedAuthenticator] loginWithEmail:self.textfieldEmailAddress.text withPassword:self.textfieldPassword.text completed:^(PortlError *error) {
        if (error != nil) {
            if (error.customizedErrorCode == PERRCODE_INVALID_EMAIL || error.customizedErrorCode == PERRCODE_INVALID_PASSWORD) {
				[self presentErrorAlertWithMessage:@"Login details incorrect. Please try again." completion:nil];
            } else {
				[self presentErrorAlertWithMessage:@"Login failed. Please try again." completion:nil];
            }
        } else {
            [self openMainPage];
        }
		[self setBusyLoggingIn:NO];
    }];
    
}

- (void) openMainPage {
	[friendsController loadFriends];
	
    [[FIRFriends sharedFriends] fetchMyFriends];
	
	[fcmTokenManagerController setFCMTokenAfterLogin];
	
	if (openedAsGuest) {
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self.navigationController performSegueWithIdentifier:@"rootSegue" sender:self];
	}
}

- (IBAction)onSkipLogin:(id)sender {
	[self dismissKeyboard:(self)];

	if ([[FIRPortlAuthenticator sharedAuthenticator] isGuestLogin]) {
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self setBusyLoggingIn:YES];
		
		[[FIRPortlAuthenticator sharedAuthenticator] guestLoginWithCompleted:^(PortlError *error) {
			if (error == nil) {
				[self openMainPage];
			} else {
				UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Cannot login now. Please try again later" preferredStyle:UIAlertControllerStyleAlert];
				[alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
				[self presentViewController:alertController animated:YES completion:nil];
			}
			
			[self setBusyLoggingIn:NO];
		}];
	}
}

- (IBAction)onSignUp:(id)sender {
    [self dismissKeyboard:(self)];

    if ([[FIRPortlAuthenticator sharedAuthenticator] isGuestLogin]) {
		if (self.navigationController.viewControllers.count > 1) {
			[self.navigationController popViewControllerAnimated:YES];
		} else {
			[self performSegueWithIdentifier:@"sid_signup" sender:nil];
		}
		return;
    }
    
    [self performSegueWithIdentifier:@"sid_signup" sender:nil];
}


- (IBAction)onForgotPassword:(id)sender {
    [self dismissKeyboard:(self)];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Please enter your email to reset password." preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = [alertController textFields][0];
        if (![textField.text isEqualToString:@""]) {
            [[FIRAuth auth] sendPasswordResetWithEmail:textField.text completion:^(NSError * _Nullable error) {
                if (error) {
                    
                    if ([[error.userInfo safeStringForKey:@"error_name"] isEqualToString:@"ERROR_USER_NOT_FOUND"]) {
                        UIAlertController *prompt = [UIAlertController alertControllerWithTitle:nil message:@"We've not found your E-mail.  Please try again." preferredStyle:UIAlertControllerStyleAlert];
                        [prompt addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:prompt animated:YES completion:nil];
                    } else {
                        UIAlertController *prompt = [UIAlertController alertControllerWithTitle:nil message:@"Sorry, we've failed to reset your password for some unknown reason. Please try again later." preferredStyle:UIAlertControllerStyleAlert];
                        [prompt addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:prompt animated:YES completion:nil];
                    }
                    
                } else {
                    
                    UIAlertController *prompt = [UIAlertController alertControllerWithTitle:nil message:@"We've sent reset password E-mail to you." preferredStyle:UIAlertControllerStyleAlert];
                    [prompt addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:prompt animated:YES completion:nil];
                    
                }
            }];
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)setBusyLoggingIn:(BOOL)isBusy {
	self.buttonForLogin.hidden = isBusy;
	self.buttonGuestLogin.enabled = !isBusy;
	if (isBusy) {
		[self.spinner startAnimating];
	} else {
		[self.spinner stopAnimating];
	}
}

@end
