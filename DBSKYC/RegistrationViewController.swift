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

class RegistrationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let pickerData = ["Father","Mother","Spouse"]
    
    var tap :UITapGestureRecognizer!
    @IBOutlet var firstName: UITextField!
    @IBOutlet var lastName: UITextField!
    @IBOutlet var gender: UISegmentedControl!
    @IBOutlet var dOB: UITextField!
    @IBOutlet var address: UITextField!
    @IBOutlet var city: UITextField!
    @IBOutlet var state: UITextField!
    @IBOutlet var country: UITextField!
    @IBOutlet var familyLink: UITextField!
    @IBOutlet var familyLinkName: UITextField!
    @IBOutlet var dobPick: UIDatePicker!
    @IBOutlet var familyLinkPick: UIPickerView!
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var successLabel: UILabel!
    
    var userGender = "M"
    
    var imagePicker: UIImagePickerController!
    var photoURL: URL!
    let transferManager = AWSS3TransferManager.default()
    var rekognitionClient: AWSRekognition!
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
    var faceId: String!
    var pLink: String!

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
    
    func uploadS3() {
        let currentDate = Int(NSDate().timeIntervalSince1970 * 100000)
        pLink = "\(self.firstName.text!)_\(self.lastName.text!)_\(currentDate).jpg"
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest!.bucket = "dbskyc"
        uploadRequest!.key = pLink
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
                self.savetoDB()
            }
            else {
                print(error)
            }
        }
    }
    
    func savetoDB(){
        let myKyc = kycInfo()
        myKyc?.KycId = self.faceId
        myKyc?.firstName = self.firstName.text
        myKyc?.lastName = self.lastName.text
        myKyc?.gender = self.userGender
        myKyc?.dOB = self.dOB.text
        myKyc?.photoDownloadLink = pLink
        myKyc?.address = self.address.text
        myKyc?.city = self.city.text
        myKyc?.state = self.state.text
        myKyc?.country = self.country.text
        myKyc?.familyLink = self.familyLink.text
        myKyc?.familyLinkName = self.familyLinkName.text
        dynamoDBObjectMapper.save(myKyc!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else {
                self.loader.hidesWhenStopped = true
                self.loader.stopAnimating()
                self.successLabel.isHidden = false
            }
            return nil
        })
    }
    
    
    @IBAction func save(sender:UIButton){
        self.successLabel.isHidden = true
        self.loader.startAnimating()
        self.uploadS3()
    }

    
    @IBAction func genderSelect(_ sender: AnyObject) {
        if self.gender.selectedSegmentIndex == 0{
            self.userGender = "M"
        }
        else{
            self.userGender = "F"
        }
    }

    
    @IBAction func pickerChange(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        var strDate = dateFormatter.string(from: dobPick.date)
        print(strDate)
        dOB.text = strDate
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tap = UITapGestureRecognizer(target: self, action:#selector(self.tapped))
        self.view.addGestureRecognizer(tap)
        if textField == self.dOB{
            dobPick = UIDatePicker()
            dobPick.datePickerMode = UIDatePickerMode.date
            dobPick.backgroundColor = UIColor.white
            dobPick.addTarget(self, action: (Selector(("pickerChange"))), for: .valueChanged)
            textField.inputView = self.dobPick
            dobPick.isHidden = false
        }else if textField == self.familyLink{
            self.familyLinkPick.isHidden = false
        }
    }
    
    func tapped(){
        self.firstName.resignFirstResponder()
        self.lastName.resignFirstResponder()
        self.address.resignFirstResponder()
        self.city.resignFirstResponder()
        self.state.resignFirstResponder()
        self.country.resignFirstResponder()
        self.dOB.resignFirstResponder()
        self.familyLink.resignFirstResponder()
        self.familyLinkName.resignFirstResponder()
        self.dobPick.isHidden = true
        self.familyLinkPick.isHidden = true
        view.removeGestureRecognizer(tap)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.tapped()
        textField.resignFirstResponder()
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        familyLink.text = pickerData[row]
        self.tapped()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dummyImage()
        
        familyLinkPick.delegate = self
        familyLinkPick.dataSource = self
        
        rekognitionClient = AWSRekognition.default()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

