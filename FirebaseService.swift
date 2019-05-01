//
//  FirebaseService.swift
//
//
//  Created by Dmitriy Poluriezov on 5/1/19.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseStorage

// MARK: - Constants
private enum Constants {
    static let firebaseStoragePath = "FIREBASE APP PATH"
    static let storageFolderPath = "documentImages/"
    static let databaseFolderPath = "documents/"
    static let creationDateKey = "creationDate"
    static let creationTimestampKey = "creationTimestamp"
    static let imageLinkKey = "imageLink"
}

final class FirebaseService: FirebaseStoragePrivateType {

    // MARK: - Singleton instance
    static let sharedInstance = FirebaseService()

    // MARK: - Initialization
    private init() {
    }

    // MARK: - FirebaseStoragePrivateType
    lazy var firebaseStorage: StorageReference = Storage.storage().reference(forURL: Constants.firebaseStoragePath)
    lazy var firebaseDatabase: DatabaseReference = Database.database().reference()
}

// MARK: - FirebaseStorable
extension DataManager: FirebaseStorable {
    // MARK: Storage methods
    func store(documentImage: UIImage, success: StorageImageUploadCallback?, failure: StorageImageUploadCallback?) {
        let currentTimestamp = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .medium)
        let currentTimestampWithMiliseconds = Date().millisecondsSince1970
        guard let imageData = documentImage.jpegData(compressionQuality: 1.0) else {
            return
        }

        let imageStorageReference = firebaseStorage.child("\(Constants.storageFolderPath)\(currentTimestampWithMiliseconds).jpg")

        imageStorageReference.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                failure?("Image upload failed")
                return
            }

            imageStorageReference.downloadURL(completion: { [weak self] url, error in
                guard error == nil, let urlString = url?.absoluteString else {
                    failure?("Image url is missing")
                    return
                }

                let document = [Constants.creationDateKey: currentTimestamp, Constants.imageLinkKey: urlString, Constants.creationTimestampKey: currentTimestampWithMiliseconds] as [String: Any]
                self?.saveToDatabase(document: document, creationTimestamp: currentTimestampWithMiliseconds)
                success?(urlString)
            })
        }
    }

    func downloadStoredDocumentImage(by name: String, success: StorageImageDownloadSuccessCallback?, failure: StorageImageDownloadFailureCallback?) {
        let imageStorageReference = firebaseStorage.child("\(name).jpg")

        imageStorageReference.getData(maxSize: 15 * 1024 * 1024) { data, error in
            guard error == nil else {
                failure?(error?.localizedDescription)
                return
            }

            guard let imageData = data, let image = UIImage(data: imageData) else {
                failure?("Error converting image data after download")
                return
            }

            success?(image)
        }
    }

    func removeDocumentImage(by name: Int) {
        let imageStorageReference = firebaseStorage.child("\(Constants.storageFolderPath)\(name).jpg")
        imageStorageReference.delete { [weak self] error in
            guard error == nil else {
                debugPrint("Document image deleted with error")
                return
            }

            debugPrint("Document image deleted successfully")
            self?.removeDocumentFromDatabase(by: name)
        }
    }

    // MARK: Database methods
    func saveToDatabase(document: [String: Any], creationTimestamp: Int) {
        let databaseReference = firebaseDatabase.child(Constants.databaseFolderPath)
        databaseReference.child("\(creationTimestamp)").setValue(document)
    }

    func removeDocumentFromDatabase(by name: Int) {
        let databaseDocumentReference = firebaseDatabase.child("\(Constants.databaseFolderPath)\(name)")
        databaseDocumentReference.removeValue { error, _ in
            guard error == nil else {
                debugPrint("File deleted with error")
                return
            }

            debugPrint("File deleted successfully")
        }
    }

    func getAllDocumentsFromDatabase(completion: @escaping (([Document]?, Error?) -> Void)) {
        let databaseReference = firebaseDatabase.child(Constants.databaseFolderPath)

        databaseReference.observeSingleEvent(of: .value, with: { snapshot in
            guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {
                return
            }

            let documents = allObjects.map { snapshot -> Document in
                return Document(snapshot: snapshot)
            }
            completion(documents, nil)
        }, withCancel: { error in
            completion(nil, error)
        })
    }
}
