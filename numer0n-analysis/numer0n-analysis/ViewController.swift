//
//  ViewController.swift
//  numer0n-analysis
//
//  Created by 村石拓海 on 2021/12/08.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.size.height
    
    var historyTableView: UITableView = UITableView()
    
    var historyArray: [Int] = [0123, 4567, 8901]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.frame = CGRect(x:screenWidth * 0/100, y:screenHeight * 10/100, width:screenWidth * 100/100, height:screenHeight * 80/100)
        historyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "historyCell")
        self.view.addSubview(historyTableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "historyCell")
        cell.textLabel?.text = String(historyArray[indexPath.row])
        return cell
    }
}

