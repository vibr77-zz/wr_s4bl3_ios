//
//  rowerStack.swift
//  S4BL3 IOS
//
//  Created by vincent.besson on 04/11/2020.
//

import Foundation


struct rowerDataPoint{
    var heartRate:Int!=0
    var elaspedtime:Int!=0
    var distance:Int!=0
    var strokes:Int!=0
    var strokeRate:Double!=0
    var power:Int!=0
}

struct rowerBadge{
    
}

struct rowerActivities{
    var title:String!=""
    var dataPoints:[rowerDataPoint]
    var agregateDataPer500m:[rowerDataPoint]
    var agregateDataPerMin:[rowerDataPoint]
    var Badge:[rowerBadge]
    var distance:Int!=0
    var strokes:Int!=0
    var averageStrokeRate:Double!=0
    var averageSpeedPer500m:Int!=0
    var averageSpeedMs:Double!=0
    var averageHeartRate:Int!=0
}

public class rowerStack: NSObject {
    
}
