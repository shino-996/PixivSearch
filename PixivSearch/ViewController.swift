//
//  ViewController.swift
//  PixivSearch
//
//  Created by shino on 2017/11/30.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let url = URL(string: "https://shino.space")!
        URLSession.shared.dataTask(with: url).resume()
    }
}

