//
//  TokenDetailsChartView.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/11/2022.
//

import UIKit
import SwiftUI
import Charts


public struct ChartViewDataPoint: Hashable, Identifiable, Equatable {
	public var value: Double
	public var date: Date
	public var id = UUID()
}



// MARK: - UIKit

protocol ChartHostingControllerDelegate: AnyObject {
	func didSelectPoint(_ point: ChartViewDataPoint?, ofIndex: Int)
	func didFinishSelectingPoint()
}

class ChartViewIntegrationService: ObservableObject {
	@Published var data: [ChartViewDataPoint] = [] {
		didSet {
			maxData = data.max(by: { $0.value < $1.value })
			minData = data.max(by: { $0.value > $1.value })
			
			// We want the background gradient to overflow the bottom value a little so it covers the bottom annotation
			// because we set the Yaxis domain to be from min -> max, we need to trigger this bleed based off
			// a percentage of, the difference between max and min, so its consistent in size for any data set
			if let max = maxData, let min = minData {
				bottomGradientBleedValue = min.value - ((max.value - min.value) * 0.25)
			}
		}
	}
	var maxData: ChartViewDataPoint? = nil
	var minData: ChartViewDataPoint? = nil
	var bottomGradientBleedValue: Double = 0
	var delegate: ChartHostingControllerDelegate? = nil
}

class ChartHostingController: UIHostingController<AnyView> {
	
	private let integration = ChartViewIntegrationService()
	private let chartView: some View = ChartView().backgroundStyle(.clear)
	
	required init?(coder: NSCoder) {
		super.init(coder: coder, rootView: AnyView(chartView.environmentObject(integration)))
	}
	
	init() {
		super.init(rootView: AnyView(chartView.environmentObject(integration)))
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	public func setDelegate(_ delegate: ChartHostingControllerDelegate?) {
		integration.delegate = delegate
	}
	
	public func setData(_ data: [ChartViewDataPoint]) {
		var d = data
		
		if d.count == 1 {
			let sameValue = d[0].value
			let oneSeconLaterValue = Date(timeIntervalSince1970: d[0].date.timeIntervalSince1970 + 1)
			d.append(ChartViewDataPoint(value: sameValue, date: oneSeconLaterValue, id: UUID()))
		}
		
		integration.data = d
	}
}



// MARK: - SwiftUI

struct ChartView: View {
	
	@State private var selectedData: ChartViewDataPoint?
	@State private var selectedDataPoint: CGPoint = CGPoint(x: 0, y: 0)
	@State private var maxDataPoint: CGPoint = CGPoint(x: 0, y: 0)
	@State private var minDataPoint: CGPoint = CGPoint(x: 0, y: 0)
	@State private var isDragging: Bool = false
	
	@EnvironmentObject private var integration: ChartViewIntegrationService
	
	private let gradient = LinearGradient(
		gradient: Gradient(
			colors: [
				Color(UIColor.colorNamed("gradGraphToken-1")),
				Color(UIColor.colorNamed("gradGraphToken-2"))
			]
		),
		startPoint: .top,
		endPoint: .bottom
	)
	
	var body: some View {
		VStack(spacing: 4) {
			if integration.data.count > 0 {
				topAnnotationView
				chart
				bottomAnnotationView
			} else {
				Text("No data available")
					.font(Font(UIFont.custom(ofType: .bold, andSize: 12)))
					.foregroundStyle(Color(UIColor.colorNamed("Txt8")))
			}
			
		}.background(.clear)
	}
	
	private var topAnnotationView: some View {
		VStack {
			ZStack(alignment: .topLeading) {
				GeometryReader { geo in
					
					let widthOfString = doubleFormatter(integration.maxData?.value).widthOfString(usingFont: UIFont.custom(ofType: .bold, andSize: 12))
					var boxOffset: CGFloat = 4
					
					if maxDataPoint.y == minDataPoint.y {
						boxOffset = CGFloat(geo.size.width - widthOfString)
					} else {
						boxOffset = max(4, min(geo.size.width - widthOfString, maxDataPoint.x - widthOfString / 2))
					}
					
					return VStack(alignment: .trailing) {
						Text(doubleFormatter((integration.maxData?.value ?? 0)))
							.font(Font(UIFont.custom(ofType: .bold, andSize: 12)))
							.foregroundStyle(Color(UIColor.colorNamed("Txt8")))
						
					}
					.offset(x: boxOffset)
				}
			}
		}
		.accessibilityIdentifier("chart-annotation-top")
		.frame(height: 18)
		.background(.clear)
	}
	
	private var bottomAnnotationView: some View {
		VStack {
			ZStack(alignment: .topLeading) {
				GeometryReader { geo in
					
					let widthOfString = doubleFormatter(integration.minData?.value).widthOfString(usingFont: UIFont.custom(ofType: .bold, andSize: 12))
					var boxOffset: CGFloat = 4
					
					if maxDataPoint.y == minDataPoint.y {
						boxOffset = CGFloat(geo.size.width - widthOfString)
					} else {
						boxOffset = max(4, min(geo.size.width - widthOfString, minDataPoint.x - widthOfString / 2))
					}
					
					
					return VStack(alignment: .trailing) {
						Text(doubleFormatter((integration.minData?.value ?? 0)))
							.font(Font(UIFont.custom(ofType: .bold, andSize: 12)))
							.foregroundStyle(Color(UIColor.colorNamed("Txt8")))
						
					}
					.offset(x: boxOffset)
				}
			}
		}
		.accessibilityIdentifier("chart-annotation-bottom")
		.frame(height: 18)
		.background(.clear)
	}
	
	private var chart: some View {
		Chart {
			ForEach(integration.data) { element in
				LineMark(x: .value("Date", element.date), y: .value("Value", element.value))
					.lineStyle(StrokeStyle(lineWidth: 3))
					.foregroundStyle(Color(UIColor.colorNamed("BGB2")))
					.interpolationMethod(.linear)
				
				AreaMark(
					x: .value("Date", element.date),
					yStart: .value("amount", integration.bottomGradientBleedValue),
					yEnd: .value("amountEnd", element.value)
				)
				.foregroundStyle(gradient)
			}
		}
		.chartXAxis(.hidden)
		.chartYAxis(.hidden)
		.chartYScale(domain: (integration.minData?.value ?? 0)...(integration.maxData?.value ?? 0))
		.backgroundStyle(Color.clear)
		.chartOverlay { proxy in
			useProxy(proxy)
			
			GeometryReader { geometry in
				Rectangle().fill(.clear).contentShape(Rectangle())
					.gesture(
						DragGesture(minimumDistance: 0)
							.onChanged { value in
								self.isDragging = true
								
								let origin = geometry[proxy.plotAreaFrame].origin
								if let datePos = proxy.value(atX: value.location.x - origin.x, as: Date.self), let firstGreater = integration.data.lastIndex(where: { $0.date < datePos }) {
									let newPoint = integration.data[firstGreater]
									
									if selectedData != newPoint {
										selectedData = newPoint
										integration.delegate?.didSelectPoint(selectedData, ofIndex: firstGreater)
										
										selectedDataPoint = proxy.position(for: (x: integration.data[firstGreater].date, y: integration.data[firstGreater].value)) ?? CGPoint(x: 0, y: 0)
									}
								}
							}
							.onEnded { value in
								self.isDragging = false
								self.selectedData = nil
								self.selectedDataPoint = CGPoint(x: 0, y: 0)
								
								integration.delegate?.didFinishSelectingPoint()
							}
					)
				
				
				// If the user is dragging their finger across the chart, compute and record the closest datapoint
				if isDragging {
					Circle()
						.fill(Color(UIColor.colorNamed("BGB8")).opacity(0.1))
						.frame(width: 32, height: 32)
						.position(x: selectedDataPoint.x, y: selectedDataPoint.y)
					
					Circle()
						.fill(Color(UIColor.colorNamed("BGB8")))
						.frame(width: 6, height: 6)
						.position(x: selectedDataPoint.x, y: selectedDataPoint.y)
				}
			}
		}
	}
	
	private func doubleFormatter(_ double: Double?) -> String {
		guard let d = double else { return "" }
		
		var numberOfDigits = 2
		if d < 0.000001 {
			let emptyValue = DependencyManager.shared.coinGeckoService.format(decimal: Decimal(d), numberStyle: .currency, maximumFractionDigits: 2)
			return "<\(emptyValue)"
			
		} else if d < 0.01 {
			numberOfDigits = 6
		}
		
		return DependencyManager.shared.coinGeckoService.format(decimal: Decimal(d), numberStyle: .currency, maximumFractionDigits: numberOfDigits)
	}
	
	private func useProxy(_ proxy: ChartProxy) -> some View {
		
		DispatchQueue.main.async {
			if let max = integration.maxData, let min = integration.minData {
				self.maxDataPoint = proxy.position(for: (x: max.date, y: max.value)) ?? CGPoint(x: 0, y: 0)
				self.minDataPoint = proxy.position(for: (x: min.date, y: min.value)) ?? CGPoint(x: 0, y: 0)
			}
		}
		
		return EmptyView()
	}
}

// MARK: - Preview

struct TokenDetailsChartView_Previews: PreviewProvider {
	static var previews: some View {
		
		let tempData1: [ChartViewDataPoint] = [
			.init(value: 1.0824332458790638, date: Date()),
			.init(value: 1.0806859563659879, date: Date().addingTimeInterval(10000)),
			.init(value: 1.0806711006253034, date: Date().addingTimeInterval(20000)),
			.init(value: 1.0795723536365875, date: Date().addingTimeInterval(30000)),
			.init(value: 1.0791162896315143, date: Date().addingTimeInterval(40000)),
			.init(value: 1.0765211160416603, date: Date().addingTimeInterval(50000)),
			.init(value: 100000.0830491365529251, date: Date().addingTimeInterval(60000))
		]
		
		let tempData2: [ChartViewDataPoint] = [
			.init(value: 1.01, date: Date()),
			.init(value: 1.02, date: Date().addingTimeInterval(10000)),
			.init(value: 1.03, date: Date().addingTimeInterval(20000)),
			.init(value: 1.07, date: Date().addingTimeInterval(30000)),
			.init(value: 1.05, date: Date().addingTimeInterval(40000)),
			.init(value: 1.06, date: Date().addingTimeInterval(50000)),
			.init(value: 1.01, date: Date().addingTimeInterval(60000))
		]
		
		let tempData3: [ChartViewDataPoint] = [
			.init(value: 900, date: Date()),
			.init(value: 500, date: Date().addingTimeInterval(10000)),
			.init(value: 80.7, date: Date().addingTimeInterval(20000)),
			.init(value: 400, date: Date().addingTimeInterval(30000)),
			.init(value: 890, date: Date().addingTimeInterval(40000)),
			.init(value: 80, date: Date().addingTimeInterval(50000)),
			.init(value: 900, date: Date().addingTimeInterval(60000))
		]
		
		let tempData4: [ChartViewDataPoint] = [
		]
		
		let tempData5: [ChartViewDataPoint] = [
			.init(value: 0.0004, date: Date()),
			.init(value: 0.0006, date: Date().addingTimeInterval(10000)),
			.init(value: 0.0002, date: Date().addingTimeInterval(20000)),
			.init(value: 0.0001, date: Date().addingTimeInterval(30000)),
			.init(value: 0.0009, date: Date().addingTimeInterval(40000)),
			.init(value: 0.00041, date: Date().addingTimeInterval(50000)),
			.init(value: 0.00042, date: Date().addingTimeInterval(60000))
		]
		
		let tempData6: [ChartViewDataPoint] = [
			.init(value: 0.0000004, date: Date()),
			.init(value: 0.0000006, date: Date().addingTimeInterval(10000)),
			.init(value: 0.0000002, date: Date().addingTimeInterval(20000)),
			.init(value: 0.0000001, date: Date().addingTimeInterval(30000)),
			.init(value: 0.0000009, date: Date().addingTimeInterval(40000)),
			.init(value: 0.00000041, date: Date().addingTimeInterval(50000)),
			.init(value: 0.00000042, date: Date().addingTimeInterval(60000))
		]
		
		let tempData7: [ChartViewDataPoint] = [
			.init(value: 0.004, date: Date()),
			.init(value: 0.004, date: Date())
		]
		
		let dataArrays = [tempData1, tempData2, tempData3, tempData4, tempData5, tempData6, tempData7]
		var currentIndex = 0
		
		let integration = ChartViewIntegrationService()
		integration.data = dataArrays[currentIndex]
		
		
		return VStack(spacing: 24) {
			AnyView(ChartView().frame(width: 300, height: 150).environmentObject(integration))
			Button("Switch data", action: {
				currentIndex += 1
				
				if currentIndex > dataArrays.count-1 {
					currentIndex = 0
				}
				
				integration.data = dataArrays[currentIndex]
			})
		}
	}
}
