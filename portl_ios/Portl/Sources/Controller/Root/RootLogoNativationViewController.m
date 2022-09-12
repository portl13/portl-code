//
//  RootLogoNativationViewController.m
//  Portl iOS Application
//
//  Created by Portl LLC on 6/10/16.
//  Copyright © 2016 Portl LLC. All rights reserved.
//

#import "RootLogoNativationViewController.h"

@interface RootLogoNativationViewController ()

@property (strong, nonatomic) UIImageView *imageViewPostrLogo;

@end

@implementation RootLogoNativationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    
//    [self addPostrLogo];
//    [self addBackgroundLogo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)addBackgroundLogo {
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_background"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.view insertSubview:imageView atIndex:0];

    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:imageView
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1
                                                                   constant:0];
    [self.view addConstraint:constraint];

    constraint = [NSLayoutConstraint constraintWithItem:imageView
                                              attribute:NSLayoutAttributeLeading
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeLeading
                                             multiplier:1
                                               constant:0];
    [self.view addConstraint:constraint];

    constraint = [NSLayoutConstraint constraintWithItem:imageView
                                              attribute:NSLayoutAttributeTrailing
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeTrailing
                                             multiplier:1
                                               constant:0];
    [self.view addConstraint:constraint];

    constraint = [NSLayoutConstraint constraintWithItem:imageView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1
                                               constant:0];
    [self.view addConstraint:constraint];
    
//    [self.view layoutIfNeeded];
}

- (void)addPostrLogo {
    
    self.imageViewPostrLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_portl_logo"]];
    self.imageViewPostrLogo.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.imageViewPostrLogo atIndex:0];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.imageViewPostrLogo
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1
                                                                   constant:40];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.imageViewPostrLogo
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1
                                               constant:0];
    [self.view addConstraint:constraint];
    [self.view layoutIfNeeded];
    
    self.imageViewPostrLogo.alpha = 0;
    [UIView animateWithDuration:1.0f animations:^{
        self.imageViewPostrLogo.alpha = 1;
    }];
}

@end
