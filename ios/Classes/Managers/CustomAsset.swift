//
//  Copyright © 2024 Amr Saied All rights reserved.
//
//  A class that holds information about an Asset
//  Adds Asset's AVURLAsset as a recipient to the Playback Content Key Session in a protected playback/download use case.
//
//  DownloadState extension is used to track the download states of Assets,
//  Keys extension is used to define a number of values to use as keys in dictionary lookups.
//

import AVFoundation

@objc public class CustomAsset : NSObject {
    
    @objc public  var name: String
    @objc public  var url: URL!
    @objc public  var contentKeyIdList: [String]?
    @objc public   var urlAsset: AVURLAsset!
    
    func extractUUID(from uri: URL) -> String? {
        let regexPattern = "[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+"
        let regex = try? NSRegularExpression(pattern: regexPattern)
        guard let matches = regex?.matches(in: uri.absoluteString, range: NSRange(uri.absoluteString.startIndex..., in: uri.absoluteString)) else {
            return nil
        }
        
        if let match = matches.first {
            return String(uri.absoluteString[Range(match.range, in: uri.absoluteString)!])
        } else {
            return nil
        }
    }

    
    @objc public  init(name: String, url: URL) {
        var updatedName = name // Create a variable to hold the potentially updated name

        // Check if the name represents a URL
        // Check if the name represents a valid URL
         if let url = URL(string: name) {
             // Get the path components of the URL
             let pathComponents = url.pathComponents
             
             // Iterate through the path components to find the UUID
             for component in pathComponents {
                 // Check if the component matches the UUID pattern
                 if component.contains("-") {
                     // Update the name to be the matched UUID
                     updatedName = component
                     break // Exit the loop once UUID is found
                 }
             }
         }
                
        self.name = updatedName
        self.url = url
        self.contentKeyIdList = [String]()
        super.init()

        print("Creating Asset with url: \(url)) name: \(updatedName)")
        
        self.createUrlAsset()
       
    }
    
    // Link AVURLAsset to Content Key Session
    @objc public   func addAsContentKeyRecipient() {
        print("Adding AVURLAsset as a recepient to the Content Key Session")
        BrightCoveContentKeyManager.sharedManager.contentKeySession.addContentKeyRecipient(urlAsset)
    }
    
    // Using different AVURLAsset to allow simultaneous playback and download
    @objc public func createUrlAsset() {
        urlAsset = AVURLAsset(url: url)
    }
}

/*
 Extends `Asset` to add a simple download state enumeration used by the sample
 to track the download states of Assets.
 */
@objc public extension CustomAsset {
    @objc public enum DownloadState: Int {
        case notDownloaded
        case downloading
        case downloadedAndSavedToDevice
    }
}

/*
 Extends `Asset` to define a number of values to use as keys in dictionary lookups.
 */
extension CustomAsset {
    struct Keys {
        /*
         Key for the Asset name, used for `AssetDownloadProgressNotification` and
         `AssetDownloadStateChangedNotification` Notifications as well as
         AssetListManager.
         */
        static let name = "AssetNameKey"
        
        /*
         Key for the Asset download percentage, used for
         `AssetDownloadProgressNotification` Notification.
         */
        static let percentDownloaded = "AssetPercentDownloadedKey"
        
        /*
         Key for the Asset download state, used for
         `AssetDownloadStateChangedNotification` Notification.
         */
        static let downloadState = "AssetDownloadStateKey"
        
        /*
         Key for the Asset download AVMediaSelection display Name, used for
         `AssetDownloadStateChangedNotification` Notification.
         */
        static let downloadSelectionDisplayName = "AssetDownloadSelectionDisplayNameKey"
    }
}
