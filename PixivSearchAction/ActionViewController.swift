//
//  ActionViewController.swift
//  PixivSearchAction
//
//  Created by shino on 2017/11/30.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    var imageURL: URL!
    var searchEngine: SearchEngine!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchEngine = SearchEngine()
        searchEngine.searchErrorHandle = {
            let alertController = UIAlertController(title: "加载失败", message: "", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "返回", style: .cancel) { action in
                self.done()
            }
            let continueAction = UIAlertAction(title: "重新加载", style: .default) { action in
                self.searchEngine.search(self.imageURL)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(continueAction)
            DispatchQueue.main.async {
                self.activity.stopAnimating()
                self.present(alertController, animated: true, completion: nil)
            }
        }
        searchEngine.searchFinishHandle = {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.activity.stopAnimating()
            }
        }
        let item = extensionContext!.inputItems.first as! NSExtensionItem
        let provider = item.attachments!.first as! NSItemProvider
        if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
            provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { imageURL, error in
                guard error == nil else {
                    print(error)
                    return
                }
                self.imageURL = imageURL as! URL
                self.activity.startAnimating()
                self.searchEngine.search(self.imageURL)
            }
        }
    }

    @IBAction func done() {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }
}

extension ActionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searchEngine.haveSearched {
            if searchEngine.showHiddenResult {
                return searchEngine.resultData.count
            } else {
                return searchEngine.resultData.count + 1
            }
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.row
        if index < searchEngine.resultData.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell",
                                                          for: indexPath) as! ImageViewCell
            cell.load(with: searchEngine.resultData[index])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MoreImageCell",
                                                          for: indexPath)
            return cell
        }
    }
}

extension ActionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        if index < searchEngine.resultData.count {
            let urlString = searchEngine.resultData[index].url
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let url = URL(string: urlString)!
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { _ in }
            } else {
                UIApplication.shared.openURL(url)
            }
        } else {
            let addIndex = searchEngine.hiddenResultData.count
            var indexArray = [IndexPath]()
            for i in 0 ..< addIndex {
                indexArray.append(IndexPath(item: indexPath.item + i, section: indexPath.section))
            }
            searchEngine.showHiddenResult = true
            collectionView.deleteItems(at: [indexPath])
            searchEngine.resultData.append(contentsOf: searchEngine.hiddenResultData)
            collectionView.insertItems(at: indexArray)
        }
    }
}
