//
//  BottomSheetVariableSegue.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 02/02/2023.
//

import UIKit

public protocol BottomSheetCustomFixedProtocol {
	var bottomSheetMaxHeight: CGFloat { get }
}

public protocol BottomSheetCustomCalculateProtocol {
	func bottomSheetHeight() -> CGFloat
}

public class BottomSheetCustomSegue: UIStoryboardSegue {
	
	override public func perform() {
		guard let dest = destination.presentationController as? UISheetPresentationController else {
			return
		}
		
		if let des = destination as? BottomSheetCustomCalculateProtocol {
			let height = des.bottomSheetHeight()
			let customId = UISheetPresentationController.Detent.Identifier("variable")
			let customDetent = UISheetPresentationController.Detent.custom(identifier: customId) { context in
				return height
			}
			dest.detents = [customDetent]
			
		} else if let value = (destination as? BottomSheetCustomFixedProtocol)?.bottomSheetMaxHeight {
			let customId = UISheetPresentationController.Detent.Identifier("variable")
			let customDetent = UISheetPresentationController.Detent.custom(identifier: customId) { context in
				return value
			}
			dest.detents = [customDetent]
			
		} else {
			let customId = UISheetPresentationController.Detent.Identifier("large-minus-background-effect")
			let customDetent = UISheetPresentationController.Detent.custom(identifier: customId) { context in
				return context.maximumDetentValue - 0.1
			}
			dest.detents = [customDetent]
		}
		
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
