//
//  searchViewController.swift
//  DBSKYC
//
//  Created by Abhigyan Singh on 02/04/17.
//  Copyright © 2017 Abhigyan Singh. All rights reserved.
//

import UIKit
import AWSRekognition
import AWSDynamoDB
import AWSS3

class searchViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imagePicker: UIImagePickerController!
    var photoURL: URL!
    let transferManager = AWSS3TransferManager.default()
    var rekognitionClient: AWSRekognition!
    @IBOutlet var camView: UIImageView!
    
    @IBAction func takephotoBTN(_ sender: Any) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
