//
//  DimmingPresentationController.swift
//  Portl
//
//  Created by Jeff Creed on 4/12/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    
    // MARK: UIPresentationController
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        guard let containerView = containerView, let transitionCoordinator = presentingViewController.transitionCoordinator else {
            return
        }
        
        let dimmingView = UIView(frame: .zero)
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 60.0)
        
        containerView.addSubview(dimmingView)
        containerView.addConstraint(dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor))
        containerView.addConstraint(dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor))
        containerView.addConstraint(dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor))
        containerView.addConstraint(dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor))
        
        self.dimmingView = dimmingView
        
        if transitionCoordinator.isAnimated {
            dimmingView.alpha = 0.0
            UIView.animate(withDuration: BottomSlideInTransitionAnimator.animationDuration * DimmingPresentationController.animationDurationPercentage, animations: {
                dimmingView.alpha = 1.0
            })
        }
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        guard let dimmingView = dimmingView, let transitionCoordinator = presentingViewController.transitionCoordinator else {
            return
        }
        
        if transitionCoordinator.isAnimated {
            transitionCoordinator.animate(alongsideTransition: { (context) in
                dimmingView.alpha = 0.0
            }) { (context) in
                dimmingView.removeFromSuperview()
                self.dimmingView = nil
            }
        } else {
            dimmingView.removeFromSuperview()
            self.dimmingView = nil
        }
    }
    
    // MARK: Properties (Private)
    
    private var dimmingView: UIView?
    
    // MARK: Properties (Private Static Constant)
    
    private static let animationDurationPercentage: TimeInterval = 0.2
}
