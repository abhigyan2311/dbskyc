//
//  ViewController.swift
//  DBSKYC
//
//  Created by Abhigyan Singh on 01/04/17.
//  Copyright © 2017 Abhigyan Singh. All rights reserved.
//

import UIKit
import AWSS3
import AVFoundation

class RegistrationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagePicker: UIImagePickerController!
    var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var photoURL: URL!

    @IBOutlet var camView: UIImageView!
    @IBAction func takePic(_ sender: UIButton) {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch status {
        case .authorized:
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
                imagePicker =  UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.allowsEditing = true
                imagePicker.sourceType = .camera
                present(imagePicker, animated: true, completion: nil)
            }
            break
            
        case .denied, .restricted :
            let titleStr = "Camera Access Needed!"
            let messageStr = "Please enable Camera access in app settings for uploading media."
            let cancelStr = "Cancel"
            let settingStr = "App Settings"
            let alert = UIAlertController(
                title: titleStr,
                message: messageStr,
                preferredStyle: UIAlertControllerStyle.alert
            )
            alert.addAction(UIAlertAction(title: cancelStr, style: .cancel, handler: { (alert) -> Void in
            }))
            alert.addAction(UIAlertAction(title: settingStr, style: .default, handler: { (alert) -> Void in
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            self.present(alert, animated: true, completion: nil)
            break
            
        //handle denied status
        case .notDetermined:
            // ask for permissions
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == false{
                }else{
                    self.imagePicker.sourceType = .camera
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            })
        }
        print(2221212)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        camView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        //this block of code grabs the path of the file
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory,nsUserDomainMask, true)
        if let dirPath = paths.first
        {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("Image2.png")
            let image    = UIImage(contentsOfFile: imageURL.path)
            print(imageURL.description)
            // Do whatever you want with the image
        }
//        let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
//        let imagePath =  imageURL.path!
//        let localPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(imagePath)
//        
//        //this block of code adds data to the above path
//        let path = localPath?.relativePath
//        let imageName = info[UIImagePickerControllerOriginalImage] as! UIImage
//        let data = UIImagePNGRepresentation(imageName)
//        let fileUrl = NSURL(string: imagePath)
//        do {
//            try data?.write(to: fileUrl as! URL, options: .noFileProtection)
//            print("Written to disk")
//        }
//        catch let error as NSError {
//            print(error.description)
//        }
//        
//        //this block grabs the NSURL so you can use it in CKASSET
//        photoURL = NSURL(fileURLWithPath: path!) as URL
//        print(photoURL)
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

