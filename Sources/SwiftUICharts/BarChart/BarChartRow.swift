//
//  ChartRow.swift
//  ChartView
//
//  Created by András Samu on 2019. 06. 12..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct BarChartRow : View {
    var data: [Double]
    var accentColor: Color
    var gradient: GradientColor?
    var maxValue: Double {
        data.max() ?? 0
    }
    
    @Binding var touchLocation: CGFloat
    
    var shouldMagnify: ((_ touchLocation: CGFloat) -> Void)?
    
    public var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: (geometry.frame(in: .local).width-22)/CGFloat(self.data.count * 3)){
                ForEach(0..<self.data.count, id: \.self) { i in
                    self.makeBarChartCell(i, geometry: geometry)
                }
            }
            .padding([.top, .leading, .trailing], 10)
        }
    }
    
    func normalizedValue(index: Int) -> Double {
        return Double(self.data[index])/Double(self.maxValue)
    }
    
    func makeBarChartCell(_ i: Int, geometry: GeometryProxy) -> some View {
        let cell = BarChartCell(value: self.normalizedValue(index: i),
                            index: i,
                            width: Float(geometry.frame(in: .local).width - 22),
                            numberOfDataPoints: self.data.count,
                            accentColor: self.accentColor,
                            gradient: self.gradient,
                            touchLocation: self.$touchLocation)
            .scaleEffect(self.touchLocation > CGFloat(i)/CGFloat(self.data.count) && self.touchLocation < CGFloat(i+1)/CGFloat(self.data.count) ? CGSize(width: 1.4, height: 1.1) : CGSize(width: 1, height: 1), anchor: .bottom)
            .animation(.spring())
        
        return applyHoverEffectsIfAvailable(cell, i: i)
    }
    
    func applyHoverEffectsIfAvailable<T: View>(_ view: T, i: Int) -> some View {
        typealias ConditionalContent = _ConditionalContent<View, View>
        
        #if os(iOS)
        guard #available(iOS 13.4, *) else {
            return AnyView(applyHoverIfAvailable(view, i: i))
        }
        
        let view = view.hoverEffect(.lift)
        let firstContent = applyHoverIfAvailable(view, i: i)
        return AnyView(firstContent)
        #else
        return AnyView(applyHoverIfAvailable(view, i: i))
        #endif
    }
    
    func applyHoverIfAvailable<T: View>(_ view: T, i: Int) -> _ConditionalContent<AnyView, T> {
        if #available(iOS 13.4, OSX 10.15, *) {
            return ViewBuilder.buildEither(first: AnyView(view.onHover { (over) in
                guard over else {
                    self.shouldMagnify?(-1)
                    return
                }

                let touchLocation = (CGFloat(i) + 0.5)/CGFloat(self.data.count)
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
        BarChartRow(data: [8,23,54,32,12,37,7], accentColor: Colors.OrangeStart, touchLocation: .constant(-1))
    }
}
#endif
