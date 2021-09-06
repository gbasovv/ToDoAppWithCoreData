//
//  ItemsTVC.swift
//  ToDoCoreData
//
//  Created by George on 3.08.21.
//

import UIKit
import CoreData

class ItemsTVC: UITableViewController {

    var selectedCategory: Category? {
        didSet {
            self.title = selectedCategory?.name
        }
    }

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var items = [Item]()

    private let search = UISearchController(searchResultsController: nil)

    private var filteredItems = [Item]()

    private var searchBarIsEmpty: Bool {
        guard let text = search.searchBar.text else { return false }
        return text.isEmpty
    }

    private var isFiltering: Bool {
        return search.isActive && !searchBarIsEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        setSearch()
    }

    @IBAction func addItems(_ sender: Any) {
        let alert = UIAlertController(title: "Add New Item", message: "", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Your task"
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        let action = UIAlertAction(title: "Add Item", style: .default) { _ in
            if let textField = alert.textFields?.first {
                if textField.text != "", let title = textField.text {
                    let newItem = Item(context: self.context)
                    newItem.title = title
                    newItem.done = false
                    newItem.parentCategory = self.selectedCategory

                    self.items.append(newItem)
                    self.tableView.reloadData()
                    self.saveItems()
                }
            }
        }

        alert.addAction(action)
        alert.addAction(cancel)

        self.present(alert, animated: true)
    }

    //MARK: - SAVE AND FETCH ITEMS FROM DB

    private func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest()) {
        if let name = selectedCategory?.name {
            let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", name)
            request.predicate = categoryPredicate
            do {
                items = try context.fetch(request)
            } catch {
                print("Error fetching data from context: \(error)")
            }
            tableView.reloadData()
        }
    }

    private func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

extension ItemsTVC {

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredItems.count
        }
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemsCell", for: indexPath)
        let item: Item
        if isFiltering {
            item = filteredItems[indexPath.row]
        } else {
            item = items[indexPath.row]
        }
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isFiltering {
            filteredItems[indexPath.row].done.toggle()
            self.saveItems()
            tableView.reloadRows(at: [indexPath], with: .fade)
        } else {
            items[indexPath.row].done.toggle()
            self.saveItems()
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let item = items[indexPath.row].title {
                let request: NSFetchRequest<Item> = Item.fetchRequest()
                request.predicate = NSPredicate(format: "title MATCHES %@", item)
                if let items = try? context.fetch(request) {
                    for item in items {
                        context.delete(item)
                    }
                    self.items.remove(at: indexPath.row)
                    saveItems()
                    tableView.reloadData()
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = items[sourceIndexPath.row]
        items.remove(at: sourceIndexPath.row)
        items.insert(item, at: destinationIndexPath.row)
    }
}

extension ItemsTVC: UISearchResultsUpdating {

    private func setSearch() {
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search Item"
        self.navigationItem.searchController = search
    }

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearch(search.searchBar.text!)
    }

    private func filterContentForSearch(_ searchText: String) {
        filteredItems = items.filter({ (item: Item) -> Bool in
            return item.title!.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
}
