//
//  BottomSlideInTransitionAnimator.swift
//  Portl
//
//  Created by Jeff Creed on 6/4/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import UIKit

class BottomSlideInTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    // MARK: UIViewControllerAnimatedTransitioning
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return BottomSlideInTransitionAnimator.animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentationTransition(using: transitionContext)
        } else {
            animateDismissalTransition(using: transitionContext)
        }
    }
    
    // MARK: Private
    
    private func animatePresentationTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to),
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let finalSize = toViewController.preferredContentSize
        let fromHeight = fromViewController.view.frame.size.height
        let finalFrame = CGRect(x: fromViewController.view.frame.origin.x, y: fromHeight - finalSize.height, width: fromViewController.view.frame.size.width, height: finalSize.height)
        
        toView.frame = CGRect(x: finalFrame.origin.x, y: fromHeight + finalSize.height, width: fromViewController.view.frame.size.width , height: finalSize.height)
        transitionContext.containerView.addSubview(toView)
        if transitionContext.isAnimated {
            UIView.animate(withDuration: BottomSlideInTransitionAnimator.animationDuration, animations: {
                toView.frame = finalFrame
            }) { (complete) in
                transitionContext.completeTransition(true)
            }
        } else {
            transitionContext.completeTransition(true)
        }
    }
    
    private func animateDismissalTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        
        if transitionContext.isAnimated {
            UIView.animate(withDuration: BottomSlideInTransitionAnimator.animationDuration, animations: {
                fromView.frame = CGRect(x: fromView.frame.origin.x, y: fromView.frame.origin.y + fromView.frame.height, width: fromView.frame.width, height: fromView.frame.height)
            }) { (completed) in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        } else {
            transitionContext.completeTransition(true)
        }
    }
    
    // MARK: Initialization
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }
    
    // MARK: Properties
    
    let isPresenting: Bool
    
    // MARK: Properties (Static Constant)
    
    static let animationDuration: TimeInterval = 0.5
}
