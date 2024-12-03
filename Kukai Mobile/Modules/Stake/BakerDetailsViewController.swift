//
//  BakerDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/07/2023.
//

import UIKit
import KukaiCoreSwift
import Combine

class BakerDetailsViewController: UIViewController {
	
	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	@IBOutlet weak var delegateButton: CustomisableButton!
	
	private var viewModel = BakerDetailsViewModel()
	private var cancellable: AnyCancellable?
	
	var dimBackground: Bool = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		delegateButton.customButtonType = .primary
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					let _ = ""
					
				case .failure(_, let errorString):
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success(_):
					let _ = ""
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let baker = TransactionService.shared.delegateData.chosenBaker else {
			return
		}
		
		delegateButton.isHidden = DependencyManager.shared.balanceService.account.delegate?.address == baker.address
		bakerNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		MediaProxyService.load(url: baker.logo, to: bakerIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		
		viewModel.refresh(animate: false)
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	@IBAction func delegateTapped(_ sender: Any) {
		let parent = ((self.presentationController?.presentingViewController as? UINavigationController)?.viewControllers.last as? ChooseBakerViewController)
		parent?.delegateTapped()
		self.dismissBottomSheet()
	}
}
