//
//  DynamoDBClass.swift
//  DBSKYC
//
//  Created by Abhigyan Singh on 01/04/17.
//  Copyright © 2017 Abhigyan Singh. All rights reserved.
//

import Foundation
import AWSDynamoDB

class kycInfo : AWSDynamoDBObjectModel, AWSDynamoDBModeling  {
    var KycId:String?
    var firstName:String?
    var lastName:String?
    var gender:String?
    var dOB:String?
    var photoDownloadLink:String?
    var address: String?
    var city: String?
    var state: String?
    var country:String?
    var familyLink:String?
    var familyLinkName: String?
    
    class func dynamoDBTableName() -> String {
        return "KycInformation"
    }
    
    class func hashKeyAttribute() -> String {
        return "KycId"
    }
}
