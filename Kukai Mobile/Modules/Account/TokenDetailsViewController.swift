//
//  TokenDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import Combine
import KukaiCoreSwift

class TokenDetailsViewController: UIViewController {
	
	@IBOutlet weak var headerIcon: UIImageView!
	@IBOutlet weak var headerSymbol: UILabel!
	@IBOutlet weak var headerFiat: UILabel!
	@IBOutlet weak var headerPriceChange: UILabel!
	@IBOutlet weak var headerPriceChangeArrow: UIImageView!
	@IBOutlet weak var headerPriceChangeDate: UILabel!
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = TokenDetailsViewModel()
	private var cancellable: AnyCancellable?
	
	
	
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
		viewModel.refresh(animate: true)
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
	
	
	
	
	
	
	
	/*
	@IBOutlet weak var tokenHeaderIcon: UIImageView!
	@IBOutlet weak var tokenHeaderSymbolLabel: UILabel!
	@IBOutlet weak var tokenHeaderFiatLabel: UILabel!
	@IBOutlet weak var tokenHeaderPriceChangeLabel: UILabel!
	@IBOutlet weak var tokenHeaderPriceChangeIcon: UIImageView!
	@IBOutlet weak var tokenHeaderPriceDateLabel: UILabel!
	
	@IBOutlet weak var favouriteButton: UIButton!
	@IBOutlet weak var buyButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	
	@IBOutlet weak var chartActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var chartContainer: UIView!
	
	@IBOutlet weak var chartRangeDayButton: UIButton!
	@IBOutlet weak var chartRangeWeekButton: UIButton!
	@IBOutlet weak var chartRangeMonthButton: UIButton!
	@IBOutlet weak var chartRangeYearButton: UIButton!
	
	@IBOutlet weak var balanceAndBakerStackView: UIStackView!
	@IBOutlet weak var tokenBalanceIcon: UIImageView!
	@IBOutlet weak var tokenBalanceLabel: UILabel!
	@IBOutlet weak var tokenValueLabel: UILabel!
	@IBOutlet weak var bakerButton: UIStackView!
	
	@IBOutlet weak var balanceAndStakeStackView: UIStackView!
	
	
	
	
	
	
	
	
	@IBOutlet weak var sendButton: UIButton!
	
	@IBOutlet weak var notStakeLabel: UILabel!
	@IBOutlet weak var stakeButtonStackview: UIStackView!
	@IBOutlet weak var stakeButton: UIButton!
	
	@IBOutlet weak var stakedActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var stakeLabel: UILabel!
	@IBOutlet weak var currentBakerIcon: UIImageView!
	@IBOutlet weak var bakerEditButton: UIButton!
	
	@IBOutlet weak var previousBakerIcon: UIImageView!
	@IBOutlet weak var previousBakerAmountTitleLabel: UILabel!
	@IBOutlet weak var previousBakerAmountLabel: UILabel!
	@IBOutlet weak var previousBakerTimeTitleLabel: UILabel!
	@IBOutlet weak var previousBakerTimeLabel: UILabel!
	@IBOutlet weak var previousBakerCycleTitleLabel: UILabel!
	@IBOutlet weak var previousBakerCycleLabel: UILabel!
	@IBOutlet weak var nextBakerIcon: UIImageView!
	@IBOutlet weak var nextBakerAmountLabel: UILabel!
	@IBOutlet weak var nextBakerTimeLabel: UILabel!
	@IBOutlet weak var nextBakerCycleLabel: UILabel!
	
	@IBOutlet weak var bakerSectionView1: UIStackView!
	@IBOutlet weak var bakerSectionView2: UIView!
	
	@IBOutlet weak var recentActivityHeader: UIStackView!
	@IBOutlet weak var recentActivityActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var noActivityLabel: UILabel!
	var activityGradientsSet = false
	
	@IBOutlet weak var activityItem1: UIView!
	var activityItem1Gradient: CAGradientLayer = CAGradientLayer()
	@IBOutlet weak var activityItem1Icon: UIImageView!
	@IBOutlet weak var activityItem1TypeIcon: UIImageView!
	@IBOutlet weak var activityItem1TypeLabel: UILabel!
	@IBOutlet weak var activityItem1AmountLabel: UILabel!
	@IBOutlet weak var activityItem1ToLabel: UILabel!
	@IBOutlet weak var activityItem1DestinationLabel: UILabel!
	@IBOutlet weak var activityItem1TimeLabel: UILabel!
	
	@IBOutlet weak var activityItem2: UIView!
	var activityItem2Gradient: CAGradientLayer = CAGradientLayer()
	@IBOutlet weak var activityItem2Icon: UIImageView!
	@IBOutlet weak var activityItem2TypeIcon: UIImageView!
	@IBOutlet weak var activityItem2TypeLabel: UILabel!
	@IBOutlet weak var activityItem2AmountLabel: UILabel!
	@IBOutlet weak var activityItem2ToLabel: UILabel!
	@IBOutlet weak var activityItem2DestinationLabel: UILabel!
	@IBOutlet weak var activityItem2TimeLabel: UILabel!
	
	@IBOutlet weak var activityItem3: UIView!
	var activityItem3Gradient: CAGradientLayer = CAGradientLayer()
	@IBOutlet weak var activityItem3Icon: UIImageView!
	@IBOutlet weak var activityItem3TypeIcon: UIImageView!
	@IBOutlet weak var activityItem3TypeLabel: UILabel!
	@IBOutlet weak var activityItem3AmountLabel: UILabel!
	@IBOutlet weak var activityItem3ToLabel: UILabel!
	@IBOutlet weak var activityItem3DestinationLabel: UILabel!
	@IBOutlet weak var activityItem3TimeLabel: UILabel!
	
	@IBOutlet weak var activityItem4: UIView!
	var activityItem4Gradient: CAGradientLayer = CAGradientLayer()
	@IBOutlet weak var activityItem4Icon: UIImageView!
	@IBOutlet weak var activityItem4TypeIcon: UIImageView!
	@IBOutlet weak var activityItem4TypeLabel: UILabel!
	@IBOutlet weak var activityItem4AmountLabel: UILabel!
	@IBOutlet weak var activityItem4ToLabel: UILabel!
	@IBOutlet weak var activityItem4DestinationLabel: UILabel!
	@IBOutlet weak var activityItem4TimeLabel: UILabel!
	
	@IBOutlet weak var activityItem5: UIView!
	var activityItem5Gradient: CAGradientLayer = CAGradientLayer()
	@IBOutlet weak var activityItem5Icon: UIImageView!
	@IBOutlet weak var activityItem5TypeIcon: UIImageView!
	@IBOutlet weak var activityItem5TypeLabel: UILabel!
	@IBOutlet weak var activityItem5AmountLabel: UILabel!
	@IBOutlet weak var activityItem5ToLabel: UILabel!
	@IBOutlet weak var activityItem5DestinationLabel: UILabel!
	@IBOutlet weak var activityItem5TimeLabel: UILabel!
	@IBOutlet weak var recentActivityFooter: UIStackView!
	
	private let viewModel = TokenDetailsViewModel()
	private var cancellable: AnyCancellable?
	private var chartController: ChartHostingController? = nil
	private var allChartData: AllChartData? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
		loadPlaceholderContent()
		setupUI()
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					self?.updateAllSections()
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.updateAllSections()
					//self?.hideLoadingView(completion: nil)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let token = TransactionService.shared.sendData.chosenToken else {
			return
		}
		
		viewModel.loadTokenData(token: token)
		
		viewModel.loadChartData(token: token) { [weak self] result in
			guard let self = self else { return }
			
			switch result {
				case .success(let data):
					self.allChartData = data
					self.viewModel.calculatePriceChange(data: data)
					self.updatePriceChange()
					self.chartRangeDayTapped(self)
					self.chartActivityIndicator.stopAnimating()
					self.chartActivityIndicator.isHidden = true
					self.chartContainer.isHidden = false
					
				case .failure(let error):
					self.alert(errorWithMessage: "\(error)")
			}
		}
		
		viewModel.loadActivityData { [weak self] result in
			guard let _ = try? result.get() else {
				self?.activitySectionEmpty()
				return
			}
			
			if self?.viewModel.activityAvailable == true {
				self?.activitySectionDisplay()
				
			} else {
				self?.activitySectionEmpty()
			}
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if activityGradientsSet {
			activityItem1Gradient.removeFromSuperlayer()
			activityItem2Gradient.removeFromSuperlayer()
			activityItem3Gradient.removeFromSuperlayer()
			activityItem4Gradient.removeFromSuperlayer()
			activityItem5Gradient.removeFromSuperlayer()
			
			if viewModel.activityItems.count >= 1 {
				activityItem1Gradient = activityItem1.addGradientPanelRows(withFrame: activityItem1.bounds)
			}
			
			if viewModel.activityItems.count >= 2 {
				activityItem2Gradient = activityItem2.addGradientPanelRows(withFrame: activityItem2.bounds)
			}
			
			if viewModel.activityItems.count >= 3 {
				activityItem3Gradient = activityItem3.addGradientPanelRows(withFrame: activityItem3.bounds)
			}
			
			if viewModel.activityItems.count >= 4 {
				activityItem4Gradient = activityItem4.addGradientPanelRows(withFrame: activityItem4.bounds)
			}
			
			if viewModel.activityItems.count >= 5 {
				activityItem5Gradient = activityItem5.addGradientPanelRows(withFrame: activityItem5.bounds)
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? ChartHostingController {
			vc.view.backgroundColor = .clear
			chartController = vc
			chartController?.setDelegate(self)
			
		} else if let vc = segue.destination as? TokenContractViewController {
			vc.setup(tokenId: viewModel.token?.tokenId?.description ?? "0", contractAddress: viewModel.token?.tokenContractAddress ?? "")
		}
	}
	
	func loadPlaceholderContent() {
		tokenHeaderSymbolLabel.text = " "
		tokenHeaderFiatLabel.text = " "
		tokenHeaderPriceChangeLabel.text = " "
		tokenHeaderPriceChangeIcon.image = nil
		tokenHeaderPriceDateLabel.text = " "
		
		chartActivityIndicator.startAnimating()
		chartContainer.isHidden = true
		
		tokenBalanceLabel.text = " "
		tokenValueLabel.text = " "
		
		notStakeLabel.isHidden = true
		stakeButtonStackview.isHidden = true
		
		stakeLabel.isHidden = true
		stakedActivityIndicator.isHidden = true
		bakerSectionView1.isHidden = true
		bakerSectionView2.isHidden = true
		
		previousBakerAmountLabel.text = "N/A"
		previousBakerTimeLabel.text = "N/A"
		previousBakerCycleLabel.text = "N/A"
		nextBakerAmountLabel.text = "N/A"
		nextBakerTimeLabel.text = "N/A"
		nextBakerCycleLabel.text = "N/A"
		
		activitySectionLoading()
	}
	
	func setupUI() {
		let normalColor = UIImage.getColoredRectImageWith(color: UIColor.colorNamed("Grey1900").cgColor, andSize: chartRangeDayButton.bounds.size)
		let selectedColor = UIImage.getColoredRectImageWith(color: UIColor.colorNamed("Grey1800").cgColor, andSize: chartRangeDayButton.bounds.size)
		
		chartRangeDayButton.setBackgroundImage(normalColor, for: .normal)
		chartRangeDayButton.setBackgroundImage(selectedColor, for: .selected)
		chartRangeWeekButton.setBackgroundImage(normalColor, for: .normal)
		chartRangeWeekButton.setBackgroundImage(selectedColor, for: .selected)
		chartRangeMonthButton.setBackgroundImage(normalColor, for: .normal)
		chartRangeMonthButton.setBackgroundImage(selectedColor, for: .selected)
		chartRangeYearButton.setBackgroundImage(normalColor, for: .normal)
		chartRangeYearButton.setBackgroundImage(selectedColor, for: .selected)
		
		let _ = sendButton.addGradientButtonPrimary(withFrame: sendButton.bounds)
		if let image = sendButton.imageView {
			sendButton.bringSubviewToFront(image)
		}
		
		let _ = bakerSectionView2.addGradientPanelRows(withFrame: bakerSectionView2.bounds)
	}
	
	func updateAllSections() {
		
		// Header and token balance
		moreButton.menu = menuForMoreButton()
		moreButton.showsMenuAsPrimaryAction = true
		moreButton.isHidden = !viewModel.tokenHasMoreButton
		
		if let tokenURL = viewModel.tokenIconURL {
			MediaProxyService.load(url: tokenURL, to: tokenHeaderIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenHeaderIcon.frame.size)
			MediaProxyService.load(url: tokenURL, to: tokenBalanceIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenBalanceIcon.frame.size)
		} else {
			tokenHeaderIcon.image = viewModel.tokenIcon
			tokenBalanceIcon.image = viewModel.tokenIcon
		}
		
		tokenHeaderSymbolLabel.text = viewModel.tokenSymbol
		tokenHeaderFiatLabel.text = viewModel.tokenFiatPrice
		tokenBalanceLabel.text = viewModel.tokenBalance
		tokenValueLabel.text = viewModel.tokenValue
		favouriteButton.setImage( viewModel.tokenIsFavourited ? UIImage(named: "star-fill") : UIImage(named: "star-no-fill") , for: .normal)
		buyButton.isHidden = !viewModel.tokenCanBePurchased
		
		
		// Baker / rewards
		if viewModel.isStakingPossible && viewModel.isStaked {
			stakeLabel.isHidden = false
			stakedActivityIndicator.isHidden = false
			stakedActivityIndicator.startAnimating()
			
			viewModel.loadBakerData { [weak self] result in
				self?.stakedActivityIndicator.stopAnimating()
				self?.stakedActivityIndicator.isHidden = true
				
				self?.updateBakerRewardsSection()
				self?.bakerSectionView1.isHidden = false
				self?.bakerSectionView2.isHidden = false
			}
		} else if viewModel.isStakingPossible {
			self.notStakeLabel.isHidden = false
			self.stakeButtonStackview.isHidden = false
		}
	}
	
	func updatePriceChange() {
		if viewModel.tokenPriceChange != "" {
			tokenHeaderPriceChangeLabel.text = viewModel.tokenPriceChange
			tokenHeaderPriceChangeLabel.textColor = viewModel.tokenPriceChangeIsUp ? UIColor.colorNamed("Positive900") : UIColor.colorNamed("Caution900")
			tokenHeaderPriceChangeIcon.image = viewModel.tokenPriceChangeIsUp ? UIImage(named: "arrow-up-green") : UIImage(named: "arrow-down-red")
			tokenHeaderPriceDateLabel.text = viewModel.tokenPriceDateText
		}
	}
	
	func updateBakerRewardsSection() {
		bakerEditButton.setTitle(viewModel.bakerText, for: .normal)
		
		MediaProxyService.load(url: viewModel.previousBakerIconURL, to: previousBakerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: previousBakerIcon.frame.size)
		previousBakerAmountTitleLabel.text = viewModel.previousBakerAmountTitle
		previousBakerAmountLabel.text = viewModel.previousBakerAmount
		previousBakerTimeTitleLabel.text = viewModel.previousBakerTimeTitle
		previousBakerTimeLabel.text = viewModel.previousBakerTime
		previousBakerCycleTitleLabel.text = viewModel.previousBakerCycleTitle
		previousBakerCycleLabel.text = viewModel.previousBakerCycle
		
		MediaProxyService.load(url: viewModel.nextBakerIconURL, to: nextBakerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: nextBakerIcon.frame.size)
		MediaProxyService.load(url: viewModel.nextBakerIconURL, to: currentBakerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: currentBakerIcon.frame.size)
		nextBakerAmountLabel.text = viewModel.nextBakerAmount
		nextBakerTimeLabel.text = viewModel.nextBakerTime
		nextBakerCycleLabel.text = viewModel.nextBakerCycle
	}
	
	func activitySectionLoading() {
		recentActivityActivityIndicator.startAnimating()
		noActivityLabel.isHidden = true
		activityItem1.isHidden = true
		activityItem2.isHidden = true
		activityItem3.isHidden = true
		activityItem4.isHidden = true
		activityItem5.isHidden = true
		recentActivityFooter.isHidden = true
	}
	
	func activitySectionEmpty() {
		recentActivityActivityIndicator.stopAnimating()
		recentActivityActivityIndicator.isHidden = true
		noActivityLabel.isHidden = false
	}
	
	func activitySectionDisplay() {
		recentActivityActivityIndicator.stopAnimating()
		recentActivityActivityIndicator.isHidden = true
		noActivityLabel.isHidden = true
		recentActivityFooter.isHidden = false
		
		let groups = viewModel.activityItems
		if groups.count >= 1 {
			activityItem1.isHidden = false
			
			if let tokenURL = viewModel.tokenIconURL {
				MediaProxyService.load(url: tokenURL, to: activityItem1Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: activityItem1Icon.frame.size)
			} else {
				activityItem1Icon.image = viewModel.tokenIcon
			}
			
			activityItem1Gradient = activityItem1.addGradientPanelRows(withFrame: activityItem1.bounds)
			activityItem1TypeIcon.image = groups[0].groupType == .send ? UIImage(named: "arrow-up-right") : UIImage(named: "arrow-down-right")
			activityItem1TypeLabel.text = groups[0].groupType == .send ? "Send" : "Receive"
			activityItem1AmountLabel.text = (groups[0].primaryToken?.amount.description ?? "") + " \(groups[0].primaryToken?.token.symbol ?? "")"
			activityItem1ToLabel.text = groups[0].groupType == .send ? "To:" : "From:"
			activityItem1DestinationLabel.text = destinationFrom(groups[0])
			activityItem1TimeLabel.text = groups[0].transactions[0].date?.timeAgoDisplay() ?? ""
		}
		
		if groups.count >= 2 {
			activityItem2.isHidden = false
			
			if let tokenURL = viewModel.tokenIconURL {
				MediaProxyService.load(url: tokenURL, to: activityItem2Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: activityItem2Icon.frame.size)
			} else {
				activityItem2Icon.image = viewModel.tokenIcon
			}
			
			activityItem2Gradient = activityItem2.addGradientPanelRows(withFrame: activityItem2.bounds)
			activityItem2TypeIcon.image = groups[1].groupType == .send ? UIImage(named: "arrow-up-right") : UIImage(named: "arrow-down-right")
			activityItem2TypeLabel.text = groups[1].groupType == .send ? "Send" : "Receive"
			activityItem2AmountLabel.text = (groups[1].primaryToken?.amount.description ?? "") + " \(groups[1].primaryToken?.token.symbol ?? "")"
			activityItem2ToLabel.text = groups[1].groupType == .send ? "To:" : "From:"
			activityItem2DestinationLabel.text = destinationFrom(groups[1])
			activityItem2TimeLabel.text = groups[1].transactions[0].date?.timeAgoDisplay() ?? ""
		}
		
		if groups.count >= 3 {
			activityItem3.isHidden = false
			
			if let tokenURL = viewModel.tokenIconURL {
				MediaProxyService.load(url: tokenURL, to: activityItem3Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: activityItem3Icon.frame.size)
			} else {
				activityItem3Icon.image = viewModel.tokenIcon
			}
			
			activityItem3Gradient = activityItem3.addGradientPanelRows(withFrame: activityItem3.bounds)
			activityItem3TypeIcon.image = groups[2].groupType == .send ? UIImage(named: "arrow-up-right") : UIImage(named: "arrow-down-right")
			activityItem3TypeLabel.text = groups[2].groupType == .send ? "Send" : "Receive"
			activityItem3AmountLabel.text = (groups[2].primaryToken?.amount.description ?? "") + " \(groups[2].primaryToken?.token.symbol ?? "")"
			activityItem3ToLabel.text = groups[2].groupType == .send ? "To:" : "From:"
			activityItem3DestinationLabel.text = destinationFrom(groups[2])
			activityItem3TimeLabel.text = groups[2].transactions[0].date?.timeAgoDisplay() ?? ""
		}
		
		if groups.count >= 4 {
			activityItem4.isHidden = false
			
			if let tokenURL = viewModel.tokenIconURL {
				MediaProxyService.load(url: tokenURL, to: activityItem4Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: activityItem4Icon.frame.size)
			} else {
				activityItem4Icon.image = viewModel.tokenIcon
			}
			
			activityItem4Gradient = activityItem4.addGradientPanelRows(withFrame: activityItem4.bounds)
			activityItem4TypeIcon.image = groups[3].groupType == .send ? UIImage(named: "arrow-up-right") : UIImage(named: "arrow-down-right")
			activityItem4TypeLabel.text = groups[3].groupType == .send ? "Send" : "Receive"
			activityItem4AmountLabel.text = (groups[3].primaryToken?.amount.description ?? "") + " \(groups[3].primaryToken?.token.symbol ?? "")"
			activityItem4ToLabel.text = groups[3].groupType == .send ? "To:" : "From:"
			activityItem4DestinationLabel.text = destinationFrom(groups[3])
			activityItem4TimeLabel.text = groups[3].transactions[0].date?.timeAgoDisplay() ?? ""
		}
		
		if groups.count >= 5 {
			activityItem5.isHidden = false
			
			if let tokenURL = viewModel.tokenIconURL {
				MediaProxyService.load(url: tokenURL, to: activityItem5Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: activityItem5Icon.frame.size)
			} else {
				activityItem5Icon.image = viewModel.tokenIcon
			}
			
			activityItem5Gradient = activityItem5.addGradientPanelRows(withFrame: activityItem5.bounds)
			activityItem5TypeIcon.image = groups[4].groupType == .send ? UIImage(named: "arrow-up-right") : UIImage(named: "arrow-down-right")
			activityItem5TypeLabel.text = groups[4].groupType == .send ? "Send" : "Receive"
			activityItem5AmountLabel.text = (groups[4].primaryToken?.amount.description ?? "") + " \(groups[4].primaryToken?.token.symbol ?? "")"
			activityItem5ToLabel.text = groups[4].groupType == .send ? "To:" : "From:"
			activityItem5DestinationLabel.text = destinationFrom(groups[4])
			activityItem5TimeLabel.text = groups[4].transactions[0].date?.timeAgoDisplay() ?? ""
		}
		
		activityGradientsSet = true
	}
	
	private func destinationFrom(_ group: TzKTTransactionGroup) -> String {
		if group.groupType == .send {
			return group.transactions[0].target?.alias ?? group.transactions[0].target?.address ?? ""
		} else {
			return group.transactions[0].sender.alias ?? group.transactions[0].sender.address
		}
	}
	
	private func menuForMoreButton() -> UIMenu {
		var actions: [UIAction] = []
		
		if viewModel.token?.isXTZ() == false {
			actions.append(
				UIAction(title: "Token Contract", image: UIImage.unknownToken(), identifier: nil, handler: { [weak self] action in
					self?.performSegue(withIdentifier: "tokenContract", sender: nil)
				})
			)
		}
		
		if viewModel.tokenCanBeHidden {
			if viewModel.tokenIsHidden {
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
							self?.alert(errorWithMessage: "Unable to favorute token")
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
							self?.alert(errorWithMessage: "Unable to favorute token")
						}
					})
				)
			}
		}
		
		if viewModel.tokenCanBeViewedOnline {
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
	
	
	
	// MARK: - Actions
	
	@IBAction func favouriteTapped(_ sender: Any) {
		if !viewModel.tokenCanBeUnFavourited {
			return
		}
		
		guard let token = TransactionService.shared.sendData.chosenToken else {
			alert(errorWithMessage: "Unable to find token reference")
			return
		}
		
		if viewModel.tokenIsFavourited {
			if TokenStateService.shared.removeFavourite(token: token) {
				favouriteButton.setImage(UIImage(named: "star-no-fill") , for: .normal)
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				
			} else {
				alert(errorWithMessage: "Unable to favorute token")
			}
			
		} else {
			if TokenStateService.shared.addFavourite(token: token) {
				favouriteButton.setImage(UIImage(named: "star-fill") , for: .normal)
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				
			} else {
				alert(errorWithMessage: "Unable to favorute token")
			}
		}
	}
	
	@IBAction func buyTapped(_ sender: Any) {
	}
	
	@IBAction func chartRangeDayTapped(_ sender: Any) {
		guard let allChartData = allChartData else { return }
		
		if !chartRangeDayButton.isSelected {
			chartController?.setData(allChartData.day)
			
			chartRangeDayButton.isSelected = true
			chartRangeWeekButton.isSelected = false
			chartRangeMonthButton.isSelected = false
			chartRangeYearButton.isSelected = false
		}
	}
	
	@IBAction func chartRangeWeekTapped(_ sender: Any) {
		guard let allChartData = allChartData else { return }
		
		if !chartRangeWeekButton.isSelected {
			chartController?.setData(allChartData.week)
			
			chartRangeDayButton.isSelected = false
			chartRangeWeekButton.isSelected = true
			chartRangeMonthButton.isSelected = false
			chartRangeYearButton.isSelected = false
		}
	}
	
	@IBAction func chartRangeMonthTapped(_ sender: Any) {
		guard let allChartData = allChartData else { return }
		
		if !chartRangeMonthButton.isSelected {
			chartController?.setData(allChartData.month)
			
			chartRangeDayButton.isSelected = false
			chartRangeWeekButton.isSelected = false
			chartRangeMonthButton.isSelected = true
			chartRangeYearButton.isSelected = false
		}
	}
	
	@IBAction func chartRangeYearTapped(_ sender: Any) {
		guard let allChartData = allChartData else { return }
		
		if !chartRangeYearButton.isSelected {
			chartController?.setData(allChartData.year)
			
			chartRangeDayButton.isSelected = false
			chartRangeWeekButton.isSelected = false
			chartRangeMonthButton.isSelected = false
			chartRangeYearButton.isSelected = true
		}
	}
	
	@IBAction func selectedBakerTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.performSegue(withIdentifier: "stake", sender: nil)
		}
	}
	
	@IBAction func stakeButtonTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.performSegue(withIdentifier: "stake", sender: nil)
		}
	}
	
	@IBAction func editBakerButotnTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.performSegue(withIdentifier: "stake", sender: nil)
		}
	}
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.sendButtonTapped()
		}
	}
	
	@IBAction func viewAllActivity(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.selectedIndex = 3
		}
	}
	
	@IBAction func activityItem1More(_ sender: Any) {
		if let url = URL(string: "https://tzkt.io/\(viewModel.activityItems[0].transactions[0].hash)") {
			UIApplication.shared.open(url, completionHandler: nil)
		}
	}
	
	@IBAction func activityItem2More(_ sender: Any) {
		if let url = URL(string: "https://tzkt.io/\(viewModel.activityItems[1].transactions[0].hash)") {
			UIApplication.shared.open(url, completionHandler: nil)
		}
	}
	
	@IBAction func activityItem3More(_ sender: Any) {
		if let url = URL(string: "https://tzkt.io/\(viewModel.activityItems[2].transactions[0].hash)") {
			UIApplication.shared.open(url, completionHandler: nil)
		}
	}
	
	@IBAction func activityItem4More(_ sender: Any) {
		if let url = URL(string: "https://tzkt.io/\(viewModel.activityItems[3].transactions[0].hash)") {
			UIApplication.shared.open(url, completionHandler: nil)
		}
	}
	
	@IBAction func activityItem5More(_ sender: Any) {
		if let url = URL(string: "https://tzkt.io/\(viewModel.activityItems[4].transactions[0].hash)") {
			UIApplication.shared.open(url, completionHandler: nil)
		}
	}
	*/
