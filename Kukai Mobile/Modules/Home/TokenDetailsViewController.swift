//
//  TokenDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import Charts
import Combine
import KukaiCoreSwift

class TokenDetailsViewController: UIViewController {
	
	@IBOutlet weak var tokenHeaderIcon: UIImageView!
	@IBOutlet weak var tokenHeaderLabel: UILabel!
	@IBOutlet weak var tokenHeaderPlusButton: UIButton!
	
	@IBOutlet weak var lineChartView: LineChartView!
	@IBOutlet weak var chartRangeSegmented: UISegmentedControl!
	
	@IBOutlet weak var tokenBalanceIcon: UIImageView!
	@IBOutlet weak var tokenBalanceLabel: UILabel!
	@IBOutlet weak var tokenValueLabel: UILabel!
	
	@IBOutlet weak var bakerLabel: UILabel!
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
	@IBOutlet weak var stakeButton: UIButton!
	
	private let viewModel = TokenDetailsViewModel()
	private var cancellable: AnyCancellable?
	private var allChartData: AllChartData? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		lineChartView.delegate = self
		lineChartView.chartDescription.enabled = false
		lineChartView.dragEnabled = false
		lineChartView.setScaleEnabled(false)
		lineChartView.pinchZoomEnabled = false
		lineChartView.drawMarkers = false
		lineChartView.highlightPerTapEnabled = false
		
		lineChartView.rightAxis.enabled = false
		lineChartView.rightAxis.drawGridLinesEnabled = false
		
		lineChartView.leftAxis.enabled = true
		lineChartView.leftAxis.drawLabelsEnabled = false
		lineChartView.leftAxis.drawZeroLineEnabled = false
		lineChartView.leftAxis.drawAxisLineEnabled = false
		lineChartView.leftAxis.drawGridLinesEnabled = false
		lineChartView.leftAxis.drawLimitLinesBehindDataEnabled = true
		
		lineChartView.xAxis.drawGridLinesEnabled = false
		lineChartView.xAxis.drawLabelsEnabled = false
		lineChartView.xAxis.drawAxisLineEnabled = false
		lineChartView.drawGridBackgroundEnabled = false
		
		lineChartView.legend.enabled = false
		
		loadPlaceholderContent()
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.updateAllSections()
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.updateAllSections()
					self?.hideLoadingView(completion: nil)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let token = TransactionService.shared.sendData.chosenToken else {
			return
		}
		
		viewModel.loadTokenAndBakerData(token: token)
		viewModel.loadChartData(token: token) { [weak self] result in
			guard let self = self else { return }
			
			switch result {
				case .success(let data):
					self.allChartData = data
					self.chartRangeChanged(self)
					
				case .failure(let error):
					self.alert(errorWithMessage: "\(error)")
			}
		}
	}
	
	func loadPlaceholderContent() {
		tokenHeaderLabel.text = ""
		tokenBalanceLabel.text = ""
		tokenValueLabel.text = ""
		
		previousBakerAmountLabel.text = "N/A"
		previousBakerTimeLabel.text = "N/A"
		previousBakerCycleLabel.text = "N/A"
		nextBakerAmountLabel.text = "N/A"
		nextBakerTimeLabel.text = "N/A"
		nextBakerCycleLabel.text = "N/A"
	}
	
	func updateAllSections() {
		
		// Header and token balance
		if let tokenURL = viewModel.tokenIconURL {
			MediaProxyService.load(url: tokenURL, to: tokenHeaderIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenHeaderIcon.frame.size)
			MediaProxyService.load(url: tokenURL, to: tokenBalanceIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenBalanceIcon.frame.size)
		} else {
			tokenHeaderIcon.image = viewModel.tokenIcon
			tokenBalanceIcon.image = viewModel.tokenIcon
		}
		
		tokenHeaderPlusButton.isHidden = !viewModel.showBuyButton
		
		tokenHeaderLabel.text = viewModel.tokenSymbol
		tokenBalanceLabel.text = viewModel.tokenBalance
		tokenValueLabel.text = viewModel.tokenValue
		
		
		// Baker and baker rewards
		showBakerRewardsSection(viewModel.showBakerRewardsSection)
		showStakeButton(viewModel.showStakeButton)
		
		bakerLabel.text = viewModel.bakerText
		stakeButton.setTitle(viewModel.stakeButtonTitle, for: .normal)
		
		MediaProxyService.load(url: viewModel.previousBakerIconURL, to: previousBakerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: previousBakerIcon.frame.size)
		previousBakerAmountTitleLabel.text = viewModel.previousBakerAmountTitle
		previousBakerAmountLabel.text = viewModel.previousBakerAmount
		previousBakerTimeTitleLabel.text = viewModel.previousBakerTimeTitle
		previousBakerTimeLabel.text = viewModel.previousBakerTime
		previousBakerCycleTitleLabel.text = viewModel.previousBakerCycleTitle
		previousBakerCycleLabel.text = viewModel.previousBakerCycle
		
		MediaProxyService.load(url: viewModel.nextBakerIconURL, to: nextBakerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: nextBakerIcon.frame.size)
		nextBakerAmountLabel.text = viewModel.nextBakerAmount
		nextBakerTimeLabel.text = viewModel.nextBakerTime
		nextBakerCycleLabel.text = viewModel.nextBakerCycle
	}
	
	func showBakerRewardsSection(_ show: Bool) {
		self.bakerSectionView1.isHidden = !show
		self.bakerSectionView2.isHidden = !show
	}
	
	func showStakeButton(_ show: Bool) {
		self.stakeButton.isHidden = !show
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func chartRangeChanged(_ sender: Any) {
		guard let allChartData = allChartData else {
			return
		}
		
		var dataSet: DataSet = DataSet(data: LineChartDataSet(entries: [], label: ""), upperLimit: ChartLimitLine(), lowerLimit: ChartLimitLine())
		
		if chartRangeSegmented.selectedSegmentIndex == 0 {
			dataSet = allChartData.day
			
		} else if chartRangeSegmented.selectedSegmentIndex == 1 {
			dataSet = allChartData.week
			
		} else if chartRangeSegmented.selectedSegmentIndex == 2 {
			dataSet = allChartData.month
			
		} else if chartRangeSegmented.selectedSegmentIndex == 3 {
			dataSet = allChartData.year
		}
		
		let lineChartData = LineChartData(dataSet: dataSet.data)
		lineChartData.setDrawValues(false)
		
		self.lineChartView.data = lineChartData
		self.lineChartView.leftAxis.removeAllLimitLines()
		self.lineChartView.leftAxis.addLimitLine(dataSet.upperLimit)
		self.lineChartView.leftAxis.addLimitLine(dataSet.lowerLimit)
		
		let space = (lineChartData.yMax - lineChartData.yMin) * 0.15
		self.lineChartView.leftAxis.axisMaximum = lineChartData.yMax + space
		self.lineChartView.leftAxis.axisMinimum = lineChartData.yMin - space
		
		self.lineChartView.notifyDataSetChanged()
	}
	
	@IBAction func stakeButtonTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.performSegue(withIdentifier: "stake", sender: nil)
		}
	}
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.sendButtonTapped(self)
		}
	}
}

extension TokenDetailsViewController: ChartViewDelegate {
	
}
