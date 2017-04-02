//
//  personDetailsViewController.swift
//  DBSKYC
//
//  Created by Abhigyan Singh on 02/04/17.
//  Copyright © 2017 Abhigyan Singh. All rights reserved.
//

import UIKit
import AWSS3

class personDetailsViewController: UIViewController {
    
    
    @IBOutlet var personImg: UIImageView!
    @IBOutlet var fName: UITextField!
    @IBOutlet var lName: UITextField!
    @IBOutlet var linkLabel: UITextField!
    @IBOutlet var familyNameLabel: UITextField!
    @IBOutlet var addressLabel: UITextField!
    @IBOutlet var cityLabel: UITextField!
    @IBOutlet var stateLabel: UITextField!
    @IBOutlet var countryLabel: UITextField!
    @IBOutlet var dobLabel: UITextField!
    @IBOutlet var genderSegment: UISegmentedControl!
    
    let transferManager = AWSS3TransferManager.default()

    func fetchS3(){
        let downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("myImage.jpg")
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest?.bucket = "dbskyc"
        downloadRequest?.key = "\(Config.photoDownloadLink!)"
        downloadRequest?.downloadingFileURL = downloadingFileURL
        transferManager.download(downloadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                    }
                } else {
                    print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                }
                return nil
            }
            print("Download complete for: \(downloadRequest?.key)")
            let downloadOutput = task.result as? UIImage
            self.personImg.image = downloadOutput
            self.fName.text = Config.firstName
            self.lName.text = Config.lastName
            self.linkLabel.text = Config.familyLink
            self.familyNameLabel.text = Config.familyLinkName
            self.addressLabel.text = Config.address
            self.cityLabel.text = Config.city
            self.stateLabel.text = Config.state
            self.countryLabel.text = Config.country
            self.dobLabel.text = Config.dOB
            if Config.gender == "M" {
                self.genderSegment.selectedSegmentIndex = 0
            }
            else {
                self.genderSegment.selectedSegmentIndex = 1
            }
            return nil
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Config.firstName)
        self.fetchS3()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
