//
//  Locations.swift
//  mapdemo
//
//  Created by Jung-Sun Yi-Tsang on 12/9/17.
//  Copyright © 2017 bayser. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Locs {
    typealias locEntry = (String, String, Int, Double, Double)
    static var locList: [locEntry] = [] //middle entry is the code
    
    static func getLocation(locCode: Int) -> locEntry? {
        for i in 0..<Locs.locList.count {
            let l = Locs.locList[i]
            if l.2 == locCode {
                return l
            }
        }
        return nil
    }
    
    static func locCoder(input: String) -> Int {
        return Int(input) ?? -1
    }
}

class MyList {
    static var locPoints = [MKPointAnnotation]()
    
    static func initiate() -> Void {
        locPoints = []
        for elm in Locs.locList {
            let an = MKPointAnnotation()
            an.title = elm.1
            an.subtitle = elm.0
            an.coordinate = CLLocationCoordinate2DMake(elm.3, elm.4)
            locPoints.append(an)
        }
    }
}
