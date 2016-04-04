//
//  PiGuard.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 06/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import Foundation

public enum CommandType: String {
    case Start = "/command/start"
    case Stop = "/command/stop"
    case Status = "/command/status"
    case Snapshot = "/command/snapshot"
    case Monitor = "/command/monitor"
    case Surveil = "/command/surveil"
}

public struct Status {
    public let timestamp: NSDate
    public let pictureName: String
    public let temperature: Double?
    public let humidity: Double?
    public let pressure: Double?
    public let co2: Int?
    public let motion: Bool?
}

public struct SystemStatus {
    public enum Status {
        case Started
        case Stopped
    }
    
    public enum Mode: String {
        case Monitoring = "monitoring"
        case Surveillance = "surveillance"
    }
    
    public var status: Status
    public var mode: Mode
}

public enum PiGuardError: ErrorType {
    case EmptyResponseError
    case InvalidStatus
    case SettingsMissing
}

private let _dateFormatter: NSDateFormatter = {
    var formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

private func statusFromJson(json: JSON) -> Status? {
    guard let timestamp = json["timestamp"].string,
        let pictureName = json["picture"].string else {
            return nil
    }
    
    let date = _dateFormatter.dateFromString(timestamp)
    return Status(timestamp: date!, pictureName: pictureName, temperature: json["temperature"], humidity: json["humidity"], pressure: json["pressure"], co2: json["co2"], motion: json["motion"])
}

public func systemStatusFromJson(json: JSON) throws -> SystemStatus {
    if let started: Bool = json["response"]["system_status"]["started"],
        let strMode: String = json["response"]["system_status"]["mode"],
        let mode = SystemStatus.Mode(rawValue: strMode) {
        return SystemStatus(status: started ? .Started : .Stopped, mode: mode)
    } else {
        throw PiGuardError.InvalidStatus
    }
}


private func authenticationToken() -> String? {
    guard let username = SettingsManager.sharedInstance.credentials?.userName,
        let password = SettingsManager.sharedInstance.credentials?.password else {
        return nil
    }
    
    let loginString = "\(username):\(password)"
    let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
    let base64LoginString = loginData.base64EncodedStringWithOptions([])
    
    return base64LoginString
}

private func createRequestForAPI(api: String) throws -> NSURLRequest {
    guard let baseURL = SettingsManager.sharedInstance.baseURL else {
        throw PiGuardError.SettingsMissing
    }
    
    let url = NSURL(string: "\(baseURL)\(api)")
    let request = NSMutableURLRequest(URL: url!)
    request.HTTPMethod = "GET"
    if let authToken = authenticationToken() {
        request.setValue("Basic \(authToken)", forHTTPHeaderField: "Authorization")
    }
    
    return request
}

private func request(apiPath: String) -> Promise<JSON> {
    return Promise<JSON> { success, fail in
        let request = try createRequestForAPI(apiPath)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                fail(error)
            } else if let data = data {
                success(JSON(data: data))
            } else {
                fail(PiGuardError.EmptyResponseError)
            }
        }
        task.resume()
    }
}

public func command(command: CommandType) -> Promise<JSON> {
    return request(command.rawValue)
}

public func statuses(hours: Int) -> Promise<[Status]> {
    let apiPath = "/statuses/\(hours)"
    return request(apiPath).then { (jsonObjects: JSON) -> [Status] in
        return jsonObjects["statuses"].flatMap(statusFromJson)
    }
}

public func systemStatus() -> Promise<SystemStatus> {
    return command(.Status).then(systemStatusFromJson)
}

