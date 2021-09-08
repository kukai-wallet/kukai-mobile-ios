//
//  HomeWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import Combine

class HomeWalletViewController: UIViewController {

	@IBOutlet weak var headerBackgroundView: UIView!
	@IBOutlet weak var bottomBackgroundView: UIView!
	
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var sendButton: UIButton!
	@IBOutlet weak var receiveButton: UIButton!
	@IBOutlet weak var buyButton: UIButton!
	
	@IBOutlet weak var tokensSegmentedButton: UIButton!
	@IBOutlet weak var nftsSegmentedButton: UIButton!
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = HomeWalletViewModel()
	private var cancellable: AnyCancellable?
	private var refreshControl = UIRefreshControl()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		
		refreshControl.addAction(UIAction(handler: { [weak self] action in
			self?.viewModel.refresh(animate: true)
		}), for: .valueChanged)
		tableView.refreshControl = refreshControl
		
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					if !(self?.refreshControl.isRefreshing ?? false) {
						self?.showActivity(clearBackground: false)
					}
					
				case .failure(_, let errorString):
					self?.hideActivity()
					self?.refreshControl.endRefreshing()
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideActivity()
					self?.refreshControl.endRefreshing()
					self?.addressLabel.text = self?.viewModel.walletAddress
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		setupUI()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		viewModel.refresh(animate: true)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		bottomBackgroundView.roundCorners(corners: [.topLeft, .topRight], radius: 36)
	}
	
	func setupUI() {
		headerBackgroundView.maskToBounds = true
		
		let containerWidth = headerBackgroundView.frame.size.width
		let containerHeight = headerBackgroundView.frame.size.height
		
		
		// Large Gradient circle
		let lightBlue = UIColor(named: "gradient-light") ?? UIColor.white
		let mediumBlue = UIColor(named: "gradient-medium") ?? UIColor.black
		
		let bigGradientCircle = CGRect(x: headerBackgroundView.frame.origin.x - 100,
									   y: headerBackgroundView.frame.origin.y - 50,
									   width: containerWidth * 1.25,
									   height: containerHeight * 1.25)
		
		let bigGradientCirclePath = UIBezierPath(ovalIn: bigGradientCircle)
		let bigGradientCircleShapeLayer = CAShapeLayer()
		bigGradientCircleShapeLayer.path = bigGradientCirclePath.cgPath
		
		let gradientLayer = CAGradientLayer()
		gradientLayer.startPoint = CGPoint(x: 0.2, y: 0.0)
		gradientLayer.endPoint = CGPoint(x: 0.7, y: 0.4)
		gradientLayer.colors = [lightBlue.cgColor, mediumBlue.cgColor]
		gradientLayer.frame = headerBackgroundView.bounds
		gradientLayer.mask = bigGradientCircleShapeLayer
		
		headerBackgroundView.layer.insertSublayer(gradientLayer, at: 0)
		
		
		// Curvy diagonal line
		let curveStartPoint = CGPoint(x: 0, y: containerHeight * 0.55)
		let curveEndPoint = CGPoint(x: containerWidth, y: containerHeight * 0.1)
		
		let curvyPath = UIBezierPath()
		curvyPath.move(to: curveEndPoint)
		curvyPath.addLine(to: CGPoint(x: containerWidth, y: containerHeight))
		curvyPath.addLine(to: CGPoint(x: 0, y: containerHeight))
		curvyPath.addLine(to: curveStartPoint)
		curvyPath.addCurve(to: curveEndPoint,
						   controlPoint1: CGPoint(x: curveStartPoint.x + containerWidth * 0.2,
											 y: curveStartPoint.y - containerHeight * 0.25),
						   controlPoint2: CGPoint(x: curveEndPoint.x - containerWidth * 0.2,
											 y: curveEndPoint.y + containerHeight * 0.5))
		
		let curvyShapeLayer = CAShapeLayer()
		curvyShapeLayer.path = curvyPath.cgPath
		
		let gradientLayer2 = CAGradientLayer()
		gradientLayer.startPoint = CGPoint(x: 0.2, y: 0.0)
		gradientLayer.endPoint = CGPoint(x: 0.7, y: 0.4)
		gradientLayer2.colors = [lightBlue.cgColor, mediumBlue.cgColor]
		gradientLayer2.frame = headerBackgroundView.bounds
		gradientLayer2.mask = curvyShapeLayer
		
		headerBackgroundView.layer.insertSublayer(gradientLayer2, at: 1)
		
		
		// Black transparent circle
		let bigAlphaBlackCircle = CGRect(x: headerBackgroundView.frame.origin.x - 250,
										 y: headerBackgroundView.frame.origin.y + 100,
								   width: headerBackgroundView.frame.size.width,
								   height: headerBackgroundView.frame.size.width)
		
		let bigAlphaBlackPath = UIBezierPath(ovalIn: bigAlphaBlackCircle)
		let bigAlphaBlackPathShapeLayer = CAShapeLayer()
		bigAlphaBlackPathShapeLayer.path = bigAlphaBlackPath.cgPath
		bigAlphaBlackPathShapeLayer.fillColor = UIColor.black.cgColor
		bigAlphaBlackPathShapeLayer.opacity = 0.05
		
		headerBackgroundView.layer.insertSublayer(bigAlphaBlackPathShapeLayer, at: 2)
		unselect(button: nftsSegmentedButton)
		
		sendButton.layer.borderColor = UIColor(named: "button-primary-border")?.cgColor ?? UIColor.clear.cgColor
		sendButton.layer.borderWidth = 1
		sendButton.layer.cornerRadius = 16
		
		receiveButton.layer.borderColor = UIColor(named: "button-primary-border")?.cgColor ?? UIColor.clear.cgColor
		receiveButton.layer.borderWidth = 1
		receiveButton.layer.cornerRadius = 16
		
		buyButton.layer.borderColor = UIColor(named: "button-primary-border")?.cgColor ?? UIColor.clear.cgColor
		buyButton.layer.borderWidth = 1
		buyButton.layer.cornerRadius = 16
	}
	
	func unselect(button: UIButton) {
		button.backgroundColor = UIColor(named: "segmented-button-background-unselected") ?? UIColor.black
		button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .light)
		
		if button.title(for: .normal) == "Tokens" {
			button.roundCorners(corners: [.bottomRight], radius: 16)
		} else {
			button.roundCorners(corners: [.bottomLeft], radius: 16)
		}
	}
	
	func select(button: UIButton) {
		button.backgroundColor = UIColor(named: "segmented-button-background") ?? UIColor.white
		button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
	}
	
	@IBAction func tokensButtonTapped(_ sender: Any) {
		select(button: tokensSegmentedButton)
		unselect(button: nftsSegmentedButton)
		
		viewModel.tokensSelected = true
		viewModel.updateTableView(animate: true)
	}
	
	@IBAction func nftsButtonTapped(_ sender: Any) {
		select(button: nftsSegmentedButton)
		unselect(button: tokensSegmentedButton)
		
		viewModel.tokensSelected = false
		viewModel.updateTableView(animate: true)
	}
}
