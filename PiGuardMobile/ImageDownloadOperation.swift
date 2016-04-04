//
//  ImageDownloadOperation.swift
//  PiGuardStream
//
//  Created by Stefano Vettor on 20/01/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import UIKit

class ImageDownloadOperation: NSOperation {
    
    let imageURL: NSURL?
    let imageUpdateBlock: (UIImage)->()
    
    init(url: String, imageUpdateBlock: (UIImage)->()) {
        self.imageURL = NSURL(string: url)
        self.imageUpdateBlock = imageUpdateBlock
    }
    
    override func main() {
        guard !self.cancelled,
            let url = imageURL,
            data = NSData(contentsOfURL: url),
            image = UIImage(data: data) else { return }
        
        print("downloading....")
        if !self.cancelled {
            dispatch_async(dispatch_get_main_queue()) {
                self.imageUpdateBlock(image)
            }
        }
    }
}