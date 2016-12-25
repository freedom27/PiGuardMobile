//
//  PiGuard.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 06/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum CommandType: String {
    case Start = "/command/start"
    case Stop = "/command/stop"
    case Status = "/command/status"
    case Snapshot = "/command/snapshot"
    case Monitor = "/command/monitor"
    case Surveil = "/command/surveil"
}

public struct Status {
    public let timestamp: Date
    public let pictureName: String
    public let temperature: Double?
    public let humidity: Double?
    public let pressure: Double?
    public let co2: Int?
    public let motion: Bool?
}

public struct SystemStatus {
    public enum Status {
        case started
        case stopped
    }
    
    public enum Mode: String {
        case Monitoring = "monitoring"
        case Surveillance = "surveillance"
    }
    
    public var status: Status
    public var mode: Mode
}

public enum PiGuardError: Error {
    case emptyResponseError
    case invalidStatus
    case settingsMissing
}

private let _dateFormatter: DateFormatter = {
    var formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

private func statusFromJson(_ json: JSON) -> Status? {
    guard let timestamp = json["timestamp"].string,
        let pictureName = json["picture"].string else {
            return nil
    }
    
    let date = _dateFormatter.date(from: timestamp)
    return Status(timestamp: date!, pictureName: pictureName, temperature: json["temperature"].double, humidity: json["humidity"].double, pressure: json["pressure"].double, co2: json["co2"].int, motion: json["motion"].bool)
}

public func systemStatusFromJson(_ json: JSON) throws -> SystemStatus {
    if let started: Bool = json["response"]["system_status"]["started"].bool,
        let strMode: String = json["response"]["system_status"]["mode"].string,
        let mode = SystemStatus.Mode(rawValue: strMode) {
        return SystemStatus(status: started ? .started : .stopped, mode: mode)
    } else {
        throw PiGuardError.invalidStatus
    }
}


private func authenticationToken() -> String? {
    guard let username = SettingsManager.sharedInstance.credentials?.userName,
        let password = SettingsManager.sharedInstance.credentials?.password else {
        return nil
    }
    
    let loginString = "\(username):\(password)"
    let loginData: Data = loginString.data(using: String.Encoding.utf8)!
    let base64LoginString = loginData.base64EncodedString(options: [])
    
    return base64LoginString
}

private func createRequestForAPI(_ api: String) throws -> URLRequest {
    guard let baseURL = SettingsManager.sharedInstance.baseURL else {
        throw PiGuardError.settingsMissing
    }
    
    let url = URL(string: "\(baseURL)\(api)")
    let request = NSMutableURLRequest(url: url!)
    request.httpMethod = "GET"
    if let authToken = authenticationToken() {
        request.setValue("Basic \(authToken)", forHTTPHeaderField: "Authorization")
    }
    
    return request as URLRequest
}

private func request(_ apiPath: String) -> Promise<JSON> {
    return Promise<JSON> { success, fail in
        let request = try createRequestForAPI(apiPath)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                fail(error)
            } else if let data = data {
                success(JSON(data: data))
            } else {
                fail(PiGuardError.emptyResponseError)
            }
        }) 
        task.resume()
    }
}

public func command(_ command: CommandType) -> Promise<JSON> {
    return request(command.rawValue)
}

public func statuses(_ hours: Int) -> Promise<[Status]> {
    let apiPath = "/statuses/\(hours)"
    return request(apiPath).then { (jsonObjects: JSON) -> [Status] in
        return jsonObjects["statuses"].arrayValue.flatMap(statusFromJson)
    }
}

public func systemStatus() -> Promise<SystemStatus> {
    return command(.Status).then(systemStatusFromJson)
}

