//
//  SearchEngine.swift
//  PixivSearchAction
//
//  Created by shino on 07/12/2017.
//  Copyright © 2017 shino. All rights reserved.
//

import Foundation
import Fuzi

class SearchEngine: NSObject {
    var haveSearched = false
    var showHiddenResult = false
    var resultData = [(previewURL: String, percent: String, url: String)]()
    var hiddenResultData = [(previewURL: String, percent: String, url: String)]()
    var searchErrorHandle: (() -> Void)!
    var searchFinishHandle: (() -> Void)!
    
    func httpBoundary() -> String {
        let letters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        let length = 16
        var boundary = "----WebKitFormBoundary"
        for _ in 0 ..< length {
            let randIndex = arc4random_uniform(UInt32(letters.count))
            let randLetter = letters[Int(randIndex)]
            boundary.append(randLetter)
        }
        return boundary
    }
    
    func postBody(ofURL dataURL: URL, withBoundary boundary: String) -> Data {
        let startBoundaryData = ("--" + boundary + "\r\n").data(using: .utf8)!
        let endBoundaryData = ("--" + boundary + "--" + "\r\n").data(using: .utf8)!
        let formDataString = "Content-Disposition: form-data; name="
        var postData = Data()
        postData.append(startBoundaryData)
        postData.append("""
            \(formDataString)"file"; filename="\(dataURL.lastPathComponent)"
            
            """.data(using: .utf8)!)
        postData.append("""
            Content-Type: image/\(dataURL.pathExtension)
            
            
            """.data(using: .utf8)!)
        postData.append(try! Data(contentsOf: dataURL))
        postData.append("""
            
            """.data(using: .utf8)!)
        postData.append(startBoundaryData)
        postData.append("""
            \(formDataString)"url"
            
            
            """.data(using: .utf8)!)
        postData.append(startBoundaryData)
        postData.append("""
            \(formDataString)"frame"
            
            1
            """.data(using: .utf8)!)
        postData.append(startBoundaryData)
        postData.append("""
            \(formDataString)"database"
            
            999
            """.data(using: .utf8)!)
        postData.append(endBoundaryData)
        return postData
    }
    
    func searchHandle(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        guard error == nil else {
            print(error!)
            self.searchErrorHandle()
            return
        }
        guard let data = data else {
            self.searchErrorHandle()
            return
        }
        let html = try! HTMLDocument(data: data)
        let results = html.xpath("//div[@id=\"middle\"]/div[@class=\"result\"] | //div[@id=\"middle\"]/div[@class=\"result hidden\"]")
        for result in results {
            if result.attr("id") == "result-hidden-notification" {
                continue
            }
            guard let previewNode = result.xpath(".//div[@class=\"resultimage\"]//img").first else {
                continue
            }
            var previewURL = ""
            if previewNode.attr("data-src") != nil {
                previewURL = previewNode.attr("data-src")!
            } else if previewNode.attr("src") != nil {
                previewURL = previewNode.attr("src")!
            } else {
                continue
            }
            let percent = result.xpath(".//div[@class=\"resultsimilarityinfo\"]").first!.stringValue
            var sourceURL = ""
            if let a = result.xpath(".//div[@class=\"resultcontentcolumn\"]/a").first {
                sourceURL = a.attr("href")!
            } else if let a = result.xpath(".//div[@class=\"resultmiscinfo\"]/a").first {
                sourceURL = a.attr("href")!
            } else {
                continue
            }
            if result.attr("class") == "result hidden" {
                self.hiddenResultData.append((previewURL, percent, sourceURL))
            } else {
                self.resultData.append((previewURL, percent, sourceURL))
            }
        }
        self.haveSearched = true
        self.searchFinishHandle()
    }
    
    func search(_ imageURL: URL) {
        let requestURL = URL(string: "http://saucenao.com/search.php")!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        let boundary = httpBoundary()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = postBody(ofURL: imageURL, withBoundary: boundary)
        self.haveSearched = false
        self.showHiddenResult = false
        URLSession.shared.dataTask(with: request, completionHandler: searchHandle).resume()
    }
}
