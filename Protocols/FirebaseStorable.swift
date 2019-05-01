//
//  FirebaseStorable.swift
//
//
//  Created by Dmitriy Poluriezov on 5/1/19.
//

import UIKit

typealias StorageImageUploadCallback = (String) -> Void
typealias StorageImageDownloadSuccessCallback = (UIImage) -> Void
typealias StorageImageDownloadFailureCallback = (String?) -> Void

protocol FirebaseStorable: class {
    // MARK: Storage methods
    func store(documentImage: UIImage, success: StorageImageUploadCallback?, failure: StorageImageUploadCallback?)
    func downloadStoredDocumentImage(by name: String, success: StorageImageDownloadSuccessCallback?, failure: StorageImageDownloadFailureCallback?)
    func removeDocumentImage(by name: Int)
    // MARK: Database methods
    func saveToDatabase(document: [String: Any], creationTimestamp: Int)
    func removeDocumentFromDatabase(by name: Int)
    func getAllDocumentsFromDatabase(completion: @escaping ((_ documents: [Document]?, _ error: Error?) -> Void))
}
