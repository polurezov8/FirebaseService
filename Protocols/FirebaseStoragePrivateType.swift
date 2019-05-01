//
//  FirebaseStorageServicePrivateType.swift
//
//
//  Created by Dmitriy Poluriezov on 5/1/19.
//

import Firebase
import FirebaseDatabase
import FirebaseStorage

protocol FirebaseStoragePrivateType: class {
    var firebaseStorage: StorageReference { get set }
    var firebaseDatabase: DatabaseReference { get set }
}
