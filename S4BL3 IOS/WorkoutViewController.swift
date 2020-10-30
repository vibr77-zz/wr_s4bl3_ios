//
//  WorkoutViewController.swift
//  S4BL3 IOS
//
//  Created by vincent.besson on 19/10/2020.
//
import UIKit
import CoreBluetooth


//let heartRateServiceCBUUID = CBUUID(string: "0x180D")
let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")


class WorkoutViewController: UIViewController {
    
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var bodySensorLocationLabel: UILabel!

    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("it has loaded");
        // Do any additional setup after loading the view.
        //centralManager = CBCentralManager(delegate: self, queue: nil)

        // Make the digits monospaces to avoid shifting when the numbers change
        heartRateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: heartRateLabel.font!.pointSize, weight: .regular)
        
        let ble = bleStack.sharedInstance;
        
        
    }
    func onHeartRateReceived(_ heartRate: Int) {
        heartRateLabel.text = String(heartRate)
        print("BPM: \(heartRate)")
    }
}

