//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    var items: [CellModel]? {
        didSet {
            if self.isViewLoaded {
                self.tableView.reloadData()
            }
         }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "DEMO"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    fileprivate func cellStyleFromCellModel(_ cellModel:CellModel) -> UITableViewCellStyle {
        if (cellModel as? Value1CellModel) != nil {
            return .value1
        } else if (cellModel as? Value2CellModel) != nil {
            return .value2
        } else if (cellModel as? SubtitleCellModel) != nil {
            return .subtitle
        } else {
            return .default
        }
    }
    
    fileprivate func configureCellWithCellModel(_ cell: UITableViewCell, cellModel: CellModel) -> Void {

        cell.imageView?.image = nil
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        
        if let dw = cellModel as? DefaultCellModel {
            cell.textLabel?.text = dw.title
            
            if let iconName = dw.iconName {
                cell.imageView?.image = UIImage(named: iconName)
            }
        }
        
        if let dw = cellModel as? SubtitleCellModel {
            cell.detailTextLabel?.text = dw.subtitle
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellModel = items![indexPath.row]
        let cellId = typeName(cellModel)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) ?? UITableViewCell(style: self.cellStyleFromCellModel(cellModel), reuseIdentifier: cellId)
        self.configureCellWithCellModel(cell, cellModel: cellModel)
        return cell
    }
}
