//
//  ChartRow.swift
//  ChartView
//
//  Created by András Samu on 2019. 06. 12..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct BarChartRow : View {
    @ObservedObject var chartData: ChartData
    
    var accentColor: Color
    var gradient: GradientColor?
    var maxValue: Double {
        chartData.onlyPoints().max() ?? 0
    }
    
    func scaleFactor(for location: Int) -> CGSize {
        guard chartData.points.count > 0 else {
            return CGSize(width: 1, height: 1)
        }
        
        if self.touchLocation > CGFloat(location)/CGFloat(self.chartData.points.count) && self.touchLocation < CGFloat(location+1)/CGFloat(self.chartData.points.count) {
            return CGSize(width: 1.4, height: 1.1)
        } else {
            return CGSize(width: 1, height: 1)
        }
    }
    
    func spacing(for geometry: GeometryProxy) -> CGFloat {
        guard self.chartData.points.count > 0 else {
            return 0
        }
        
        return (geometry.frame(in: .local).width-22)/CGFloat(self.chartData.points.count * 3)
    }
    
    @Binding var touchLocation: CGFloat
    
    var shouldMagnify: ((_ touchLocation: CGFloat) -> Void)?
    
    public var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: self.spacing(for: geometry)) {
                ForEach(0..<self.chartData.points.count, id: \.self) { i in
                    self.makeBarChartCell(i, geometry: geometry)
                }
            }
            .padding([.top, .leading, .trailing], 10)
        }
    }
    
    func normalizedValue(index: Int) -> Double {
        guard maxValue > 0 else {
            return 0
        }
        
        return Double(self.chartData.onlyPoints()[index])/Double(self.maxValue)
    }
    
    func makeBarChartCell(_ i: Int, geometry: GeometryProxy) -> some View {
        let cell = BarChartCell(value: Binding<Double>(
            get: { self.normalizedValue(index: i) },
            set: { _ in }),
                            index: i,
                            width: Float(geometry.frame(in: .local).width - 22),
                            numberOfDataPoints: self.chartData.points.count,
                            accentColor: self.accentColor,
                            gradient: self.gradient,
                            touchLocation: self.$touchLocation)
            .scaleEffect(self.scaleFactor(for: i), anchor: .bottom)
            .animation(.spring())
        
        return applyHoverIfAvailable(cell, i: i)
    }
    
    func applyHoverIfAvailable<T: View>(_ view: T, i: Int) -> _ConditionalContent<AnyView, T> {
        if #available(iOS 13.4, OSX 10.15, *) {
            return ViewBuilder.buildEither(first: AnyView(view.onHover { (over) in
                guard over else {
                    self.shouldMagnify?(-1)
                    return
                }

                let touchLocation = (self.chartData.points.count > 0) ? (CGFloat(i) + 0.5)/CGFloat(self.chartData.points.count) : 0
                self.shouldMagnify?(touchLocation)
                }))
        } else {
            return ViewBuilder.buildEither(second: view)
        }
    }
}

#if DEBUG
struct ChartRow_Previews : PreviewProvider {
    static var previews: some View {
        BarChartRow(chartData: ChartData(points: [8,23,54,32,12,37,7]), accentColor: Colors.OrangeStart, touchLocation: .constant(-1))
    }
}
#endif
