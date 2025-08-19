//
//  ViewController.swift
//  mobileTest
//
//  Created by apple on 2025/8/19.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    
    private var segments: [Segment] = []
    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        tableView = UITableView(frame: view.bounds)
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //调用data provider接口，在console中打出对应data
        BookingDataManager.shared.fetchBooking(forceRefresh: false) { result in
            switch result {
            case .success(let booking):
                print("booking.json : \(booking)")
                self.segments = booking.segments
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Failed to fetch booking: \(error)")
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "id = \(segments[indexPath.row].id)"
        
        return cell
    }
}

