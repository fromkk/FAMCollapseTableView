//
//  FAMCollapseTableViewDataSource.swift
//  FAMCollapseTableView
//
//  Created by Kazuya Ueoka on 2016/03/24.
//  Copyright © 2016年 Timers inc. All rights reserved.
//

import UIKit

protocol FAMCollapseTableViewProtocol {
    func openedSection() -> Int
    func tableView(tableView :UITableView, indexPathsFromSections sections :Array<Int>) -> Array<NSIndexPath>
    func tableView(tableView :UITableView, openSection section: Int, animated: Bool)
    func tableView(tableView :UITableView, closeSection section: Int, animated: Bool)
    func tableView(tableView :UITableView, toggleSection section: Int, animated: Bool) -> Bool
}

class FAMCollapseTableViewDataSource :NSObject, UITableViewDataSource, FAMCollapseTableViewProtocol
{
    var originalDataSource :UITableViewDataSource
    var sectionStatus: Array<Bool> = []
    var exclusiveSections :Bool = false

    init(dataSource :UITableViewDataSource)
    {
        originalDataSource = dataSource

        super.init()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var result :Int = 1
        if self.originalDataSource.respondsToSelector(#selector(UITableViewDataSource.numberOfSectionsInTableView(_:)))
        {
            result = self.originalDataSource.numberOfSectionsInTableView!(tableView)
        }

        while result < self.sectionStatus.count
        {
            self.sectionStatus.removeLast()
        }
        while (result > self.sectionStatus.count)
        {
            self.sectionStatus.append(false)
        }
        return result
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !self.sectionStatus[section]
        {
            return 0
        }

        return self.originalDataSource.tableView(tableView, numberOfRowsInSection: section)
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.originalDataSource.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return self.originalDataSource.sectionIndexTitlesForTableView?(tableView)
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.originalDataSource.tableView?(tableView, titleForHeaderInSection: section)
    }
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.originalDataSource.tableView?(tableView, titleForHeaderInSection: section)
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if self.originalDataSource.respondsToSelector(#selector(UITableViewDataSource.tableView(_:canEditRowAtIndexPath:)))
        {
            return self.originalDataSource.tableView!(tableView, canEditRowAtIndexPath: indexPath)
        }
        return false
    }
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if self.originalDataSource.respondsToSelector(#selector(UITableViewDataSource.tableView(_:canMoveRowAtIndexPath:)))
        {
            return self.originalDataSource.tableView!(tableView, canMoveRowAtIndexPath: indexPath)
        }
        return false
    }
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        if self.originalDataSource.respondsToSelector(#selector(UITableViewDataSource.sectionIndexTitlesForTableView(_:)))
        {
            return originalDataSource.tableView!(tableView, sectionForSectionIndexTitle: title, atIndex: index)
        }
        return 0
    }
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.originalDataSource.tableView?(tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.originalDataSource.tableView?(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
    }

    //MARK: FAMCollapseTableViewProtocol
    func openedSection() -> Int {
        if !self.exclusiveSections
        {
            return NSNotFound
        }

        for section in 0..<self.sectionStatus.count
        {
            if self.sectionStatus[section]
            {
                return section
            }
        }

        return NSNotFound
    }

    func tableView(tableView: UITableView, indexPathsFromSections sections: Array<Int>) -> Array<NSIndexPath> {
        var result :Array<NSIndexPath> = []
        for section in sections
        {
            for row in 0..<self.originalDataSource.tableView(tableView, numberOfRowsInSection: section)
            {
                result.append(NSIndexPath(forRow: row, inSection: section))
            }
        }
        return result
    }

    //MARK: FAMCollapseTableViewDelegate
    func tableView(tableView: UITableView, openSection section: Int, animated: Bool) {
        if self.sectionStatus[section]
        {
            return
        }

        var deleteSections :Array<NSIndexPath> = []
        if self.exclusiveSections
        {
            let deleteSection :Int = self.openedSection()
            if NSNotFound != deleteSection
            {
                deleteSections = self.tableView(tableView, indexPathsFromSections: [deleteSection])
                self.sectionStatus[deleteSection] = false
            }
        }

        self.sectionStatus[section] = true

        if animated
        {
            tableView.beginUpdates()
            tableView.insertRowsAtIndexPaths(self.tableView(tableView, indexPathsFromSections: [section]), withRowAnimation: .Bottom)
            if 0 < deleteSections.count
            {
                tableView.deleteRowsAtIndexPaths(deleteSections, withRowAnimation: .Top)
            }
            tableView.endUpdates()
        } else
        {
            tableView.reloadData()
        }
    }
    func tableView(tableView: UITableView, closeSection section: Int, animated: Bool) {
        if !self.sectionStatus[section]
        {
            return
        }

        self.sectionStatus[section] = false

        if animated
        {
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths(self.tableView(tableView, indexPathsFromSections: [section]), withRowAnimation: .Top)
            tableView.endUpdates()
        } else
        {
            tableView.reloadData()
        }
    }
    func tableView(tableView: UITableView, toggleSection section: Int, animated: Bool) -> Bool {
        if self.sectionStatus[section]
        {
            self.tableView(tableView, closeSection: section, animated: animated)
        } else
        {
            self.tableView(tableView, openSection: section, animated: animated)
        }

        return self.sectionStatus[section]
    }
}
