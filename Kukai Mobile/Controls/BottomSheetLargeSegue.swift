//
//  BottomSheetLargeSegue.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/12/2021.
//

import UIKit

public class BottomSheetLargeSegue: UIStoryboardSegue {
	
	override public func perform() {
		guard let dest = destination.presentationController as? UISheetPresentationController else {
			return
		}
		
		let customId = UISheetPresentationController.Detent.Identifier("large-minus-background-effect")
		let customDetent = UISheetPresentationController.Detent.custom(identifier: customId) { context in
			return context.maximumDetentValue - 0.1
		}
		dest.detents = [customDetent]
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
