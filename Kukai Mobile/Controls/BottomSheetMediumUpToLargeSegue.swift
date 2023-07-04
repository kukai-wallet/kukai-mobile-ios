//
//  BottomSheetMediumUpToLargeSegue.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/07/2023.
//

import UIKit

public class BottomSheetMediumUpToLargeSegue: UIStoryboardSegue {
	
	override public func perform() {
		guard let dest = destination.presentationController as? UISheetPresentationController else {
			return
		}
		
		dest.detents = [.medium(), .large()]
		dest.prefersGrabberVisible = true
		dest.preferredCornerRadius = 30
		
		source.present(destination, animated: true)
		
		
		// If we are not on top of another bottom sheet, darken the background more
		if source.presentingViewController?.presentedViewController == nil {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
				UIView.animate(withDuration: 0.3, delay: 0) {
					dest.containerView?.backgroundColor = UIColor("#000000", alpha: 0.75)
				}
			})
		}
	}
}
