//
//  EnterCustomBakerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2023.
//

import UIKit

class EnterCustomBakerViewController: UIViewController, EnterAddressComponentDelegate {
	
	@IBOutlet weak var enterAddressComponent: EnterAddressComponent!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		enterAddressComponent.headerLabel.text = "Baker:"
		enterAddressComponent.updateAvilableAddressTypes([.tezosAddress, .tezosDomain])
		enterAddressComponent.delegate = self
    }
	
	func validatedInput(entered: String, validAddress: Bool, ofType: AddressType) {
		if !validAddress {
			return
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			
			if ofType == .tezosAddress {
				let parent = ((self?.presentationController?.presentingViewController as? UINavigationController)?.viewControllers.last as? StakeViewController)
				parent?.enteredCustomBaker(address: entered)
				self?.dismissBottomSheet()
				
			} else {
				self?.findAddressThenNavigate(text: entered, type: ofType)
			}
		}
	}
	
	func findAddressThenNavigate(text: String, type: AddressType) {
		self.showLoadingView()
		
		enterAddressComponent.findAddress(forText: text) { [weak self] result in
			self?.hideLoadingView()
			
			guard let res = try? result.get() else {
				self?.hideLoadingView()
				self?.windowError(withTitle: "Error", description: result.getFailure().description)
				return
			}
			
			let parent = ((self?.presentationController?.presentingViewController as? UINavigationController)?.viewControllers.last as? StakeViewController)
			parent?.enteredCustomBaker(address: res.address)
			self?.hideLoadingView()
			self?.dismissBottomSheet()
		}
	}
}
