//
//  ProfileBioEditViewController.m
//  Portl iOS Application
//  Created by Portl LLC on 2017/01/11.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import "ProfileBioEditViewController.h"
#import <UITextView_Placeholder/UITextView+Placeholder.h>
#import "NSMutableDictionary+safeString.h"
#import "Portl-Swift.h"

@interface ProfileBioEditViewController ()

@property (strong, nonatomic) ProfileServiceController* profileServiceController;

@end

@implementation ProfileBioEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.profileServiceController = [[ProfileServiceController alloc] init];
	
    self.textViewMain.placeholder = @"Enter your bio description here.";
	self.textViewMain.text = [self.profileServiceController getProfileBio];
	
	self.navigationItem.title = @"Edit Bio";

	UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_arrow_left"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
	backItem.tintColor = [UIColor whiteColor];
	self.navigationItem.leftBarButtonItem = backItem;

	UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(onDone)];
	doneItem.tintColor = [UIColor whiteColor];
	self.navigationItem.rightBarButtonItem = doneItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];

	[self.textViewMain becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onDone {
    
	[self.profileServiceController setProfileBioWithBioText:self.textViewMain.text completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    
    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    self.constraintForTextViewBottom.constant = keyboardSize.height;

}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.constraintForTextViewBottom.constant = 0;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    
    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    self.constraintForTextViewBottom.constant = keyboardSize.height;
}

@end
