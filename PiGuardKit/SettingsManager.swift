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

open class SettingsManager {
    open static var sharedInstance = SettingsManager()
    
    open var credentials: Credentials?
    open var url: String?
    
    fileprivate init() {
        if let username = UserDefaults.standard .object(forKey: "username") as? String,
            let password = UserDefaults.standard .object(forKey: "password") as? String {
            credentials = Credentials(userName: username, password: password)
        }
        
        if let siteUrl = UserDefaults.standard .object(forKey: "siteUrl") as? String {
            url = siteUrl
        }
    }
    
    open var settingsLoaded: Bool {
        return credentials != nil && url != nil
    }
    
    open var baseURL: String? {
        if settingsLoaded {
            return "https://\(url!):2728"
        } else {
            return nil
        }
    }
    
    open var baseURLWithCredentials: String? {
        if let credentials = credentials, let url = url {
            return "https://\(credentials.userName):\(credentials.password)@\(url):2728"
        } else {
            return nil
        }
    }
    
    open func setCredentials(_ cred: Credentials) {
        credentials = cred
        UserDefaults.standard.setValue(credentials?.userName, forKey: "username")
        UserDefaults.standard.setValue(credentials?.password, forKey: "password")
    }
    
    open func setURL(_ siteUrl: String) {
        url = siteUrl
        UserDefaults.standard.setValue(siteUrl, forKey: "siteUrl")
    }
}
