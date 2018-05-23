//
//  ViewController.swift
//  MasteringTableView
//
//  Created by illusion on 2018. 2. 18..
//  Copyright © 2018년 illusion. All rights reserved.
//

import UIKit

/**
 https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/TableView_iPhone/ManageInsertDeleteRow/ManageInsertDeleteRow.html#//apple_ref/doc/uid/TP40007451-CH10-SW9
 */
class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private var items = [String]()
    private var key: UInt64 = 0
    private let itemCountForNewGen = 8
    private var isModifyMode = false
    
    private let insertQueue = DispatchQueue.init(label: "insertQueue")
    private let deleteQueue = DispatchQueue.init(label: "deleteQueue")
    private let updateQueue = DispatchQueue.init(label: "updateQueue")
    private let keyGenQueue = DispatchQueue.init(label: "keyGenQueue")
    
    private var tableViewLoadOperationOn = false
    
    private func nextKey() -> UInt64 {
        self.key = self.key + 1
        return self.key
    }
    
    private func generateItems(count : Int) -> [String] {
        var items = [String]()
        keyGenQueue.sync {
            for _ in 0..<count {
                items.append("\(nextKey())")
            }
        }
        return items
    }
    
    private func insertItems(items: [String], useReload: Bool = false) {
        DispatchQueue.main.async {
            if useReload {
                self.items.append(contentsOf: items)
                self.tableView.reloadData()
                self.scrollToBottom()
            } else {
                UIView.setAnimationsEnabled(false)
                self.tableView.beginUpdates()
                let startRow = self.items.count
                var indexPathes = [IndexPath]()
                for i in 0..<items.count {
                    indexPathes.append(IndexPath(row: i + startRow, section: 0))
                }
                self.items.append(contentsOf: items)
                
                self.tableView.insertRows(at: indexPathes, with: UITableViewRowAnimation.automatic)
                self.tableView.endUpdates()
                UIView.setAnimationsEnabled(true)
                self.scrollToBottom()
            }
            
        }
    }
    func scrollToBottom() {
        let row = self.items.count - 1
        if row > 0 {
            self.tableView.scrollToRow(at: IndexPath.init(row: row, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.observe(\UITableView.hasUncommittedUpdates, options: .new) { (tableView, changed) in
            if let value = changed as? Bool {
                if value {
                    print("hasUncommittedUpdates : on")
                } else {
                    print("hasUncommittedUpdates : off")
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func touchUpInsertButton(_ sender: UIButton) {

        // 일반적인 케이스 (normal case)
//        insertQueue.async { [weak self] in guard let sSelf = self else { return }
//            let newItems = sSelf.generateItems(count: sSelf.itemCountForNewGen)
//            sSelf.insertItems(items: newItems)
//        }
        
        // crash??
        insertQueue.async { [weak self] in guard let sSelf = self else { return }
            for i in 0..<sSelf.itemCountForNewGen {
                let newItems = sSelf.generateItems(count: i + 1)
                sSelf.insertItems(items: newItems, useReload: true)
            }
        }
    }
    
    @IBAction func touchUpDeleteButton(_ sender: UIButton) {
        deleteQueue.async {
            DispatchQueue.main.async { [weak self] in guard let sSelf = self else { return }
                sSelf.items.removeAll()
                sSelf.tableView.reloadData()
            }
        }
    }
    
    @IBAction func touchUpUpdateButton(_ sender: UIButton) {
        updateQueue.async {
            DispatchQueue.main.async { [weak self] in guard let sSelf = self else { return }
                sSelf.tableView.reloadData()
            }
        }
    }
    
    @IBAction func touchUpModifyButton(_ sender: Any) {
        isModifyMode = !isModifyMode
        if isModifyMode {
            self.tableView.setEditing(true, animated: true)
        } else {
            self.tableView.setEditing(false, animated: true)
        }
        
    }
}



extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        let count = 1
        if count == 0 {
            tableViewLoadOperationOn = false
        }
        print("numberOfSections")
        
        tableViewLoadOperationOn = true
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRowsInSection: \(section)")
        let count = items.count
        
        if count == 0 {
            tableViewLoadOperationOn = false
        }
        
        return count
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        print("heightForRowAtIndexPath : \(indexPath.row)")
        if self.items.count - 1 == indexPath.row {
            tableViewLoadOperationOn = false
        }
        return 64
    }
    
    /**
     이 2개는 delegate의 호출 수가 다르다.
     tableViewLoadOperationOn off 여부를 판단하기 위해서는 forIndexPath를 사용하면 안된다.(tableView:heightForRowAt:indexPath 3번씩 호출됨)
     tableView.dequeueReusableCell forIndexPath
     tableView.dequeueReusableCell
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAtIndexPath : \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath)
//        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell")!
        
        if let messageCell = cell as? MessageTableViewCell {
            // 크래시가 발생하는 부분이 있을까?
            // 일관성이 언제 깨지는가?
            messageCell.messageLabel.text = items[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            self.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            tableView.endUpdates()
        } else {
            let newItem = self.generateItems(count: 1).first!
            tableView.beginUpdates()
            self.items.append(newItem)
            tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            tableView.endUpdates()
            self.scrollToBottom()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.row == self.items.count - 1 {
            return .insert
        }
        
        return .delete
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var moreRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "More", handler:{action, indexpath in
            
        });
        moreRowAction.backgroundColor = UIColor(red: 0.298, green: 0.851, blue: 0.3922, alpha: 1.0);
        
        var deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler:{action, indexpath in
            tableView.beginUpdates()
            self.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            tableView.endUpdates()
        });
        
        return [deleteRowAction, moreRowAction];
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.showsReorderControl = true
//    }
}
