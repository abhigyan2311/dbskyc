//
//  searchViewController.swift
//  DBSKYC
//
//  Created by Abhigyan Singh on 02/04/17.
//  Copyright © 2017 Abhigyan Singh. All rights reserved.
//

import UIKit
import AVFoundation
import AWSRekognition
import AWSDynamoDB
import AWSS3

class searchViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imagePicker: UIImagePickerController!
    var photoURL: URL!
    let transferManager = AWSS3TransferManager.default()
    var rekognitionClient: AWSRekognition!
    var faceID: String!
    
    @IBOutlet var nextBTN: UIButton!
    
    @IBOutlet var camView: UIImageView!
    
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
    
    @IBAction func takephotoBTN(_ sender: Any) {
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
    }
    
    @IBAction func searchUserBTN(_ sender: Any) {
        self.awsRekognition()
    }
    
    func dummyImage(){
        let camImage = UIImage(named: "searchFace")
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
    
//    func uploadS3() {
//        let uploadRequest = AWSS3TransferManagerUploadRequest()
//        uploadRequest!.bucket = "dbskyc"
//        uploadRequest!.key = "tempImg.jpg"
//        uploadRequest!.body = photoURL
//        transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
//            if let error = task.error as? NSError {
//                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
//                    switch code {
//                    case .cancelled, .paused:
//                        break
//                    default:
//                        print("Error uploading: \(uploadRequest?.key) Error: \(error)")
//                    }
//                } else {
//                    print("Error uploading: \(uploadRequest?.key) Error: \(error)")
//                }
//                return nil
//            }
//            //S3 upload complete
//            let uploadOutput = task.result
//            print("Upload complete for: \(uploadRequest?.key)")
//            //Call the training function
//            self.awsRekognition()
//            return nil
//        })
//    }
    
    func awsRekognition(){
//        guard let request = AWSRekognitionSearchFacesByImageRequest() else
//        {
//            puts("Unable to initialize AWSRekognitionSearchfacerequest.")
//            return
//        }
//        request.collectionId = "DBSKYC"
//        request.faceMatchThreshold = 70
//        request.maxFaces = 2
//        let mys3 = AWSRekognitionS3Object()
//        mys3?.bucket = "dbskyc"
//        mys3?.name = "tempImg.jpg"
//        let searchImage = AWSRekognitionImage()
//        searchImage?.s3Object = mys3
//        request.image = searchImage
//        rekognitionClient.
//        rekognitionClient.searchFaces(byImage:request) { (response:AWSRekognitionSearchFacesByImageResponse?, error:Error?) in
//            if error == nil
//            {
//                self.faceID = response!.faceMatches?[0].face?.faceId
//                self.fetchDynamoDB()
//                
//            }
//            else {
//                print(error)
//            }
//        }
        faceID = "763bfa4b-fe4c-58c2-8abf-21da0ee40a88"
        self.fetchDynamoDB()
    }
    
    func fetchDynamoDB(){
        dynamoDBObjectMapper.load(kycInfo.self, hashKey: faceID, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else if let resultKyc = task.result as? kycInfo {
                Config.firstName = resultKyc.firstName
                Config.lastName = resultKyc.lastName
                Config.gender = resultKyc.gender
                Config.dOB = resultKyc.dOB
                Config.address = resultKyc.address
                Config.city = resultKyc.city
                Config.state = resultKyc.state
                Config.country = resultKyc.country
                Config.photoDownloadLink = resultKyc.photoDownloadLink
                Config.familyLink = resultKyc.familyLink
                Config.familyLinkName = resultKyc.familyLinkName
                
                self.nextBTN.isHidden = false
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "personDetailsViewController") as! personDetailsViewController
                self.present(nextViewController, animated:true, completion:nil)
                
            }
            return nil
        })

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dummyImage()
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
