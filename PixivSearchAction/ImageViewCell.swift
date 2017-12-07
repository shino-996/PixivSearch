//
//  ImageViewCell.swift
//  PixivSearchAction
//
//  Created by shino on 2017/12/5.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit

class ImageViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imagePercentLabel: UILabel!
    var imageURL: String!
    
    func load(with imageData: (previewURL: String, percent: String, url: String)) {
        DispatchQueue.global().async {
            do {
                let urlString = imageData.previewURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                let imageURL = URL(string: urlString)!
                let image = try Data(contentsOf: imageURL)
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: image)
                }
            } catch(let error) {
                print("image load error: \(error)")
            }
        }
        imagePercentLabel.text = imageData.percent
        imageURL = imageData.url
    }
}
