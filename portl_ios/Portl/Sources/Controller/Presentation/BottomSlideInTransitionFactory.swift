//
//  BottomSlideInTransitionFactory.swift
//  Portl
//
//  Created by Jeff Creed on 4/12/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import UIKit

class BottomSlideInTransitionFactory: NSObject, UIViewControllerTransitioningDelegate {
    
    // MARK: UIViewControllerTransisitoningDelegate
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSlideInTransitionAnimator(isPresenting: false)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSlideInTransitionAnimator(isPresenting: true)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
