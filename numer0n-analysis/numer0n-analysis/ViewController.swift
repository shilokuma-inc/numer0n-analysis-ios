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
  //  let cellBackgroundColor = UIColor.named("cellBackgroundColor")
    
    var historyTableView: UITableView = UITableView()
    
    var historyArray: [Int] = [123]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.systemGray4
        
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.frame = CGRect(x:screenWidth * 1/10, y:screenHeight * 1/10, width:screenWidth * 4/5, height:screenHeight * 3/10)
        historyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "historyCell")
        historyTableView.rowHeight = 60
        historyTableView.layer.cornerRadius = 15
        historyTableView.layer.shadowColor = UIColor.gray.cgColor
        historyTableView.layer.shadowOpacity = 1
        historyTableView.layer.shadowRadius = 5
        historyTableView.layer.shadowOffset = CGSize(width: 4, height: 4)
        historyTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        self.view.addSubview(historyTableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "historyCell")
        cell.textLabel?.font = UIFont.systemFont(ofSize: 40)
        cell.textLabel?.text = String(historyArray[indexPath.row])
        cell.contentView.backgroundColor = UIColor.cellBackgroundColor
        
        return cell
    }
}

extension UIColor {
    class var cellBackgroundColor: UIColor {
        return UIColor(named: "CellBackgroundColor") ?? UIColor.white
    }
}
