//
//  FAMCollapseTableViewDataSource.swift
//  FAMCollapseTableView
//
//  Created by Kazuya Ueoka on 2016/03/24.
//  Copyright © 2016年 Timers inc. All rights reserved.
//

import UIKit

@objc protocol FAMCollapseTableViewProtocol {
    func openedSection() -> Int
    func tableView(tableView :UITableView, indexPathsFromSections sections :Array<Int>) -> Array<NSIndexPath>
    func tableView(tableView :UITableView, openSection section: Int, animated: Bool)
    func tableView(tableView :UITableView, closeSection section: Int, animated: Bool)
    func tableView(tableView :UITableView, toggleSection section: Int, animated: Bool)
    func tableView(tableView :UITableView, isOpenedSection section: Int) -> Bool
    func tableViewIsAnimating(tableView :UITableView) -> Bool
}

@objc protocol FAMCollapseTableViewDelegate
{
    func tableView(tableView :UITableView, willInsertIndexPaths insertIndexPaths :[NSIndexPath], willDeleteIndexPaths deleteIndexPaths :[NSIndexPath])
    func tableView(tableView :UITableView, didInsertIndexPaths insertIndexPaths :[NSIndexPath], didDeleteIndexPaths deleteIndexPaths :[NSIndexPath])
    func tableView(tableView :UITableView, sectionDidOpened section: Int)
    func tableView(tableView :UITableView, sectionDidClosed section: Int)
}

public class FAMCollapseTableViewDataSource :NSObject, UITableViewDataSource, FAMCollapseTableViewProtocol
{
    var originalDataSource :UITableViewDataSource
    weak var delegate :FAMCollapseTableViewDelegate?
    var sectionStatus: Array<Bool> = []
    var exclusiveSections :Bool = false
    private var animating :Bool = false

    init(dataSource :UITableViewDataSource, delegate :FAMCollapseTableViewDelegate?)
    {
        self.originalDataSource = dataSource
        self.delegate = delegate
        super.init()
    }

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
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
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !self.sectionStatus[section]
        {
            return 0
        }

        return self.originalDataSource.tableView(tableView, numberOfRowsInSection: section)
    }
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.originalDataSource.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return self.originalDataSource.sectionIndexTitlesForTableView?(tableView)
    }
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.originalDataSource.tableView?(tableView, titleForHeaderInSection: section)
    }
    public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.originalDataSource.tableView?(tableView, titleForHeaderInSection: section)
    }

    public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if self.originalDataSource.respondsToSelector(#selector(UITableViewDataSource.tableView(_:canEditRowAtIndexPath:)))
        {
            return self.originalDataSource.tableView!(tableView, canEditRowAtIndexPath: indexPath)
        }
        return false
    }
    public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if self.originalDataSource.respondsToSelector(#selector(UITableViewDataSource.tableView(_:canMoveRowAtIndexPath:)))
        {
            return self.originalDataSource.tableView!(tableView, canMoveRowAtIndexPath: indexPath)
        }
        return false
    }
    public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        if self.originalDataSource.respondsToSelector(#selector(UITableViewDataSource.sectionIndexTitlesForTableView(_:)))
        {
            return originalDataSource.tableView!(tableView, sectionForSectionIndexTitle: title, atIndex: index)
        }
        return 0
    }
    public func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.originalDataSource.tableView?(tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
    public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.originalDataSource.tableView?(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
    }

    //MARK: FAMCollapseTableViewProtocol
    public func openedSection() -> Int {
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

    public func tableView(tableView: UITableView, indexPathsFromSections sections: Array<Int>) -> Array<NSIndexPath> {
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
    public func tableView(tableView: UITableView, openSection section: Int, animated: Bool) {
        if self.animating
        {
            return
        }

        if self.sectionStatus[section]
        {
            return
        }

        self.animating = true

        var deleteIndexPaths :[NSIndexPath] = []
        var deleteSections :[Int] = []
        if self.exclusiveSections
        {
            let deleteSection :Int = self.openedSection()
            if NSNotFound != deleteSection
            {
                deleteIndexPaths = self.tableView(tableView, indexPathsFromSections: [deleteSection])
                deleteSections.append(deleteSection)
                self.sectionStatus[deleteSection] = false
            }
        }

        self.sectionStatus[section] = true
        let insertIndexPaths :[NSIndexPath] = self.tableView(tableView, indexPathsFromSections: [section])

        self.delegate?.tableView(tableView, willInsertIndexPaths: insertIndexPaths, willDeleteIndexPaths: deleteIndexPaths)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.delegate?.tableView(tableView, didInsertIndexPaths :insertIndexPaths, didDeleteIndexPaths :deleteIndexPaths)
            self.animating = false
        }

        if animated
        {
            tableView.beginUpdates()
            tableView.insertRowsAtIndexPaths(insertIndexPaths, withRowAnimation: .Bottom)
            if 0 < deleteIndexPaths.count
            {
                tableView.deleteRowsAtIndexPaths(deleteIndexPaths, withRowAnimation: .Top)
            }
            tableView.endUpdates()
        } else
        {
            tableView.reloadData()
            self.animating = false
        }

        CATransaction.commit()

        self.delegate?.tableView(tableView, sectionDidOpened: section)
        for section in deleteSections
        {
            self.delegate?.tableView(tableView, sectionDidClosed: section)
        }
    }
    public func tableView(tableView: UITableView, closeSection section: Int, animated: Bool) {
        if self.animating
        {
            return
        }

        if !self.sectionStatus[section]
        {
            return
        }

        self.animating = true

        self.sectionStatus[section] = false
        let deleteIndexPaths :[NSIndexPath] = self.tableView(tableView, indexPathsFromSections: [section])

        self.delegate?.tableView(tableView, willInsertIndexPaths: [], willDeleteIndexPaths: deleteIndexPaths)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.delegate?.tableView(tableView, didInsertIndexPaths :[], didDeleteIndexPaths :deleteIndexPaths)
            self.animating = false
        }

        if animated
        {
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths(deleteIndexPaths, withRowAnimation: .Top)
            tableView.endUpdates()
        } else
        {
            tableView.reloadData()
            self.animating = false
        }

        CATransaction.commit()

        self.delegate?.tableView(tableView, sectionDidClosed: section)
    }
    public func tableView(tableView: UITableView, toggleSection section: Int, animated: Bool)
    {
        if self.animating
        {
            return
        }

        let layout :(() -> Void) = {
            if self.sectionStatus[section]
            {
                self.tableView(tableView, closeSection: section, animated: animated)
            } else
            {
                self.tableView(tableView, openSection: section, animated: animated)
            }
        }

        if animated
        {
            UIView.animateWithDuration(0.3, animations: layout)
        } else
        {
            layout()
        }
    }

    public func tableView(tableView: UITableView, isOpenedSection section: Int) -> Bool {
        return self.sectionStatus[section]
    }
    
    public func tableViewIsAnimating(tableView: UITableView) -> Bool {
        return self.animating
    }
    
    //MARK: deinit
    deinit
    {
        self.delegate = nil
        
    }
}