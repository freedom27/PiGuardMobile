//
//  MotionPicturesViewController.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 10/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import UIKit
import PiGuardKit

class MotionPicturesViewController: UITableViewController {
    
    private let _dateFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm:ss"
        return formatter
    }()
    
    private let _downloadQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Download Queue"
        return queue
    }()
    var _pictureInDownloadForCell = [MotionPictureCell: ImageDownloadOperation]()
    
    var motions = [(NSDate, String)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

// MARK: - UITableViewDataSource
extension MotionPicturesViewController {
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return motions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("motionPicture", forIndexPath: indexPath) as! MotionPictureCell
        
        _pictureInDownloadForCell.removeValueForKey(cell)?.cancel()
        
        let (motionDate, motionPicture) = motions[indexPath.row]
        
        cell.timestampLabel.text = _dateFormatter.stringFromDate(motionDate)
        cell.picture.image = nil
        if let baseURL = SettingsManager.sharedInstance.baseURLWithCredentials {
            let downloadOperation = ImageDownloadOperation(url: "\(baseURL)/image/\(motionPicture)") { image in
                cell.picture.image = image
            }
            _pictureInDownloadForCell[cell] = downloadOperation
            _downloadQueue.addOperation(downloadOperation)
        }
        
        return cell
    }
}

//MARK: UITableViewDelegate
extension MotionPicturesViewController {
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UIScreen.mainScreen().bounds.width * (3/4)
    }
    
}
