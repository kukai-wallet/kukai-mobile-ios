//
//  TokenDetailsChartView.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/11/2022.
//

import UIKit
import SwiftUI
import Charts



public struct ChartViewDataPoint: Identifiable {
	public var value: Double
	public var date: Date
	public var id = UUID()
}



// MARK: - UIKit

class ChartViewIntegrationService: ObservableObject {
	@Published var data: [ChartViewDataPoint] = []
}

class ChartHostingController: UIHostingController<AnyView> {
	
	private let integration = ChartViewIntegrationService()
	private let chartView: some View = ChartView().backgroundStyle(.clear)
	
	required init?(coder: NSCoder) {
		super.init(coder: coder, rootView: AnyView(chartView.environmentObject(integration)))
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
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
	
	var body: some View {
		VStack(spacing: 0) {
			topSelectedView
			topAnnotationView
			chart
			bottomAnnotationView
			
		}.background(.clear)
	}
	
	private var topSelectedView: some View {
		VStack {
			ZStack(alignment: .topLeading) {
				GeometryReader { geo in
					
					if isDragging, let selectedData {
						let widthOfString = doubleFormatter(selectedData.value).widthOfString(usingFont: UIFont.custom(ofType: .bold, andSize: 12))
						let boxOffset = max(0, min(geo.size.width - widthOfString, selectedDataPoint.x - widthOfString / 2))
						
						VStack(alignment: .center) {
							Text(doubleFormatter(selectedData.value))
								.font(Font(UIFont.custom(ofType: .bold, andSize: 12)))
								.foregroundStyle(Color("Grey2000"))
						}
						.frame(width: widthOfString, alignment: .center)
						.background {
							ZStack {
								RoundedRectangle(cornerRadius: 8)
									.fill(.white.opacity(0.7))
							}
							.padding(.horizontal, -8)
							.padding(.vertical, -4)
						}
						.offset(x: boxOffset)
					}
				}
			}
		}
		.frame(height: 18)
		.background(.clear)
	}
	
	private var topAnnotationView: some View {
		VStack {
			ZStack(alignment: .topLeading) {
				GeometryReader { geo in
					
					let widthOfString = doubleFormatter(maxData?.value).widthOfString(usingFont: UIFont.custom(ofType: .bold, andSize: 12))
					let boxOffset = max(0, min(geo.size.width - widthOfString, maxDataPoint.x - widthOfString / 2))
					
					VStack(alignment: .trailing) {
						Text(doubleFormatter(maxData?.value))
							.font(Font(UIFont.custom(ofType: .bold, andSize: 12)))
							.foregroundStyle(Color("Grey900"))
						
					}
					.offset(x: boxOffset)
					
					if isDragging {
						let lineX = selectedDataPoint.x
						let lineHeight = 18.0
						
						Rectangle()
							.fill(.white.opacity(0.5))
							.frame(width: 2, height: lineHeight)
							.position(x: lineX, y: lineHeight / 2)
					}
				}
			}
		}
		.frame(height: 18)
		.background(.clear)
	}
	
	private var bottomAnnotationView: some View {
		VStack {
			ZStack(alignment: .topLeading) {
				GeometryReader { geo in
						
					let widthOfString = doubleFormatter(minData?.value).widthOfString(usingFont: UIFont.custom(ofType: .bold, andSize: 12))
					let boxOffset = max(0, min(geo.size.width - widthOfString, minDataPoint.x - widthOfString / 2))
					
					VStack(alignment: .trailing) {
						Text(doubleFormatter(minData?.value))
							.font(Font(UIFont.custom(ofType: .bold, andSize: 12)))
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
		Chart(integration.data) {
			LineMark(x: .value("Date", $0.date), y: .value("Value", $0.value))
				.lineStyle(StrokeStyle(lineWidth: 3))
				.foregroundStyle(Color("Brand1200"))
				.interpolationMethod(.linear)
		}
		.chartXAxis(.hidden)
		.chartYAxis(.hidden)
		.backgroundStyle(Color.clear)
		.chartBackground { proxy in
			ZStack(alignment: .topLeading) {
				GeometryReader { geo in
					useProxy(proxy)
					
					if isDragging {
						let lineX = selectedDataPoint.x + geo[proxy.plotAreaFrame].origin.x
						let lineHeight = selectedDataPoint.y
						
						Rectangle()
							.fill(.white.opacity(0.5))
							.frame(width: 2, height: lineHeight)
							.position(x: lineX, y: lineHeight / 2)
					}
				}
			}
		}
		.chartOverlay { proxy in
			GeometryReader { geometry in
				Rectangle().fill(.clear).contentShape(Rectangle())
					.gesture(
						DragGesture(minimumDistance: 0)
							.onChanged { value in
								self.isDragging = true
								
								let origin = geometry[proxy.plotAreaFrame].origin
								if let datePos = proxy.value(atX: value.location.x - origin.x, as: Date.self), let firstGreater = integration.data.lastIndex(where: { $0.date < datePos }) {
									selectedData = integration.data[firstGreater]
									selectedDataPoint = proxy.position(for: (x: integration.data[firstGreater].date, y: integration.data[firstGreater].value)) ?? CGPoint(x: 0, y: 0)
								}
							}
							.onEnded { value in
								self.isDragging = false
								self.selectedData = nil
							}
					)
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
			.init(value: 400, date: Date()),
			.init(value: 500, date: Date().addingTimeInterval(10000)),
			.init(value: 80.7, date: Date().addingTimeInterval(20000)),
			.init(value: 20, date: Date().addingTimeInterval(30000)),
			.init(value: 900, date: Date().addingTimeInterval(40000)),
			.init(value: 80, date: Date().addingTimeInterval(50000)),
			.init(value: 890, date: Date().addingTimeInterval(60000))
		]
		
		let integration = ChartViewIntegrationService()
		integration.data = tempData
		
		return AnyView(ChartView().environmentObject(integration))
	}
}
