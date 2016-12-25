//
//  ImageDownloadOperation.swift
//  PiGuardStream
//
//  Created by Stefano Vettor on 20/01/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import UIKit

class ImageDownloadOperation: Operation {
    
    let imageURL: URL?
    let imageUpdateBlock: (UIImage)->()
    
    init(url: String, imageUpdateBlock: @escaping (UIImage)->()) {
        self.imageURL = URL(string: url)
        self.imageUpdateBlock = imageUpdateBlock
    }
    
    override func main() {
        guard !self.isCancelled,
            let url = imageURL,
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data) else { return }
        
        print("downloading....")
        if !self.isCancelled {
            DispatchQueue.main.async {
                self.imageUpdateBlock(image)
            }
        }
    }
}
