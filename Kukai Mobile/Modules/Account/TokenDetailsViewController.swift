//
//  TokenDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import Combine
import KukaiCoreSwift

class TokenDetailsViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var favouriteButton: CustomisableButton!
	@IBOutlet weak var moreButtonBarItem: UIBarButtonItem!
	@IBOutlet weak var moreButtonContainer: UIView!
	@IBOutlet weak var moreButton: CustomisableButton!
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = TokenDetailsViewModel()
	private var cancellable: AnyCancellable?
	private var firstLoad = true
	private var menu: MenuViewController? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		favouriteButton.accessibilityIdentifier = "button-favourite"
		moreButton.accessibilityIdentifier = "button-more"
		
		viewModel.token = TransactionService.shared.sendData.chosenToken
		viewModel.delegate = self
		viewModel.makeDataSource(withTableView: tableView)
		
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView()
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					
					self?.setFavState(isFav: self?.viewModel.buttonData?.isFavourited ?? false)
					if self?.viewModel.buttonData?.hasMoreButton == true {
						self?.menu = self?.moreMenu()
						
					} else {
						self?.navigationItem.rightBarButtonItems?.removeAll(where: { item in
							item == self?.moreButtonBarItem
						})
					}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if firstLoad {
			viewModel.refresh(animate: true)
			firstLoad = false
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? TokenContractViewController {
			vc.setup(tokenId: viewModel.token?.tokenId?.description ?? "0", contractAddress: viewModel.token?.tokenContractAddress ?? "")
		}
	}
	
	@IBAction func favouriteButtonTapped(_ sender: CustomisableButton) {
		guard self.viewModel.buttonData?.canBeUnFavourited == true else {
			return
		}
		
		guard let token = TransactionService.shared.sendData.chosenToken else {
			windowError(withTitle: "error".localized(), description: "error-no-token".localized())
			return
		}
		
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		if viewModel.buttonData?.isFavourited == true {
			if TokenStateService.shared.removeFavourite(forAddress: address, token: token) {
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				viewModel.buttonData?.isFavourited = false
				setFavState(isFav: false)
				
			} else {
				windowError(withTitle: "error".localized(), description: "error-cant-unfav".localized())
			}
			
		} else {
			if TokenStateService.shared.addFavourite(forAddress: address, token: token) {
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				viewModel.buttonData?.isFavourited = true
				setFavState(isFav: true)
				
			} else {
				windowError(withTitle: "error".localized(), description: "error-cant-fav".localized())
			}
		}
	}
	
	@IBAction func moreButtonTapped(_ sender: CustomisableButton) {
		menu?.display(attachedTo: sender)
	}
	
	private func setFavState(isFav: Bool) {
		if isFav {
			favouriteButton.customImage = UIImage(named: "FavoritesOn") ?? UIImage()
			favouriteButton.accessibilityValue = "On"
		} else {
			favouriteButton.customImage = UIImage(named: "FavoritesOff") ?? UIImage()
			favouriteButton.accessibilityValue = "Off"
		}
		
		favouriteButton.updateCustomImage()
	}
	
	private func moreMenu() -> MenuViewController {
		var actions: [UIAction] = []
		
		if viewModel.token?.isXTZ() == false {
			actions.append(
				UIAction(title: "Token Contract", image: UIImage(named: "Placeholder"), identifier: nil, handler: { [weak self] action in
					self?.performSegue(withIdentifier: "tokenContract", sender: nil)
				})
			)
		}
		
		if viewModel.buttonData?.canBeHidden == true {
			if viewModel.buttonData?.isHidden == true {
				actions.append(
					UIAction(title: "Unhide Token", image: UIImage(named: "HiddenOff"), identifier: nil, handler: { [weak self] action in
						guard let token = TransactionService.shared.sendData.chosenToken else {
							self?.windowError(withTitle: "error".localized(), description: "error-no-token".localized())
							return
						}
						
						let address = DependencyManager.shared.selectedWalletAddress ?? ""
						if TokenStateService.shared.removeHidden(forAddress: address, token: token) {
							DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
							self?.navigationController?.popViewController(animated: true)
							
						} else {
							self?.windowError(withTitle: "error".localized(), description: "error-unhide-token".localized())
						}
					})
				)
			} else {
				actions.append(
					UIAction(title: "Hide Token", image: UIImage(named: "HiddenOn"), identifier: nil, handler: { [weak self] action in
						guard let token = TransactionService.shared.sendData.chosenToken else {
							self?.windowError(withTitle: "error".localized(), description: "error-no-token".localized())
							return
						}
						
						let address = DependencyManager.shared.selectedWalletAddress ?? ""
						if TokenStateService.shared.addHidden(forAddress: address, token: token) {
							DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
							self?.navigationController?.popViewController(animated: true)
							
						} else {
							self?.windowError(withTitle: "error".localized(), description: "error-hide-token".localized())
						}
					})
				)
			}
		}
		
		if viewModel.buttonData?.canBeViewedOnline == true {
			actions.append(
				UIAction(title: "View on Blockchain", image: UIImage(named: "ArrowWeb"), identifier: nil, handler: { [weak self] action in
					if let contract = self?.viewModel.token?.tokenContractAddress, let url = URL(string: "https://better-call.dev/mainnet/\(contract)") {
						UIApplication.shared.open(url, completionHandler: nil)
					}
				})
			)
		}
		
		return MenuViewController(actions: [actions], header: nil, sourceViewController: self)
	}
}



// MARK: - TokenDetailsButtonsCellDelegate

extension TokenDetailsViewController: TokenDetailsViewModelDelegate {
	
	func sendTapped() {
		self.performSegue(withIdentifier: "send", sender: nil)
	}
	
	func launchExternalBrowser(withURL url: URL) {
		UIApplication.shared.open(url)
	}
}

extension TokenDetailsViewController: TokenDetailsBakerDelegate {
	
	func changeTapped() {
		
		if viewModel.isNewBakerFlow() {
			self.alert(errorWithMessage: "Under Construction")
		} else {
			self.performSegue(withIdentifier: "choose-baker", sender: nil)
		}
	}
	
	func learnTapped() {
		self.alert(errorWithMessage: "Under Construction")
	}
}

extension TokenDetailsViewController: TokenDetailsStakeBalanceDelegate {
	
	func stakeTapped() {
		TransactionService.shared.stakeData.chosenBaker = viewModel.baker
		TransactionService.shared.stakeData.chosenToken = viewModel.token
		self.performSegue(withIdentifier: "stake-amount", sender: nil)
	}
	
	func unstakeTapped() {
		self.alert(errorWithMessage: "Under Construction")
	}
	
	func finalizeTapped() {
		self.alert(errorWithMessage: "Under Construction")
	}
}
