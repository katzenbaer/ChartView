//
//  ChartView.swift
//  ChartView
//
//  Created by András Samu on 2019. 06. 12..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct BarChartView : View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    internal var data: ChartData
    public var title: String
    public var legend: String?
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    public var formSize:CGSize
    public var dropShadow: Bool
    public var cornerImage: Image
    public var valueSpecifier:String
    
    private var currentIndex: Int {
        guard self.data.points.count > 0 else {
            return 0
        }
        
        return max(0,min(self.data.points.count-1,Int(floor((self.touchLocation*self.formSize.width)/(self.formSize.width/CGFloat(self.data.points.count))))))
    }
    @State private var touchLocation: CGFloat = -1.0
    @State private var showValue: Bool = false
    @State private var showLabelValue: Bool = false
    @State private var currentValueLabel: String = ""
    @State private var currentValue: Double = 0 {
        didSet{
            if(oldValue != self.currentValue && self.showValue) {
                HapticFeedback.playSelection()
            }
        }
    }
    var isFullWidth:Bool {
        return self.formSize == ChartForm.large
    }
    public init(data: ChartData, title: String, legend: String? = nil, style: ChartStyle = Styles.barChartStyleOrangeLight, form: CGSize? = ChartForm.medium, dropShadow: Bool? = true, cornerImage:Image? = nil, valueSpecifier: String? = "%.1f"){
        self.data = data
        self.title = title
        self.legend = legend
        self.style = style
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.barChartStyleOrangeDark
        self.formSize = form!
        self.dropShadow = dropShadow!
        self.cornerImage = cornerImage ?? Image("")
        self.valueSpecifier = valueSpecifier!
    }
    
    public var body: some View {
        let stack = ZStack{
            Rectangle()
                .fill(self.colorScheme == .dark ? self.darkModeStyle.backgroundColor : self.style.backgroundColor)
                .cornerRadius(20)
                .shadow(color: self.style.dropShadowColor, radius: self.dropShadow ? 8 : 0)
            VStack(alignment: .leading){
                HStack{
                    if(!showValue){
                        Text(self.title)
                            .font(.headline)
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
                    }else{
                        Text("\(self.currentValue, specifier: self.valueSpecifier)")
                            .font(.headline)
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
                    }
                    if(self.formSize == ChartForm.large && self.legend != nil && !showValue) {
                        Text(self.legend!)
                            .font(.callout)
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.accentColor : self.style.accentColor)
                            .transition(.opacity)
                            .animation(.easeOut)
                    }
                    Spacer()
                    #if os(iOS)
                    self.cornerImage
                        .imageScale(.large)
                        .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor)
                    #else
                    self.cornerImage
                        .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor)
                    #endif
                }.padding()
                BarChartRow(chartData: data,
                            accentColor: self.colorScheme == .dark ? self.darkModeStyle.accentColor : self.style.accentColor,
                            gradient: self.colorScheme == .dark ? self.darkModeStyle.gradientColor : self.style.gradientColor,
                            touchLocation: self.$touchLocation,
                            shouldMagnify: tryMagnify(_:))
                if self.legend != nil  && self.formSize == ChartForm.medium && !self.showLabelValue{
                    Text(self.legend!)
                        .font(.headline)
                        .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor)
                        .padding()
                } else if (self.data.valuesGiven) {
                    LabelView(arrowOffset: self.getArrowOffset(touchLocation: self.touchLocation),
                              title: $currentValueLabel)
                        .offset(x: self.getLabelViewOffset(touchLocation: self.touchLocation), y: -6)
                        .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor)
                }
                
            }
        }
        .frame(minWidth:self.formSize.width,
               maxWidth: self.isFullWidth ? .infinity : self.formSize.width,
               minHeight:self.formSize.height,
               maxHeight:self.formSize.height)
        .onReceive(data.$points, perform: { (points: [(String, Double)]) in
            guard points.count > self.currentIndex else {
                return
            }
            let currentPoint = points[self.currentIndex]
            self.currentValueLabel = currentPoint.0
            self.currentValue = currentPoint.1
        })
        .gesture(DragGesture()
            .onChanged({ value in
                self.touchLocation = value.location.x/self.formSize.width
                self.showValue = true
                self.currentValue = self.data.points[self.currentIndex].1
                if(self.data.valuesGiven && self.formSize == ChartForm.medium) {
                    self.showLabelValue = true
                }
            })
            .onEnded({ value in
                self.showValue = false
                self.showLabelValue = false
                self.touchLocation = -1
            })
        )
        .gesture(TapGesture())
        
        if #available(iOS 13.4, OSX 10.15, *) {
            return AnyView(stack.onHover { (over) in
                guard !over else {
                    return
                }

                self.resetMagnify()
            })
        } else {
            return AnyView(stack)
        }
    }
    
    func getArrowOffset(touchLocation:CGFloat) -> Binding<CGFloat> {
        let realLoc = (self.touchLocation * self.formSize.width) - 50
        if realLoc < 10 {
            return .constant(realLoc - 10)
        }else if realLoc > self.formSize.width-110 {
            return .constant((self.formSize.width-110 - realLoc) * -1)
        } else {
            return .constant(0)
        }
    }
    
    func getLabelViewOffset(touchLocation:CGFloat) -> CGFloat {
        return min(self.formSize.width-110,max(10,(self.touchLocation * self.formSize.width) - 50))
    }
    
    func tryMagnify(_ touchLocation: CGFloat) -> Void {
        guard touchLocation != -1 else {
            // Resetting it here causes issues because of a race condition between switching hover elements
            return
        }
        
        self.touchLocation = touchLocation
        self.showValue = true
        self.currentValue = self.data.points[self.currentIndex].1
        if(self.data.valuesGiven && self.formSize == ChartForm.medium) {
            self.showLabelValue = true
        }
    }
    
    func resetMagnify() {
        self.showValue = false
        self.showLabelValue = false
        self.touchLocation = -1
    }
}

#if DEBUG
struct ChartView_Previews : PreviewProvider {
    static var previews: some View {
        BarChartView(data: TestData.values ,
                     title: "Model 3 sales",
                     legend: "Quarterly",
                     valueSpecifier: "%.0f")
    }
}
#endif
