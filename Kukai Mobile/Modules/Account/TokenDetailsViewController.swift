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
	
	@IBOutlet weak var headerIcon: UIImageView!
	@IBOutlet weak var headerIconWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var headerIconHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var headerSymbol: UILabel!
	@IBOutlet weak var headerFiat: UILabel!
	@IBOutlet weak var headerPriceChange: UILabel!
	@IBOutlet weak var headerPriceChangeArrow: UIImageView!
	@IBOutlet weak var headerPriceChangeDate: UILabel!
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = TokenDetailsViewModel()
	private var cancellable: AnyCancellable?
	private var headerAnimator = UIViewPropertyAnimator()
	private var headerAnimatorStarted = false
	private let defaultHeaderFiatFontSize: CGFloat = 18
	private var currentHeaderFiatFontSize: CGFloat = 18
	private var firstLoad = true
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		headerPriceChangeDate.accessibilityIdentifier = "token-details-selected-date"
		
		viewModel.token = TransactionService.shared.sendData.chosenToken
		viewModel.delegate = self
		viewModel.chartDelegate = self
		viewModel.buttonDelegate = self
		viewModel.makeDataSource(withTableView: tableView)
		
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		loadPlaceholderUI()
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					self?.loadRealData()
					self?.updatePriceChange()
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
	
	func loadPlaceholderUI() {
		headerSymbol.text = ""
		headerFiat.text = ""
		headerPriceChange.text = ""
		headerPriceChangeDate.text = ""
		headerPriceChangeArrow.image = UIImage()
	}
	
	func loadRealData() {
		if let tokenURL = viewModel.tokenIconURL {
			MediaProxyService.load(url: tokenURL, to: headerIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
		} else {
			headerIcon.image = viewModel.tokenIcon
		}
		
		headerSymbol.text = viewModel.tokenSymbol
		headerFiat.text = viewModel.tokenFiatPrice
	}
	
	func updatePriceChange() {
		guard viewModel.tokenPriceChange != "" else {
			return
		}
		
		headerPriceChange.text = viewModel.tokenPriceChange
		headerPriceChangeDate.text = viewModel.tokenPriceDateText
		
		if viewModel.tokenPriceChangeIsUp {
			let color = UIColor.colorNamed("TxtGood4")
			var image = UIImage(named: "ArrowUp")
			image = image?.resizedImage(size: CGSize(width: 12, height: 12))
			image = image?.withTintColor(color)
			
			headerPriceChangeArrow.image = image
			headerPriceChange.textColor = color
			
		} else {
			let color = UIColor.colorNamed("TxtAlert4")
			var image = UIImage(named: "ArrowDown")
			image = image?.resizedImage(size: CGSize(width: 12, height: 12))
			image = image?.withTintColor(color)
			
			headerPriceChangeArrow.image = image
			headerPriceChange.textColor = color
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? TokenContractViewController {
			vc.setup(tokenId: viewModel.token?.tokenId?.description ?? "0", contractAddress: viewModel.token?.tokenContractAddress ?? "")
		}
	}
}



// MARK: - UITableViewDelegate

extension TokenDetailsViewController {
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		guard headerAnimatorStarted == false else {
			return
		}
		
		// make sure we only run this ocne
		headerAnimatorStarted = true
		
		// Set what we want the constraints to be
		self.headerIconWidthConstraint.constant = 32
		self.headerIconHeightConstraint.constant = 32
		
		// Setup property animator
		headerAnimator = UIViewPropertyAnimator(duration: 3, curve: .easeOut, animations: { [weak self] in
			
			self?.headerIcon.customCornerRadius = (self?.headerIconWidthConstraint.constant ?? 32) / 2
			
			// Refresh constraints
			self?.view.layoutIfNeeded()
			
			// Alpha the rest
			self?.headerPriceChange.alpha = 0
			self?.headerPriceChangeDate.alpha = 0
			self?.headerPriceChangeArrow.alpha = 0
		})
		
		headerAnimator.startAnimation()
		headerAnimator.pauseAnimation()
		headerAnimator.pausesOnCompletion = true
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		
		// Every move event, compute how much things should change
		let fraction = self.tableView.contentOffset.y / 75
		
		if fraction <= 1 {
			headerAnimator.fractionComplete = fraction
			
			let fontSizeReduction: CGFloat = CGFloat(Int(fraction / 0.1))
			var newSize = CGFloat(defaultHeaderFiatFontSize - fontSizeReduction)
			
			if newSize < 12 {
				newSize = 13
			} else if newSize > defaultHeaderFiatFontSize {
				newSize = defaultHeaderFiatFontSize
			}
			
			if newSize != currentHeaderFiatFontSize {
				self.headerFiat.font = UIFont.custom(ofType: .medium, andSize: newSize)
				currentHeaderFiatFontSize = newSize
			}
		}
	}
}



// MARK: - TokenDetailsButtonsCellDelegate

extension TokenDetailsViewController: TokenDetailsViewModelDelegate {
	
	func moreMenu() -> MenuViewController {
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
							self?.dismiss(animated: true)
						} else {
							self?.windowError(withTitle: "error".localized(), description: "Unable to unhide token")
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
							self?.dismiss(animated: true)
							
						} else {
							self?.windowError(withTitle: "error".localized(), description: "Unable to hide token")
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
	
	func setBakerTapped() {
		self.performSegue(withIdentifier: "stake", sender: nil)
	}
	
	func sendTapped() {
		self.performSegue(withIdentifier: "send", sender: nil)
	}
	
	func stakingRewardsInfoTapped() {
		self.performSegue(withIdentifier: "stakingInfo", sender: nil)
	}
	
	func launchExternalBrowser(withURL url: URL) {
		UIApplication.shared.open(url)
	}
}



// MARK: - TokenDetailsButtonsCellDelegate

extension TokenDetailsViewController: TokenDetailsButtonsCellDelegate {
	
	func favouriteTapped() -> Bool? {
		guard let token = TransactionService.shared.sendData.chosenToken else {
			alert(errorWithMessage: "Unable to find token reference")
			return nil
		}
		
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		if viewModel.buttonData?.isFavourited == true {
			if TokenStateService.shared.removeFavourite(forAddress: address, token: token) {
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				viewModel.buttonData?.isFavourited = false
				return false
				
			} else {
				alert(errorWithMessage: "Unable to favorite token")
			}
			
		} else {
			if TokenStateService.shared.addFavourite(forAddress: address, token: token) {
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				viewModel.buttonData?.isFavourited = true
				return true
				
			} else {
				alert(errorWithMessage: "Unable to favorite token")
			}
		}
		
		return nil
	}
	
	func swapTapped() {
		alert(errorWithMessage: "Swapping not setup yet")
	}
}



// MARK: - ChartHostingControllerDelegate

extension TokenDetailsViewController: ChartHostingControllerDelegate {
	
	func didSelectPoint(_ point: ChartViewDataPoint?, ofIndex: Int) {
		self.viewModel.calculatePriceChange(point: point)
		self.updatePriceChange()
		self.headerFiat.text = DependencyManager.shared.coinGeckoService.format(decimal: Decimal(point?.value ?? 0), numberStyle: .currency, maximumFractionDigits: 2)
	}
	
	func didFinishSelectingPoint() {
		self.viewModel.calculatePriceChange(point: nil)
		self.updatePriceChange()
		self.headerFiat.text = viewModel.tokenFiatPrice
	}
}
