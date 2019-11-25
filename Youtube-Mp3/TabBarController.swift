//
//  TabBarController.swift
//  Youtube-Mp3
//
//  Created by burak kaya on 22/11/2019.
//  Copyright © 2019 burak kaya. All rights reserved.
//

import UIKit
import RxSwift

class TabBarController: UITabBarController {
    @IBOutlet weak var mainTabBar: UITabBar!
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myTabBarItem3 = (self.tabBar.items?[2])! as UITabBarItem

        downloadingVideos.subscribe(onNext: { videos in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
            if videos?.count ?? 0 > 0{
                myTabBarItem3.title = "\(videos?.count ?? 0)"

            }else{
                
                myTabBarItem3.title = ""
            }
        }).disposed(by: bag)
        
        let myTabBarItem1 = (self.tabBar.items?[0])! as UITabBarItem
        myTabBarItem1.image = UIImage(named: "searchBtn")
        myTabBarItem1.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        myTabBarItem1.title = ""

        let myTabBarItem2 = (self.tabBar.items?[1])! as UITabBarItem
        myTabBarItem2.image = UIImage(named: "savedBtn")
        myTabBarItem2.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        myTabBarItem2.title = ""
        
        myTabBarItem3.image = UIImage(named: "stillDownload")
        myTabBarItem3.imageInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)

    }
}
