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
import AWSDynamoDB
import AWSRekognition

class RegistrationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagePicker: UIImagePickerController!
    var photoURL: URL!
    let transferManager = AWSS3TransferManager.default()
    var rekognitionClient: AWSRekognition!
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
    var faceId: String!

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
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        
        let camImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory,nsUserDomainMask, true)
        

        if let dirPath = paths.first{
            let writePath = URL(fileURLWithPath: dirPath).appendingPathComponent("Image2.png")
            do {
                    try UIImagePNGRepresentation(camImage!)!.write(to: writePath)
                    print("Image Added Successfully")
                } catch {
                    print(error)
                }
            
            photoURL = URL(fileURLWithPath: dirPath).appendingPathComponent("Image2.png")
            let image    = UIImage(contentsOfFile: photoURL.path)
            camView.image = image
        }
            // Do whatever you want with the image
    }
    
    func dummyImage(){
        let camImage = UIImage(named: "face")
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory,nsUserDomainMask, true)
        if let dirPath = paths.first{
            let writePath = URL(fileURLWithPath: dirPath).appendingPathComponent("Image2.png")
            do {
                try UIImagePNGRepresentation(camImage!)!.write(to: writePath)
                print("Image Added Successfully")
            } catch {
                print(error)
            }
            photoURL = URL(fileURLWithPath: dirPath).appendingPathComponent("Image2.png")
            let image    = UIImage(contentsOfFile: photoURL.path)
            camView.image = image
        }
    }
    
    @IBAction func uploadS3(_ sender: Any) {
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest!.bucket = "dbskyc"
        uploadRequest!.key = "testImg.png"
        print(photoURL)
        uploadRequest!.body = photoURL
        transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error uploading: \(uploadRequest?.key) Error: \(error)")
                    }
                } else {
                    print("Error uploading: \(uploadRequest?.key) Error: \(error)")
                }
                return nil
            }
            //S3 upload complete
            let uploadOutput = task.result
            print("Upload complete for: \(uploadRequest?.key)")
            //Call the training function
            self.awsRekognition()
            return nil
        })
    }
    
    func awsRekognition(){
        guard let request = AWSRekognitionIndexFacesRequest() else
        {
            puts("Unable to initialize AWSRekognitionindexFaceRequest.")
            return
        }
        request.collectionId = "DBSKYC"
        request.detectionAttributes = ["ALL", "DEFAULT"]
        request.externalImageId = "testImg"
        let sourceImage = camView.image
        let image = AWSRekognitionImage()
        image!.bytes = UIImageJPEGRepresentation(sourceImage!, 0.7)
        request.image = image
        rekognitionClient.indexFaces(request) { (response:AWSRekognitionIndexFacesResponse?, error:Error?) in
            if error == nil
            {
                //Trained and got the face ID
                print(response!.faceRecords?[0].face?.faceId)
                self.faceId = (response!.faceRecords?[0].face?.faceId)!
            }
            else {
                print(error)
            }
        }
    }
    
    func savetoDB(){

        let currentDate = (NSDate().timeIntervalSince1970 * 1000)
        
        let myKyc = kycInfo()
        myKyc?.KycId = "9433-qsjd23-343"
        myKyc?.firstName = "Abhigyan"
        myKyc?.lastName = "Singh"
        myKyc?.gender = "M"
        myKyc?.dOB = "2017-11-23"
        myKyc?.photoDownloadLink = "Abhigyan_Singh_\(currentDate)"
        myKyc?.address = "VIT"
        myKyc?.city = "Vellore"
        myKyc?.state = "Tamil Nadu"
        myKyc?.country = "India"
        myKyc?.familyLink = "father"
        myKyc?.familyLinkName = "Ajai Singh"
        
        dynamoDBObjectMapper.save(myKyc!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else {
                print(task.result!)
            }
            return nil
        })
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dummyImage()
        
        rekognitionClient = AWSRekognition.default()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

