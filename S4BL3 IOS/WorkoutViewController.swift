//
//  WorkoutViewController.swift
//  S4BL3 IOS
//
//  Created by vincent.besson on 19/10/2020.
//
import UIKit
import CoreBluetooth
import Charts

class WorkoutViewController: UIViewController,bleStackDelegate {
    
    
    
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var bodySensorLocationLabel: UILabel!
    @IBOutlet weak var barChart: BarChartView!

    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
   
    var ble:bleStack!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view has loaded");
        barChartUpdate()
        ble = bleStack.sharedInstance;
        ble.delegate = self
    }
    
    func onUpdateBleData(bleData:rowerDataKpi) {
        
        heartRateLabel.text=String(bleData.strokeCount);
    }
    
    func barChartUpdate () {
            
            // Basic set up of plan chart
            
            let entry1 = BarChartDataEntry(x: 1.0, y: Double(10))
            let entry2 = BarChartDataEntry(x: 2.0, y: Double(20))
            let entry3 = BarChartDataEntry(x: 3.0, y: Double(30))
            let dataSet = BarChartDataSet(entries: [entry1, entry2, entry3], label: "Widgets Type")
            let data = BarChartData(dataSets: [dataSet])
            barChart.data = data
            barChart.chartDescription?.text = "Number of Widgets by Type"

            // Color
            dataSet.colors = ChartColorTemplates.vordiplom()

            // Refresh chart with new data
            barChart.notifyDataSetChanged()
        }
    
    
    func onHeartRateReceived(_ heartRate: Int) {
        heartRateLabel.text = String(heartRate)
        print("BPM: \(heartRate)")
    }
}

