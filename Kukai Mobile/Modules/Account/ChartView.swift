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
	public var value: Decimal
	public var date: Date
	public var id = UUID()
}



// MARK: - UIKit

class ChartViewIntegrationService: ObservableObject {
	@Published var data: [ChartViewDataPoint] = []
}

class ChartHostingController: UIHostingController<AnyView> {
	
	private let integration = ChartViewIntegrationService()
	private let chartView = ChartView()
	
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
	@State private var middleValue: Decimal = 0
	@State private var isDragging: Bool = false
	
	@EnvironmentObject private var integration: ChartViewIntegrationService
	
	var body: some View {
		VStack(spacing: 0) {
			VStack {
				ZStack(alignment: .topLeading) {
					GeometryReader { geo in
						if isDragging, let selectedData {
							
							let boxWidth: CGFloat = 50
							let boxOffset = max(0, min(geo.size.width - boxWidth, selectedDataPoint.x - boxWidth / 2))
							
							VStack(alignment: .center) {
								Text(selectedData.value.description)
									.font(Font(UIFont.custom(ofType: .bold, andSize: 12)))
									.foregroundStyle(Color("Grey900"))
							}
							.frame(width: boxWidth, alignment: .center)
							.background {
								ZStack {
									RoundedRectangle(cornerRadius: 8)
										.fill(Color("Grey1300").opacity(0.7))
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
			chart
		}
	}
	
	private var chart: some View {
		Chart(integration.data) {
			LineMark(x: .value("Date", $0.date), y: .value("Value", $0.value))
				.lineStyle(StrokeStyle(lineWidth: 3))
				.foregroundStyle(Color("Brand1200"))
				.interpolationMethod(.linear)
			
			
			if let max = integration.data.max(by: { $0.value < $1.value }), let min = integration.data.max(by: { $0.value > $1.value }) {
				PointMark(x: .value("Date", max.date), y: .value("Value", max.value))
					.symbolSize(CGSize(width: 1, height: 1))
					.foregroundStyle(.clear)
					.annotation(position: .top, spacing: 4) {
						Text(max.value.description)
							.font(Font(UIFont.custom(ofType: .bold, andSize: 10)))
							.foregroundColor(isDragging ? .clear : Color("Grey900"))
					}
				
				PointMark(x: .value("Date", min.date), y: .value("Value", min.value))
					.symbolSize(CGSize(width: 1, height: 1))
					.foregroundStyle(.clear)
					.annotation(position: .bottom, spacing: 4) {
						Text(min.value.description)
							.font(Font(UIFont.custom(ofType: .bold, andSize: 10)))
							.foregroundColor(isDragging ? .clear : Color("Grey900"))
					}
			}
		}
		.chartXAxis(.hidden)
		.chartYAxis(.hidden)
		.backgroundStyle(Color.clear)
		.chartBackground { proxy in
			ZStack(alignment: .topLeading) {
				GeometryReader { geo in
					if isDragging {
						let lineX = selectedDataPoint.x + geo[proxy.plotAreaFrame].origin.x
						let lineHeight = selectedDataPoint.y
						
						Rectangle()
							.fill(Color("Grey1300").opacity(0.5))
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
}

// MARK: - Preview

struct TokenDetailsChartView_Previews: PreviewProvider {
	static var previews: some View {
		let tempData: [ChartViewDataPoint] = [
			.init(value: 400, date: Date()),
			.init(value: 500, date: Date().addingTimeInterval(10000)),
			.init(value: 80.7, date: Date().addingTimeInterval(20000)),
			.init(value: 20, date: Date().addingTimeInterval(30000)),
			.init(value: 890, date: Date().addingTimeInterval(40000)),
			.init(value: 80, date: Date().addingTimeInterval(50000)),
			.init(value: 900, date: Date().addingTimeInterval(60000))
		]
		
		let integration = ChartViewIntegrationService()
		integration.data = tempData
		
		return AnyView(ChartView().environmentObject(integration))
	}
}
