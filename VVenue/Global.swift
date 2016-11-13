//
//  Global.swift
//  VVenue
//
//  Created by Cassidy Wang on 11/13/16.
//  Copyright © 2016 Cassidy Wang. All rights reserved.
//

import Foundation
import Alamofire

enum FaceAPIResult<AnyObject, Error: NSError> {
    case Success(AnyObject)
    case Failure(Error)
}

var personGroupID: String = "id1"
var currentKey: String = ""
