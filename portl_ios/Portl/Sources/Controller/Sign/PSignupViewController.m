//
//  PSignupViewController.m
//  Portl iOS Application
//
//  Created by Portl LLC on 6/10/16.
//  Copyright © 2016 Portl LLC. All rights reserved.
//

#import "PSignupViewController.h"
#import "NSString+formatCheck.h"
#import "RootTabBarController.h"
#import "Portl-Swift.h"

@interface PSignupViewController () <UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, OptionalSignUpViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *dismissKeyboardButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *statusBarTintView;
@property (weak, nonatomic) IBOutlet UITextView *tosLabel;

@end

@implementation PSignupViewController {
	BOOL openedAsGuest;
	FriendsController* friendsController;
	FCMTokenManagerController* fcmTokenManagerController;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (@available(iOS 13.0, *)) {
		self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
	}

	// Do any additional setup after loading the view.
	friendsController = [[FriendsController alloc] init];
	fcmTokenManagerController = [[FCMTokenManagerController alloc] init];
	
	NSMutableAttributedString* tosString = [[NSMutableAttributedString alloc] initWithString:@"By signing up, you agree to PORTL Terms of Service and Privacy Policy" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16.0]}];
	NSRange termsRange = [tosString.string rangeOfString:@"Terms of Service"];
	NSRange privacyRange = [tosString.string rangeOfString:@"Privacy Policy"];
	UIColor* textColor = [UIColor colorWithRed:204.0/255.0 green:207.0/255.0 blue:204.0/255.0 alpha:1.0];
	UIColor* linkColor = [UIColor colorWithRed:237.0/255.0 green:30.0/255.0 blue:121.0/255.0 alpha:1.0];
	[tosString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16.0] range:NSMakeRange(0, tosString.string.length)];
	[tosString addAttribute:NSLinkAttributeName value:@"CUSTOM://TOS" range:termsRange];
	[tosString addAttribute:NSLinkAttributeName value:@"CUSTOM://PP" range:privacyRange];
	[tosString addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, tosString.string.length)];
	self.tosLabel.linkTextAttributes = @{NSForegroundColorAttributeName: linkColor};
	self.tosLabel.textContainerInset = UIEdgeInsetsZero;
	self.tosLabel.textContainer.lineFragmentPadding = 0;
	[self.tosLabel setAttributedText:tosString];
	self.tosLabel.textAlignment = NSTextAlignmentCenter;
	
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
	self.textfieldPassword.text = nil;
	self.textfieldEmailAddress.text = nil;
	self.textfieldUsername.text = nil;
}

// MARK: UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
	if ([URL.scheme isEqualToString:@"CUSTOM"]) {
		if ([[URL.absoluteURL absoluteString] isEqualToString:@"CUSTOM://TOS"]) {
			[self performSegueWithIdentifier:@"termsSegue" sender:self];
		} else {
			[self performSegueWithIdentifier:@"privacySegue" sender:self];
		}
	}
	return YES;
}

// MARK: Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"termsSegue"]) {
		TermsViewController* controller = (TermsViewController*)segue.destinationViewController;
		controller.isModal = YES;
	} else if ([segue.identifier isEqualToString:@"optionalSignUpSegue"]) {
		OptionalSignUpViewController* controller = (OptionalSignUpViewController*)segue.destinationViewController;
		controller.delegate = self;
	} else if ([segue.identifier isEqualToString:@"privacySegue"]) {
		PrivacyPolicyViewController* controller = (PrivacyPolicyViewController*)segue.destinationViewController;
		controller.isModal = YES;
	}
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (textField == self.textfieldUsername) {
		if(range.length + range.location > textField.text.length) {
			return NO;
		}
		__block NSUInteger stringCount = 0;
		[string enumerateSubstringsInRange:NSMakeRange(0, [string length])
								   options:NSStringEnumerationByComposedCharacterSequences
								usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
									stringCount++;
								}];
		
		__block NSUInteger textCount = 0;
		[textField.text enumerateSubstringsInRange:NSMakeRange(0, [textField.text length])
								   options:NSStringEnumerationByComposedCharacterSequences
								usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
									textCount++;
								}];
		
		NSUInteger newLength = textCount + stringCount - range.length;
		return newLength <= 32;
	} else {
		return YES;
	}
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

- (IBAction)onLogin:(id)sender {
	[self dismissKeyboard:(self)];
	
	if ([[FIRPortlAuthenticator sharedAuthenticator] isGuestLogin]) {
		if (self.navigationController.viewControllers.count > 1) {
			[self.navigationController popViewControllerAnimated:YES];
		} else {
			[self performSegueWithIdentifier:@"sid_login" sender:nil];
		}
		return;
	}
	
	if (self.navigationController.viewControllers.count > 1) {
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	}
}

- (IBAction)onSignUp:(id)sender {
	[self dismissKeyboard:(self)];
	
	if ([self.textfieldEmailAddress.text isEqualToString:@""]) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Please enter your E-mail address." preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
		return;
	}
	
	if (![self.textfieldEmailAddress.text isValidEmailAddress]) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Please enter a valid E-mail address." preferredStyle:UIAlertControllerStyleAlert];
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
	
	if (self.textfieldPassword.text.length < 6) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Password should be at least 6 characters." preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
		return;
	}
	
	if ([self.textfieldUsername.text isEqualToString:@""]) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Please enter your username." preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
		return;
	}
	
	if ([self.textfieldUsername.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length < 6) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Username should be at least 6 characters." preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
		return;
	}
	
	if (self.textfieldUsername.text.length > 32) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Username should be 32 characters or less." preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
		return;
	}
	
	
	NSString *fromGuestId = @"";
	
	if (/*[__dataKeeper__ userInfo] != nil && [__dataKeeper__.userInfo safeBooleanValueForKey:@"is_guest"]*/[[FIRPortlAuthenticator sharedAuthenticator] isGuestLogin]) {
		fromGuestId = [FIRPortlAuthenticator sharedAuthenticator].currentUser.uid; //[__dataKeeper__.userInfo safeStringForKey:@"id"];
	}
	
	[self setBusyRegistering:YES];
	
	[[FIRPortlAuthenticator sharedAuthenticator] signupWithEmail:self.textfieldEmailAddress.text
								 password:self.textfieldPassword.text
								 username:[self.textfieldUsername.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
							  fromGuestId:fromGuestId
								completed:^(PortlError *error) {
									if (error != nil) {
										NSLog(@"Error in sign up, %d, %@, %@", error.customizedErrorCode, error.customizedErrorMessage, error.error);
										[self presentErrorAlertWithMessage:error.customizedErrorMessage completion:nil];
									} else {
										[self loadProfileAndGoToSecondarySignUp];
									}
									[self setBusyRegistering:NO];
								}];
}

- (IBAction)onSkipSignUp:(id)sender {
	[self dismissKeyboard:(self)];
	
	if ([[FIRPortlAuthenticator sharedAuthenticator] isGuestLogin]) {
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self setBusyRegistering:YES];
		
		[[FIRPortlAuthenticator sharedAuthenticator] guestLoginWithCompleted:^(PortlError *error) {
			if (error == nil) {
				[self openMainPage];
			} else {
				UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Cannot login now. Please try again later" preferredStyle:UIAlertControllerStyleAlert];
				[alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
				[self presentViewController:alertController animated:YES completion:nil];
			}
			[self setBusyRegistering:NO];
		}];
	}
}

- (void)loadProfileAndGoToSecondarySignUp {
	[friendsController loadFriends];
	
	[[FIRFriends sharedFriends] fetchMyFriends];
	[fcmTokenManagerController setFCMTokenAfterLogin];

	[self performSegueWithIdentifier:@"optionalSignUpSegue" sender:self];
}

- (void)optionalSignUpViewControllerDidFinish:(OptionalSignUpViewController *)optionalSignUpViewController {
	[self openMainPage];
}

- (void)openMainPage {
	if (openedAsGuest) {
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	} else {
		NSMutableArray* viewControllers = [self.navigationController.viewControllers mutableCopy];
		RootTabBarController *newController = __Controller(@"Main", @"RootTabBarController");
		[viewControllers insertObject:newController atIndex:1];
		self.navigationController.viewControllers = viewControllers;
		[self.navigationController popToViewController:newController animated:YES];
	}
}

- (void)setBusyRegistering:(BOOL)isBusy {
	self.buttonForSignup.hidden = isBusy;
	self.signInButton.enabled = !isBusy;
	if (isBusy) {
		[self.spinner startAnimating];
	} else {
		[self.spinner stopAnimating];
	}
}

@end
