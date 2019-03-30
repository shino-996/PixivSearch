//
//  SearchEngine.swift
//  PixivSearchAction
//
//  Created by shino on 07/12/2017.
//  Copyright © 2017 shino. All rights reserved.
//

import Foundation
import Kanna

class SearchEngine: NSObject {
    var isSearched = false
    var showHiddenResult = false
    var resultData = [(previewURL: String, percent: String, url: String)]()
    var hiddenResultData = [(previewURL: String, percent: String, url: String)]()
    var searchErrorHandler: (() -> Void)!
    var searchFinishHandler: (() -> Void)!
    
    func httpBoundary() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var boundary = "----WebKitFormBoundary"
        for _ in 0 ..< 16 {
            let randomLetter = letters.randomElement()!
            boundary.append(randomLetter)
        }
        return boundary
    }
    
    func postBody(ofURL dataURL: URL, withBoundary boundary: String) -> Data? {
        guard let imageData = try? Data(contentsOf: dataURL) else {
            return nil
        }
        var postData = Data()
        // 多行字符串, 换行和空行是有意义的
        postData.append("""
            --\(boundary)
            Content-Disposition: form-data; name="file"; filename="\(dataURL.lastPathComponent)"
            Content-Type: image/\(dataURL.pathExtension)
            
            
            """.data(using: .utf8)!)
        postData.append(imageData)
        postData.append("""
            
            --\(boundary)
            Content-Disposition: form-data; name="url"
            
            
            --\(boundary)
            Content-Disposition: form-data; name="frame"
            
            1
            --\(boundary)
            Content-Disposition: form-data; name="database"
            
            999
            --\(boundary)--
            """.data(using: .utf8)!)
        return postData
    }
    
    func searchHandle(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        guard error == nil else {
            print(error!)
            self.searchErrorHandler()
            return
        }
        guard (response as? HTTPURLResponse)?.statusCode == 200,
            let data = data,
            let html = try? HTML(html: data, encoding: .utf8) else {
            self.searchErrorHandler()
            return
        }
        let results = html.xpath("//div[@id=\"middle\"]/div[@class=\"result\"] | //div[@id=\"middle\"]/div[@class=\"result hidden\"]")
        for result in results {
            if result["id"] == "result-hidden-notification" {
                continue
            }
            guard let previewNode = result.xpath(".//div[@class=\"resultimage\"]//img").first else {
                continue
            }
            var previewURL = ""
            if previewNode["data-src"] != nil {
                previewURL = previewNode["data-src"]!
            } else if previewNode["src"] != nil {
                previewURL = previewNode["src"]!
            } else {
                continue
            }
            let percent = result.xpath(".//div[@class=\"resultsimilarityinfo\"]").first?.text ?? "0"
            var sourceURL = ""
            if let a = result.xpath(".//div[@class=\"resultcontentcolumn\"]/a").first {
                sourceURL = a["href"]!
            } else if let a = result.xpath(".//div[@class=\"resultmiscinfo\"]/a").first {
                sourceURL = a["href"]!
            } else {
                continue
            }
            if result["class"] == "result hidden" {
                self.hiddenResultData.append((previewURL, percent, sourceURL))
            } else {
                self.resultData.append((previewURL, percent, sourceURL))
            }
        }
        self.isSearched = true
        self.searchFinishHandler()
    }
    
    func search(_ imageURL: URL) {
        let requestURL = URL(string: "http://saucenao.com/search.php")!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        let boundary = httpBoundary()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = postBody(ofURL: imageURL, withBoundary: boundary)
        URLSession.shared.dataTask(with: request, completionHandler: searchHandle).resume()
    }
}
