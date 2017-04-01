//
//  ViewController.swift
//  DBSKYC
//
//  Created by Abhigyan Singh on 01/04/17.
//  Copyright © 2017 Abhigyan Singh. All rights reserved.
//

import UIKit
import AWSS3

class RegistrationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagePicker: UIImagePickerController!
    var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var photoURL: URL!

    @IBOutlet var camView: UIImageView!
    @IBAction func takePic(_ sender: Any) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        camView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        //this block of code grabs the path of the file
        let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        let imagePath =  imageURL.path!
        let localPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(imagePath)
        
        //this block of code adds data to the above path
        let path = localPath?.relativePath
        let imageName = info[UIImagePickerControllerOriginalImage] as! UIImage
        let data = UIImagePNGRepresentation(imageName)
        let fileUrl = NSURL(string: imagePath)
        do {
            try data?.write(to: fileUrl as! URL, options: .noFileProtection)
            print("Written to disk")
        }
        catch let error as NSError {
            print(error.description)
        }
        
        //this block grabs the NSURL so you can use it in CKASSET
        photoURL = NSURL(fileURLWithPath: path!) as URL
        print(photoURL)
    }
    
    @IBAction func uploadS3(_ sender: Any) {
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, progress) in DispatchQueue.main.async(execute: {
            // Do something e.g. Update a progress bar.
        })
        }
        self.completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                print("Uploaded")
            })
        }
        let  transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadFile(photoURL,
                                   bucket: S3BucketName,
                                   key: "iosImg",
                                   contentType: "image/png",
                                   expression: expression,
                                   completionHandler: completionHandler).continueWith { (task) -> AnyObject! in
                                    if let error = task.error {
                                        print("Error: \(error.localizedDescription)")
                                    }
                                    
                                    if let _ = task.result {
                                        // Do something with uploadTask.
                                    }
                                    
                                    return nil;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

