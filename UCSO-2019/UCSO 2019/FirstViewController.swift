//
//  FirstViewController.swift
//  UCSO Invitational 2018
//
//  Created by Jung-Sun Yi-Tsang on 12/10/17.
//  Copyright © 2017 bayser. All rights reserved.
//

import UIKit
import MapKit


class FirstViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var map: MKMapView!
    let locationManager = CLLocationManager()
    var oldPoints : [MKPointAnnotation] = []

    func tabBar(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Howdy!")
        if viewController is FirstViewController {
            print("First tab")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let centerLoc = CLLocationCoordinate2DMake(40.101952, -88.227161)
        let mapSpan = MKCoordinateSpanMake(0.015, 0.015)
        let mapRegion = MKCoordinateRegion(center: centerLoc, span: mapSpan)
        self.map.setRegion(mapRegion, animated: true)
        
        self.reloadPoints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDownloadFinished), name: .downloadFinished, object: nil)
        
        self.map.showsUserLocation = true
        
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    @objc func onDownloadFinished() {
        DispatchQueue.main.async {
            self.reloadPoints()
        }
    }

    func reloadPoints() {
        if (oldPoints == []) || (MyList.locPoints != oldPoints) {
            MyList.initiate()
            if MyList.locPoints.count != 0 {
                self.map.removeAnnotations(self.map.annotations)
                
                let firstPoint = MyList.locPoints.first!
                
                var minLat: Double = firstPoint.coordinate.latitude
                var maxLat: Double = firstPoint.coordinate.latitude
                var minLong: Double = firstPoint.coordinate.longitude
                var maxLong: Double = firstPoint.coordinate.longitude
                
                for pt in MyList.locPoints {
                    self.map.addAnnotation(pt)
                    let lat = pt.coordinate.latitude
                    let long = pt.coordinate.longitude
                    if lat < minLat {
                        minLat = lat
                    } else if lat > maxLat {
                        maxLat = lat
                    }
                    if long < minLong {
                        minLong = long
                    } else if long > maxLong {
                        maxLong = long
                    }
                }
                let midLat = (minLat + maxLat) / 2
                let midLong = (minLong + maxLong) / 2
                
                let spread = 0.01 + max(maxLat-minLat, maxLong - minLong) / 2
                
                
                let centerLoc = CLLocationCoordinate2DMake(midLat, midLong)
                let mapSpan = MKCoordinateSpanMake(spread, spread)
                let mapRegion = MKCoordinateRegion(center: centerLoc, span: mapSpan)
                self.map.setRegion(mapRegion, animated: true)
                
                oldPoints = MyList.locPoints
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

