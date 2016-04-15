//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    var items: [CellModel]? {
        didSet {
            if self.isViewLoaded() {
                self.tableView.reloadData()
            }
         }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "DEMO"
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    private func cellStyleFromCellModel(cellModel:CellModel) -> UITableViewCellStyle {
        if (cellModel as? Value1CellModel) != nil {
            return .Value1
        } else if (cellModel as? Value2CellModel) != nil {
            return .Value2
        } else if (cellModel as? SubtitleCellModel) != nil {
            return .Subtitle
        } else {
            return .Default
        }
    }
    
    private func configureCellWithCellModel(cell: UITableViewCell, cellModel: CellModel) -> Void {

        if let dw = cellModel as? DefaultCellModel {
            cell.textLabel?.text = dw.title
            
            if let iconName = dw.iconName {
                cell.imageView?.image = UIImage.init(named: iconName)
            }
        }
        
        if let dw = cellModel as? SubtitleCellModel {
            cell.detailTextLabel?.text = dw.subtitle
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellModel = items![indexPath.row]
        let cellId = typeName(cellModel)
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId) ?? UITableViewCell.init(style: self.cellStyleFromCellModel(cellModel), reuseIdentifier: cellId)
        self.configureCellWithCellModel(cell, cellModel: cellModel)
        return cell
    }
}
