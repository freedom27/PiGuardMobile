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
    
    fileprivate let _dateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm:ss"
        return formatter
    }()
    
    fileprivate let _downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Download Queue"
        return queue
    }()
    var _pictureInDownloadForCell = [MotionPictureCell: ImageDownloadOperation]()
    
    var motions = [(Date, String)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

// MARK: - UITableViewDataSource
extension MotionPicturesViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return motions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "motionPicture", for: indexPath) as! MotionPictureCell
        
        _pictureInDownloadForCell.removeValue(forKey: cell)?.cancel()
        
        let (motionDate, motionPicture) = motions[indexPath.row]
        
        cell.timestampLabel.text = _dateFormatter.string(from: motionDate)
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.width * (3/4)
    }
    
}
