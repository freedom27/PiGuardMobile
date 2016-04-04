//
//  SummaryViewViewModel.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 06/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import UIKit
import PiGuardKit

class SummaryViewModel {
    
    private let _dateFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "dd MMM-HH:mm"
        return formatter
    }()
    
    var errorHandler: (ErrorType->Void)?
    
    var picture: Dynamic<UIImage?>
    var date: Dynamic<String>
    var time: Dynamic<String>
    var temperature: Dynamic<String?>
    var humidity: Dynamic<String?>
    var pressure: Dynamic<String?>
    var co2: Dynamic<String?>
    
    var temperatureHistory: Dynamic<[(Double, String)]>
    var humidityHistory: Dynamic<[(Double, String)]>
    var pressureHistory: Dynamic<[(Double, String)]>
    var co2History: Dynamic<[(Int, String)]>
    
    var motionHistory: Dynamic<[(NSDate, String)]>
    
    var systemOn: Dynamic<Bool>
    var surveillanceOn: Dynamic<Bool>
    
    var streamingURL: NSURL? {
        if let baseURL = SettingsManager.sharedInstance.baseURLWithCredentials {
            return NSURL(string: "\(baseURL)/live_video")!
        } else {
            return nil
        }
    }
    
    init() {
        picture = Dynamic(value: nil)
        
        date = Dynamic(value: "01 Jan")
        time = Dynamic(value: "00:00")
        temperature = Dynamic(value: nil)
        humidity = Dynamic(value: nil)
        pressure = Dynamic(value: nil)
        co2 = Dynamic(value: nil)
        
        temperatureHistory = Dynamic(value: [(Double, String)]())
        humidityHistory = Dynamic(value: [(Double, String)]())
        pressureHistory = Dynamic(value: [(Double, String)]())
        co2History = Dynamic(value: [(Int, String)]())
        motionHistory = Dynamic(value: [(NSDate, String)]())
        systemOn = Dynamic(value: false)
        surveillanceOn = Dynamic(value: false)
    }
    
    func loadData() {
        PiGuardKit.statuses(24).then { statuses in
            let status = statuses[0]
            dispatch_async(dispatch_get_main_queue()) {
                let dateTime = self._dateFormatter.stringFromDate(status.timestamp)
                self.date.value = dateTime.substringToIndex(dateTime.rangeOfString("-")!.startIndex)
                self.time.value = dateTime.substringFromIndex(dateTime.rangeOfString("-")!.startIndex.advancedBy(1))
                self.temperature.value = status.temperature != nil ? "\(status.temperature!)°C" : nil
                self.humidity.value = status.humidity != nil ? "\(status.humidity!)%" : nil
                self.pressure.value = status.pressure != nil ? "\(status.pressure!)mbar" : nil
                self.co2.value = status.co2 != nil ? "\(status.co2!)ppm" : nil
                
                self.motionHistory.value = statuses.filter{$0.motion ?? false}.map{($0.timestamp, $0.pictureName)}
                
                if let baseURL = SettingsManager.sharedInstance.baseURLWithCredentials {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                        guard let imageUrl = NSURL(string: "\(baseURL)/image/\(status.pictureName)"),
                            let imageData = NSData(contentsOfURL: imageUrl) else { return }
                        dispatch_async(dispatch_get_main_queue()) {
                            self.picture.value = UIImage(data: imageData)
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.prepareHistoryData(statuses)
            }
        }.error {
            self.errorHandler?($0)
        }
    }
    
    func loadStatus() {
        PiGuardKit.systemStatus().then(prepareStatus).error{ print($0) }
    }
    
    func prepareStatus(systemStatus: SystemStatus) {
        dispatch_async(dispatch_get_main_queue()) {
            self.systemOn.value = systemStatus.status == .Started
            self.surveillanceOn.value = systemStatus.mode == .Surveillance
        }
    }
    
    func prepareHistoryData(statuses: [Status]) {
        let timeFormatter: NSDateFormatter = {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter
        }()
        self.temperatureHistory.value = statuses.filter{$0.temperature != nil}.map{($0.temperature!, timeFormatter.stringFromDate($0.timestamp))}.reverse()
        self.humidityHistory.value = statuses.filter{$0.humidity != nil}.map{($0.humidity!, timeFormatter.stringFromDate($0.timestamp))}.reverse()
        self.pressureHistory.value = statuses.filter{$0.pressure != nil}.map{($0.pressure!, timeFormatter.stringFromDate($0.timestamp))}.reverse()
        self.co2History.value = statuses.filter{$0.co2 != nil}.map{($0.co2!, timeFormatter.stringFromDate($0.timestamp))}.reverse()
    }
}