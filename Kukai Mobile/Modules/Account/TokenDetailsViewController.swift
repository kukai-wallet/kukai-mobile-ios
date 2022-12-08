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
	private var firstLoad = true
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
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
					self?.alert(withTitle: "Error", andMessage: errorString)
					
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
			MediaProxyService.load(url: tokenURL, to: headerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: headerIcon.frame.size)
			
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
			let color = UIColor.colorNamed("Positive900")
			var image = UIImage(named: "arrow-up")
			image = image?.resizedImage(Size: CGSize(width: 11, height: 11))
			image = image?.withTintColor(color)
			
			headerPriceChangeArrow.image = image
			headerPriceChange.textColor = color
			
		} else {
			let color = UIColor.colorNamed("Grey1100")
			var image = UIImage(named: "arrow-down")
			image = image?.resizedImage(Size: CGSize(width: 11, height: 11))
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
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if viewModel.isIndexActivityViewMore(indexPath) {
			let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
			
			self.dismiss(animated: true) {
				homeTabController?.selectedIndex = 3
			}
		}
	}
	
	
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		guard headerAnimatorStarted == false else {
			return
		}
		
		// make sure we only run this ocne
		headerAnimatorStarted = true
		
		
		// Set what we want the constraints to be
		self.headerIconWidthConstraint.constant = 28
		self.headerIconHeightConstraint.constant = 28
		
		// Labels are weird, grab properties to manipulate later
		let labelLayer = self.headerFiat.layer
		let position = labelLayer.frame.origin
		labelLayer.anchorPoint = CGPoint(x: 0, y: 0)
		labelLayer.position = position
		
		
		// Setup property animator
		headerAnimator = UIViewPropertyAnimator(duration: 3, curve: .easeOut, animations: { [weak self] in
			
			// Refresh consttraints
			self?.view.layoutIfNeeded()
			
			// Update label
			labelLayer.setAffineTransform(CGAffineTransform(scaleX: 0.6, y: 0.6))
			labelLayer.position = CGPoint(x: self?.headerSymbol.frame.minX ?? 0, y: self?.headerSymbol.frame.maxY ?? 0)
			
			// Alpha the rest
			self?.headerPriceChange.alpha = 0
			self?.headerPriceChangeDate.alpha = 0
			self?.headerPriceChangeArrow.alpha = 0
		})
		
		headerAnimator.startAnimation()
		headerAnimator.pauseAnimation()
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		
		// Every move event, compute how much things should change
		let fraction = self.tableView.contentOffset.y / 100
		if fraction <= 1 {
			headerAnimator.fractionComplete = fraction
			
		} else {
			// For some reason, after a point, label jumps to somwhere else, need to avoid that
			self.headerFiat.layer.position = CGPoint(x: self.headerSymbol.frame.minX, y: self.headerSymbol.frame.maxY)
		}
	}
}



// MARK: - TokenDetailsButtonsCellDelegate

extension TokenDetailsViewController: TokenDetailsViewModelDelegate {
	
	func moreMenu() -> UIMenu {
		var actions: [UIAction] = []
		
		if viewModel.token?.isXTZ() == false {
			actions.append(
				UIAction(title: "Token Contract", image: UIImage.unknownToken(), identifier: nil, handler: { [weak self] action in
					self?.performSegue(withIdentifier: "tokenContract", sender: nil)
				})
			)
		}
		
		if viewModel.buttonData?.canBeHidden == true {
			if viewModel.buttonData?.isHidden == true {
				actions.append(
					UIAction(title: "Unhide Token", image: UIImage(named: "context-menu-unhide"), identifier: nil, handler: { [weak self] action in
						guard let token = TransactionService.shared.sendData.chosenToken else {
							self?.alert(errorWithMessage: "Unable to find token reference")
							return
						}
						
						if TokenStateService.shared.removeHidden(token: token) {
							DependencyManager.shared.balanceService.updateTokenStates()
							DependencyManager.shared.accountBalancesDidUpdate = true
							self?.dismiss(animated: true)
						} else {
							self?.alert(errorWithMessage: "Unable to unhide token")
						}
					})
				)
			} else {
				actions.append(
					UIAction(title: "Hide Token", image: UIImage(named: "context-menu-hidden"), identifier: nil, handler: { [weak self] action in
						guard let token = TransactionService.shared.sendData.chosenToken else {
							self?.alert(errorWithMessage: "Unable to find token reference")
							return
						}
						
						if TokenStateService.shared.addHidden(token: token) {
							DependencyManager.shared.balanceService.updateTokenStates()
							DependencyManager.shared.accountBalancesDidUpdate = true
							self?.dismiss(animated: true)
							
						} else {
							self?.alert(errorWithMessage: "Unable to hide token")
						}
					})
				)
			}
		}
		
		if viewModel.buttonData?.canBeViewedOnline == true {
			actions.append(
				UIAction(title: "View on Blockchain", image: UIImage(named: "external-link"), identifier: nil, handler: { [weak self] action in
					if let contract = self?.viewModel.token?.tokenContractAddress, let url = URL(string: "https://better-call.dev/mainnet/\(contract)") {
						UIApplication.shared.open(url, completionHandler: nil)
					}
				})
			)
		}
		
		return UIMenu(title: "", image: nil, identifier: nil, options: [], children: actions)
	}
	
	func setBakerTapped() {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.performSegue(withIdentifier: "stake", sender: nil)
		}
	}
	
	func sendTapped() {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.sendButtonTapped()
		}
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
		
		if viewModel.buttonData?.isFavourited == true {
			if TokenStateService.shared.removeFavourite(token: token) {
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				viewModel.buttonData?.isFavourited = false
				return false
				
			} else {
				alert(errorWithMessage: "Unable to favourite token")
			}
			
		} else {
			if TokenStateService.shared.addFavourite(token: token) {
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				viewModel.buttonData?.isFavourited = true
				return true
				
			} else {
				alert(errorWithMessage: "Unable to favourite token")
			}
		}
		
		return nil
	}
	
	func buyTapped() {
		alert(errorWithMessage: "Purchases not setup yet")
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
