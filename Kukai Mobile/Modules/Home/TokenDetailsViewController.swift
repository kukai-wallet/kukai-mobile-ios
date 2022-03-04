//
//  TokenDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import Charts

class TokenDetailsViewController: UIViewController {

	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var lineChartView: LineChartView!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var fiatLabel: UILabel!
	@IBOutlet weak var rateLabel: UILabel!
	
	private let viewModel = TokenDetailsViewModel()
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
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let token = TransactionService.shared.sendData.chosenToken else {
			return
		}
		
		viewModel.loadOfflineData(token: token)
		
		self.symbolLabel.text = viewModel.symbol
		self.balanceLabel.text = viewModel.balance
		self.fiatLabel.text = viewModel.fiat
		self.rateLabel.text = viewModel.rate
		
		
		viewModel.loadChartData(token: token) { [weak self] result in
			guard let self = self else { return }
			
			switch result {
				case .success(let data):
					self.allChartData = data
					self.segmentedControlChanged(self)
					
				case .failure(let error):
					self.alert(errorWithMessage: "\(error)")
			}
		}
	}
	
	@IBAction func segmentedControlChanged(_ sender: Any) {
		guard let allChartData = allChartData else {
			return
		}
		
		var dataSet: DataSet = DataSet(data: LineChartDataSet(entries: [], label: ""), upperLimit: ChartLimitLine(), lowerLimit: ChartLimitLine())
		
		if segmentedControl.selectedSegmentIndex == 0 {
			dataSet = allChartData.day
			
		} else if segmentedControl.selectedSegmentIndex == 1 {
			dataSet = allChartData.week
			
		} else if segmentedControl.selectedSegmentIndex == 2 {
			dataSet = allChartData.month
			
		} else if segmentedControl.selectedSegmentIndex == 3 {
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
	
	@IBAction func sendTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.sendButtonTapped(self)
		}
	}
}

extension TokenDetailsViewController: ChartViewDelegate {
	
}
