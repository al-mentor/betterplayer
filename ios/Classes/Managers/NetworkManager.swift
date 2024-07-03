//
//  NetworkManager.swift
//  better_player
//
//  Created by Amr Saied on 26/05/2024.
//

import Foundation


class NetworkManager {
   static let shared = NetworkManager()
   
   private let responseCacheKey = "responseCacheKey"
   
   var responseCache: [String: CachedResponse] {
       get {
           if let cachedData = UserDefaults.standard.object(forKey: responseCacheKey) as? Data {
               do {
                   return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(cachedData) as? [String: CachedResponse] ?? [:]
               } catch {
                   print("Failed to load cache: \(error)")
                   return [:]
               }
           }
           return [:]
       }
       set {
           do {
               let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
               UserDefaults.standard.set(data, forKey: responseCacheKey)
           } catch {
               print("Failed to save cache: \(error)")
           }
       }
   }
   
   func synchronousDataTask(urlRequest: URLRequest) -> (Data?, URLResponse?, Error?) {
       let urlString = urlRequest.url!.absoluteString
       
       // Check if the response is already in the cache
       if let cachedResponse = responseCache[urlString] {
           let error = cachedResponse.errorDescription != nil ? NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: cachedResponse.errorDescription!]) : nil
           return (cachedResponse.data, cachedResponse.urlResponse, error)
       }
       
       var data: Data?
       var response: URLResponse?
       var error: Error?
       
       let semaphore = DispatchSemaphore(value: 0)
       
       let dataTask = URLSession.shared.dataTask(with: urlRequest) { (responseData, urlResponse, responseError) in
           data = responseData
           response = urlResponse
           error = responseError
           
           // Cache the response
           let errorDescription = responseError?.localizedDescription
           let cachedResponse = CachedResponse(data: responseData, urlResponse: urlResponse, errorDescription: errorDescription)
           self.responseCache[urlString] = cachedResponse
           
           semaphore.signal()
       }
       
       dataTask.resume()
       semaphore.wait()
       
       return (data, response, error)
   }
}




