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
	@Published var data: [ChartViewDataPoint] = []
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
		integration.data = data
	}
}



// MARK: - SwiftUI

struct ChartView: View {
	
	@State private var selectedData: ChartViewDataPoint?
	@State private var selectedDataPoint: CGPoint = CGPoint(x: 0, y: 0)
	@State private var maxData: ChartViewDataPoint?
	@State private var maxDataPoint: CGPoint = CGPoint(x: 0, y: 0)
	@State private var minData: ChartViewDataPoint?
	@State private var minDataPoint: CGPoint = CGPoint(x: 0, y: 0)
	@State private var middleValue: Decimal = 0
	@State private var isDragging: Bool = false
	
	@EnvironmentObject private var integration: ChartViewIntegrationService
	
	private let gradient = LinearGradient(
		gradient: Gradient(
			colors: [
				Color(red: 0.333, green: 0.361, blue: 0.792, opacity: 0.48),
				Color(red: 0.333, green: 0.361, blue: 0.792, opacity: 0)
			]
		),
		startPoint: .top,
		endPoint: .bottom
	)
	
	var body: some View {
		VStack(spacing: 0) {
			topAnnotationView
			chart
			
		}.background(.clear)
	}
	
	private var topAnnotationView: some View {
		VStack {
			ZStack(alignment: .topLeading) {
				GeometryReader { geo in
					
					let widthOfString = doubleFormatter(maxData?.value).widthOfString(usingFont: UIFont.custom(ofType: .bold, andSize: 10))
					let boxOffset = max(4, min(geo.size.width - widthOfString, maxDataPoint.x - widthOfString / 2))
					
					VStack(alignment: .trailing) {
						Text(doubleFormatter(maxData?.value))
							.font(Font(UIFont.custom(ofType: .bold, andSize: 10)))
							.foregroundStyle(Color("Grey900"))
						
					}
					.offset(x: boxOffset)
				}
			}
		}
		.frame(height: 18)
		.background(.clear)
	}
	
	private var chart: some View {
		Chart {
			ForEach(integration.data) { element in
				AreaMark(x: .value("Date", element.date), y: .value("Value", element.value))
					.interpolationMethod(.linear)
					.foregroundStyle(gradient)
				
				LineMark(x: .value("Date", element.date), y: .value("Value", element.value))
					.lineStyle(StrokeStyle(lineWidth: 3))
					.foregroundStyle(Color("Brand1200"))
					.interpolationMethod(.linear)
			}
		}
		.chartXAxis(.hidden)
		.chartYAxis(.hidden)
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
										
										/*
										if selectedDataPoint.x == 0 && selectedDataPoint.y == 0 {
											selectedDataPoint = proxy.position(for: (x: integration.data[firstGreater].date, y: integration.data[firstGreater].value)) ?? CGPoint(x: 0, y: 0)
										} else {
											withAnimation(.linear(duration: 0.3)) {
												selectedDataPoint = proxy.position(for: (x: integration.data[firstGreater].date, y: integration.data[firstGreater].value)) ?? CGPoint(x: 0, y: 0)
											}
										}
										*/
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
				
				
				// Add text annotation of lowest value as overlay to bottom of chart
				let widthOfString = doubleFormatter(minData?.value).widthOfString(usingFont: UIFont.custom(ofType: .bold, andSize: 10))
				let boxOffset = max(4, min(geometry.size.width - widthOfString, minDataPoint.x - widthOfString / 2))
				
				VStack(alignment: .trailing) {
					Text(doubleFormatter(minData?.value))
						.font(Font(UIFont.custom(ofType: .bold, andSize: 10)))
						.foregroundStyle(Color("Grey900"))
					
				}
				.offset(x: boxOffset, y: minDataPoint.y + 8)
				
				
				// If the user is dragging their finger across the chart, compute and record the closest datapoint
				if isDragging {
					Circle()
						.fill(Color("Brand500").opacity(0.1))
						.frame(width: 32, height: 32)
						.position(x: selectedDataPoint.x, y: selectedDataPoint.y)
					
					Circle()
						.fill(Color("Brand500"))
						.frame(width: 6, height: 6)
						.position(x: selectedDataPoint.x, y: selectedDataPoint.y)
				}
			}
		}
	}
	
	private func doubleFormatter(_ double: Double?) -> String {
		guard let d = double else { return "" }
		
		return DependencyManager.shared.coinGeckoService.format(decimal: Decimal(d), numberStyle: .currency, maximumFractionDigits: 2)
	}
	
	private func useProxy(_ proxy: ChartProxy) -> some View {
		
		DispatchQueue.main.async {
			if let max = integration.data.max(by: { $0.value < $1.value }), let min = integration.data.max(by: { $0.value > $1.value }) {
				self.maxData = max
				self.maxDataPoint = proxy.position(for: (x: max.date, y: max.value)) ?? CGPoint(x: 0, y: 0)
				
				self.minData = min
				self.minDataPoint = proxy.position(for: (x: min.date, y: min.value)) ?? CGPoint(x: 0, y: 0)
			}
		}
		
		return EmptyView()
	}
}

// MARK: - Preview

struct TokenDetailsChartView_Previews: PreviewProvider {
	static var previews: some View {
		let tempData: [ChartViewDataPoint] = [
			.init(value: 900, date: Date()),
			.init(value: 500, date: Date().addingTimeInterval(10000)),
			.init(value: 80.7, date: Date().addingTimeInterval(20000)),
			.init(value: 400, date: Date().addingTimeInterval(30000)),
			.init(value: 890, date: Date().addingTimeInterval(40000)),
			.init(value: 80, date: Date().addingTimeInterval(50000)),
			.init(value: 900, date: Date().addingTimeInterval(60000))
		]
		
		let integration = ChartViewIntegrationService()
		integration.data = tempData
		
		return AnyView(ChartView().frame(width: 300, height: 150).environmentObject(integration))
	}
}
