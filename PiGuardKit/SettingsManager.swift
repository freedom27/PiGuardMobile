//
//  SettingsManager.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 24/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import Foundation

public struct Credentials {
    public let userName: String
    public let password:String
    
    public init(userName: String, password: String) {
        self.userName = userName
        self.password = password
    }
}

public class SettingsManager {
    public static var sharedInstance = SettingsManager()
    
    public var credentials: Credentials?
    public var url: String?
    
    private init() {
        if let username = NSUserDefaults.standardUserDefaults() .objectForKey("username") as? String,
            let password = NSUserDefaults.standardUserDefaults() .objectForKey("password") as? String {
            credentials = Credentials(userName: username, password: password)
        }
        
        if let siteUrl = NSUserDefaults.standardUserDefaults() .objectForKey("siteUrl") as? String {
            url = siteUrl
        }
    }
    
    public var settingsLoaded: Bool {
        return credentials != nil && url != nil
    }
    
    public var baseURL: String? {
        if settingsLoaded {
            return "https://\(url!):2728"
        } else {
            return nil
        }
    }
    
    public var baseURLWithCredentials: String? {
        if let credentials = credentials, let url = url {
            return "https://\(credentials.userName):\(credentials.password)@\(url):2728"
        } else {
            return nil
        }
    }
    
    public func setCredentials(cred: Credentials) {
        credentials = cred
        NSUserDefaults.standardUserDefaults().setValue(credentials?.userName, forKey: "username")
        NSUserDefaults.standardUserDefaults().setValue(credentials?.password, forKey: "password")
    }
    
    public func setURL(siteUrl: String) {
        url = siteUrl
        NSUserDefaults.standardUserDefaults().setValue(siteUrl, forKey: "siteUrl")
    }
}