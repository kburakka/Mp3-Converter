//
//  DownloadingVideosViewController.swift
//  Youtube-Mp3
//
//  Created by burak kaya on 25/11/2019.
//  Copyright © 2019 burak kaya. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

var downloadingVideos = BehaviorRelay<[VideoCell]?>(value: [])

class DownloadingVideosViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    let bag = DisposeBag()
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadingVideos.value?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("VideoViewCell", owner: self, options: nil)?.first as! VideoViewCell
        cell.configure(with: downloadingVideos.value?[indexPath.row])
        return cell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    @objc func loadList(notification: NSNotification){
        self.tableView.reloadData()
    }
}
