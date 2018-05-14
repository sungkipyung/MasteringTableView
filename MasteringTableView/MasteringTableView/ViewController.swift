//
//  ViewController.swift
//  MasteringTableView
//
//  Created by illusion on 2018. 2. 18..
//  Copyright © 2018년 illusion. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private var items = [String]()
    private var key: UInt64 = 0
    private let itemCountForNewGen = 8
    
    private let insertQueue = DispatchQueue.init(label: "insertQueue")
    private let deleteQueue = DispatchQueue.init(label: "deleteQueue")
    private let updateQueue = DispatchQueue.init(label: "updateQueue")
    private let keyGenQueue = DispatchQueue.init(label: "keyGenQueue")
    
    private func nextKey() -> UInt64 {
        self.key = self.key + 1
        return self.key
    }
    
    private func generateItems() -> [String] {
        var items = [String]()
        keyGenQueue.sync {
            for _ in 0..<itemCountForNewGen {
                items.append("\(nextKey())")
            }
        }
        return items
    }
    
    private func insertItems(items: [String]) {
        // 정렬도 해야지? 그지? 응?
        DispatchQueue.main.async {
            self.items.append(contentsOf: items)
            self.tableView.reloadData()
            let row = self.items.count - 1
            self.tableView.scrollToRow(at: IndexPath.init(row: row, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func touchUpInsertButton(_ sender: UIButton) {
        
        insertQueue.async { [weak self] in guard let sSelf = self else { return }
            let newItems = sSelf.generateItems()
            
            sSelf.insertItems(items: newItems)
        }
    }
    
    @IBAction func touchUpDeleteButton(_ sender: UIButton) {
        deleteQueue.async { [weak self] in guard let sSelf = self else { return }
            
        }
    }
    
    @IBAction func touchUpUpdateButton(_ sender: UIButton) {
        updateQueue.async { [weak self] in guard let sSelf = self else { return }
            
        }
    }
}



extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        print("numberOfSections")
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRowsInSection: \(section)")
        return items.count
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        print("heightForRowAtIndexPath : \(indexPath.row)")
        return 64
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAtIndexPath : \(indexPath.row)")
//        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell")!
        
        if let messageCell = cell as? MessageTableViewCell {
            // 크래시가 발생하는 부분이 있을까?
            // 일관성이 언제 깨지는가?
            messageCell.messageLabel.text = items[indexPath.row]
        }
        
        return cell
    }
}
