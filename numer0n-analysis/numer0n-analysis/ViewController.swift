//
//  ViewController.swift
//  numer0n-analysis
//
//  Created by 村石拓海 on 2021/12/08.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.size.height
  //  let cellBackgroundColor = UIColor.named("cellBackgroundColor")
    
    var historyTableView: UITableView = UITableView()
    let numberTextField = UITextField()
    
    var historyArray: [Int] = [123]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.systemGray4
        
        let inputView = UIView()
        inputView.frame = CGRect(x:screenWidth * 1/10, y:screenHeight * 9/20, width:screenWidth * 4/5, height:screenHeight * 1/10)
        inputView.backgroundColor = UIColor.white
        
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
        //historyTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        inputView.layer.cornerRadius = 15
        inputView.layer.shadowColor = UIColor.gray.cgColor
        inputView.layer.shadowOpacity = 1
        inputView.layer.shadowRadius = 5
        inputView.layer.shadowOffset = CGSize(width: 4, height: 4)

		setUpNumberTextField(textField: numberTextField)

        self.view.addSubview(historyTableView)
        self.view.addSubview(inputView)
        self.view.addSubview(numberTextField)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension UIColor {
    class var cellBackgroundColor: UIColor {
        return UIColor(named: "CellBackgroundColor") ?? UIColor.white
    }
}

extension ViewController {
	private func setUpNumberTextField(textField: UITextField) {
		textField.frame = CGRect(x:screenWidth * 15/100, y:screenHeight * 9/20, width:screenWidth * 3/5, height:screenHeight * 1/10)
		textField.placeholder = "数字3桁"
		textField.keyboardType = .numberPad
		textField.font = UIFont.systemFont(ofSize: 40)
		textField.layer.cornerRadius = 15
		textField.returnKeyType = .done
		textField.clearButtonMode = .never
		textField.delegate = self
	}
}
