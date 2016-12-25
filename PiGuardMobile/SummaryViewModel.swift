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
    
    fileprivate let _dateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "dd MMM-HH:mm"
        return formatter
    }()
    
    var errorHandler: ((Error)->Void)?
    
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
    
    var motionHistory: Dynamic<[(Date, String)]>
    
    var systemOn: Dynamic<Bool>
    var surveillanceOn: Dynamic<Bool>
    
    var streamingURL: URL? {
        if let baseURL = SettingsManager.sharedInstance.baseURLWithCredentials {
            return URL(string: "\(baseURL)/live_video")!
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
        motionHistory = Dynamic(value: [(Date, String)]())
        systemOn = Dynamic(value: false)
        surveillanceOn = Dynamic(value: false)
    }
    
    func loadData() {
        PiGuardKit.statuses(24).then { statuses in
            let status = statuses[0]
            DispatchQueue.main.async {
                let dateTime = self._dateFormatter.string(from: status.timestamp)
                self.date.value = dateTime.substring(to: dateTime.range(of: "-")!.lowerBound)
                self.time.value = dateTime.substring(from: dateTime.index(dateTime.range(of: "-")!.lowerBound, offsetBy: 1))
                self.temperature.value = status.temperature != nil ? "\(status.temperature!)°C" : nil
                self.humidity.value = status.humidity != nil ? "\(status.humidity!)%" : nil
                self.pressure.value = status.pressure != nil ? "\(status.pressure!)mbar" : nil
                self.co2.value = status.co2 != nil ? "\(status.co2!)ppm" : nil
                
                self.motionHistory.value = statuses.filter{$0.motion ?? false}.map{($0.timestamp, $0.pictureName)}
                
                if let baseURL = SettingsManager.sharedInstance.baseURLWithCredentials {
                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
                        guard let imageUrl = URL(string: "\(baseURL)/image/\(status.pictureName)"),
                            let imageData = try? Data(contentsOf: imageUrl) else { return }
                        DispatchQueue.main.async {
                            self.picture.value = UIImage(data: imageData)
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.prepareHistoryData(statuses)
            }
        }.error {
            self.errorHandler?($0)
        }
    }
    
    func loadStatus() {
        PiGuardKit.systemStatus().then(prepareStatus).error{ print($0) }
    }
    
    func prepareStatus(_ systemStatus: SystemStatus) {
        DispatchQueue.main.async {
            self.systemOn.value = systemStatus.status == .started
            self.surveillanceOn.value = systemStatus.mode == .Surveillance
        }
    }
    
    func prepareHistoryData(_ statuses: [Status]) {
        let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter
        }()
        self.temperatureHistory.value = statuses.filter{$0.temperature != nil}.map{($0.temperature!, timeFormatter.string(from: $0.timestamp))}.reversed()
        self.humidityHistory.value = statuses.filter{$0.humidity != nil}.map{($0.humidity!, timeFormatter.string(from: $0.timestamp))}.reversed()
        self.pressureHistory.value = statuses.filter{$0.pressure != nil}.map{($0.pressure!, timeFormatter.string(from: $0.timestamp))}.reversed()
        self.co2History.value = statuses.filter{$0.co2 != nil}.map{($0.co2!, timeFormatter.string(from: $0.timestamp))}.reversed()
    }
}
