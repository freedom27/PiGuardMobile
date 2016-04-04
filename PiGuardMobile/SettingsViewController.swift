//
//  SettingsViewController.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 24/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import UIKit
import PiGuardKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var urlField: UITextField!
    
    var completionHandler: (()->Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let credentials = SettingsManager.sharedInstance.credentials {
            usernameField.text = credentials.userName
            passwordField.text = credentials.password
        }
        
        if let url = SettingsManager.sharedInstance.url {
            urlField.text = url
        }
    }
    
    @IBAction func clear(sender: AnyObject) {
        usernameField.text = ""
        passwordField.text = ""
        urlField.text = ""
    }
    
    @IBAction func save(sender: AnyObject) {
        guard let username = usernameField.text where username != "",
            let password = passwordField.text where password != "",
            let url = urlField.text where url != "" else {
                return
        }
        
        let credentials = Credentials(userName: username, password: password)
        SettingsManager.sharedInstance.setCredentials(credentials)
        SettingsManager.sharedInstance.setURL(url)
        
        completionHandler?()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
