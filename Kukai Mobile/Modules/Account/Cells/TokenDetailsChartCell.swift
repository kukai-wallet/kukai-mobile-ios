//
//  TokenDetailsChartCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

enum TokenDetailsChartCellRange: Int {
	case day
	case week
	case month
	case year
}

protocol TokenDetailsChartCellDelegate: AnyObject {
	func chartRangeChanged(to: TokenDetailsChartCellRange)
}

class TokenDetailsChartCell: UITableViewCell {
	
	@IBOutlet weak var chartContainer: UIView!
	@IBOutlet weak var activityView: UIActivityIndicatorView!
	
	@IBOutlet weak var dayButton: UIButton!
	@IBOutlet weak var weekButton: UIButton!
	@IBOutlet weak var monthButton: UIButton!
	@IBOutlet weak var yearButton: UIButton!
	
	private weak var delegate: TokenDetailsChartCellDelegate? = nil
	private weak var chartController: ChartHostingController? = nil
	private var allChartData: AllChartData? = nil
	private let chartButtonBackgroundColor = UIColor.colorNamed("BtnMicroB1")
	private let chartButtonBorderColor = UIColor.colorNamed("BtnStrokeMicroB1")
	private let chartButtonSelectedBackgroundColor = UIColor.colorNamed("BtnMicro1")
	private let chartButtonSelectedBorderColor = UIColor.colorNamed("BtnStrokeMicro1")
	
	
	func setup() {
		activityView.startAnimating()
		activityView.isHidden = false
		
		dayButton.backgroundColor = chartButtonBackgroundColor
		weekButton.backgroundColor = chartButtonBackgroundColor
		monthButton.backgroundColor = chartButtonBackgroundColor
		yearButton.backgroundColor = chartButtonBackgroundColor
	}
	
	func setup(delegate: TokenDetailsChartCellDelegate?, chartController: ChartHostingController, allChartData: AllChartData) {
		activityView.stopAnimating()
		activityView.isHidden = true
		
		self.delegate = delegate
		self.chartController = chartController
		self.chartContainer?.backgroundColor = .clear
		
		if let cView = self.chartController?.view {
			cView.backgroundColor = .clear
			self.chartContainer?.addSubview(cView)
			
			cView.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				cView.leadingAnchor.constraint(equalTo: self.chartContainer.leadingAnchor),
				cView.trailingAnchor.constraint(equalTo: self.chartContainer.trailingAnchor),
				cView.topAnchor.constraint(equalTo: self.chartContainer.topAnchor),
				cView.bottomAnchor.constraint(equalTo: self.chartContainer.bottomAnchor)
			])
		}
		
		self.allChartData = allChartData
		self.dayButtonTapped(self)
	}
	
	@IBAction func dayButtonTapped(_ sender: Any) {
		guard let allChartData = allChartData else { return }
		
		if !dayButton.isSelected {
			self.chartController?.setData(allChartData.day)
			self.delegate?.chartRangeChanged(to: .day)
			
			dayButton.isSelected = true
			dayButton.backgroundColor = chartButtonSelectedBackgroundColor
			dayButton.borderColor = chartButtonSelectedBorderColor
			weekButton.isSelected = false
			weekButton.backgroundColor = chartButtonBackgroundColor
			weekButton.borderColor = chartButtonBorderColor
			monthButton.isSelected = false
			monthButton.backgroundColor = chartButtonBackgroundColor
			monthButton.borderColor = chartButtonBorderColor
			yearButton.isSelected = false
			yearButton.backgroundColor = chartButtonBackgroundColor
			yearButton.borderColor = chartButtonBorderColor
		}
	}
	
	@IBAction func weekButtonTapped(_ sender: Any) {
		guard let allChartData = allChartData else { return }
		
		if !weekButton.isSelected {
			self.chartController?.setData(allChartData.week)
			self.delegate?.chartRangeChanged(to: .week)
			
			dayButton.isSelected = false
			dayButton.backgroundColor = chartButtonBackgroundColor
			dayButton.borderColor = chartButtonBorderColor
			weekButton.isSelected = true
			weekButton.backgroundColor = chartButtonSelectedBackgroundColor
			weekButton.borderColor = chartButtonSelectedBorderColor
			monthButton.isSelected = false
			monthButton.backgroundColor = chartButtonBackgroundColor
			monthButton.borderColor = chartButtonBorderColor
			yearButton.isSelected = false
			yearButton.backgroundColor = chartButtonBackgroundColor
			yearButton.borderColor = chartButtonBorderColor
		}
	}
	
	@IBAction func monthButtonTapped(_ sender: Any) {
		guard let allChartData = allChartData else { return }
		
		if !monthButton.isSelected {
			self.chartController?.setData(allChartData.month)
			self.delegate?.chartRangeChanged(to: .month)
			
			dayButton.isSelected = false
			dayButton.backgroundColor = chartButtonBackgroundColor
			dayButton.borderColor = chartButtonBorderColor
			weekButton.isSelected = false
			weekButton.backgroundColor = chartButtonBackgroundColor
			weekButton.borderColor = chartButtonBorderColor
			monthButton.isSelected = true
			monthButton.backgroundColor = chartButtonSelectedBackgroundColor
			monthButton.borderColor = chartButtonSelectedBorderColor
			yearButton.isSelected = false
			yearButton.backgroundColor = chartButtonBackgroundColor
			yearButton.borderColor = chartButtonBorderColor
		}
	}
	
	@IBAction func yearButtonTapped(_ sender: Any) {
		guard let allChartData = allChartData else { return }
		
		if !yearButton.isSelected {
			self.chartController?.setData(allChartData.year)
			self.delegate?.chartRangeChanged(to: .year)
			
			dayButton.isSelected = false
			dayButton.backgroundColor = chartButtonBackgroundColor
			dayButton.borderColor = chartButtonBorderColor
			weekButton.isSelected = false
			weekButton.backgroundColor = chartButtonBackgroundColor
			weekButton.borderColor = chartButtonBorderColor
			monthButton.isSelected = false
			monthButton.backgroundColor = chartButtonBackgroundColor
			monthButton.borderColor = chartButtonBorderColor
			yearButton.isSelected = true
			yearButton.backgroundColor = chartButtonSelectedBackgroundColor
			yearButton.borderColor = chartButtonSelectedBorderColor
		}
	}
}
