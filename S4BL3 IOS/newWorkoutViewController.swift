//
//  newWorkoutViewController.swift
//  S4BL3 IOS
//
//  Created by vincent.besson on 01/11/2020.
//

import UIKit
import CoreBluetooth
import MSCircularSlider


class newWorkoutViewController: UIViewController,MSCircularSliderDelegate,bleStackDelegate{
    
    func onBleConnectionDidChange(pType: Int, isConnected: Bool) {
        print("connection change")
        print(pType)
        
        if (pType == 0 && isConnected == true){
           
            iconBleFitnessServiceConnection.image=UIImage(named: "iconRower512Blue.png")
            
            if (ble.isFitnessPeripheralHasBatteryService == true){
                iconBleBatteryServiceConnection.image=UIImage(named: "iconBattery512Blue.png")
            }else{
                iconBleBatteryServiceConnection.image=UIImage(named: "iconBattery512Gray.png")
            }
            
        }else if(pType == 0){
            iconBleFitnessServiceConnection.image=UIImage(named: "iconRower512Gray.png")
            iconBleBatteryServiceConnection.image=UIImage(named: "iconBattery512Gray.png")
        }
        
        if (pType == 1 && isConnected == true){
            iconBleHeartRateServiceConnection.image=UIImage(named: "iconHeartRate512Blue.png")
        }else if (pType == 1){
            iconBleHeartRateServiceConnection.image=UIImage(named: "iconHeartRate512Gray.png")
        }
        
        computeWorkoutStartButtonState()
    }
    
    func onBleDataNotification(bleData: rowerDataKpi) {
        print("")
    }
    
    @IBOutlet weak var iconBleFitnessServiceConnection:UIImageView!
    @IBOutlet weak var iconBleBatteryServiceConnection:UIImageView!
    @IBOutlet weak var iconBleHeartRateServiceConnection:UIImageView!
    
    @IBOutlet weak var workoutTargetValueLabel: UILabel!
    @IBOutlet weak var workourTargetlabel: UILabel!
    @IBOutlet weak var workourTargetUnitlabel: UILabel!
    @IBOutlet weak var workoutStartButton: UIButton!
    @IBOutlet weak var circularSlider: MSCircularSlider!
    @IBOutlet weak var workouType: UISegmentedControl!
    
    var circularRevolution=0;
    var _workoutValue:Double=0;
    var fullrevolutionValue=30;
    var nearestValue=5;
    
    var ble:bleStack!
    
    @IBAction func workoutTypeSelection(_ sender: Any) {
        
        circularSlider.currentValue=0;
        _workoutValue=0;
        
        switch workouType.selectedSegmentIndex{
            case 0:
                workourTargetlabel.text="Define a timer and row until the timer stops."
                fullrevolutionValue=30
                circularSlider.maximumRevolutions=4
                circularSlider._commaSeparatedLabels="0,5,10,15,20,25"
                nearestValue=5
                workourTargetUnitlabel.text="min"
                circularSlider.isHidden=false
 
            case 1:
                workourTargetlabel.text="Define a distance, row until you reached this distance."
                circularSlider.maximumRevolutions=5
                circularSlider._commaSeparatedLabels="0,250,500,750,1000,1250,1500,1750"
                fullrevolutionValue=2000
                nearestValue=100
                workourTargetUnitlabel.text="m"
                circularSlider.isHidden=false
                
            case 2:
                workourTargetlabel.text="Define a number of strokes, row until you reached this number"
                fullrevolutionValue=200
                circularSlider._commaSeparatedLabels="0,25,50,75,100,125,150,175"
                nearestValue=10
                workourTargetUnitlabel.text="strokes"
                circularSlider.isHidden=false
               
            case 3:
                workourTargetlabel.text="Row freely as long and as far you want"
                workourTargetUnitlabel.text=""
                circularSlider.isHidden=true
               
            default:
                break
        }
        
        computeWorkoutStartButtonState()
        workoutTargetValueLabel.text="-"
        circularSlider.maximumValue=Double(fullrevolutionValue)
    }
    
    func circularSlider(_ slider: MSCircularSlider, revolutionsChangedTo value: Int){
        circularRevolution=value
    }
    
    func circularSlider(_ slider: MSCircularSlider, valueChangedTo value: Double, fromUser: Bool) {
        _workoutValue=Double(circularRevolution*fullrevolutionValue)+value
        _workoutValue=round(_workoutValue/Double(nearestValue))*Double(nearestValue)
        workoutTargetValueLabel.text=String(Int(_workoutValue))
        
        computeWorkoutStartButtonState()
    }
    
    func computeWorkoutStartButtonState(){
       if ( (ble.fitnessPeripheral != nil && ble.fitnessPeripheral.state == .connected && _workoutValue != 0) || (ble.fitnessPeripheral != nil && ble.fitnessPeripheral.state == .connected && workouType.selectedSegmentIndex == 3)){
        workoutStartButton.isEnabled=true
        workoutStartButton.backgroundColor=UIColor.systemBlue
       }else{
        workoutStartButton.isEnabled=false
        workoutStartButton.backgroundColor=UIColor.lightGray
       }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if let vc = segue.destination as? WorkoutViewController{
            vc.workoutType = workouType.selectedSegmentIndex
            vc.workoutTargetValue = _workoutValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ble = bleStack.sharedInstance;
        ble.delegate=self
        
        if ( ble.fitnessPeripheral != nil && ble.fitnessPeripheral.state == .connected){
            iconBleFitnessServiceConnection.image=UIImage(named: "iconRower512Blue.png")
            
            if (ble.isFitnessPeripheralHasBatteryService == true){
                iconBleBatteryServiceConnection.image=UIImage(named: "iconBattery512Blue.png")
            }else{
                iconBleBatteryServiceConnection.image=UIImage(named: "iconBattery512Gray.png")
            }
            
        }else{
            iconBleFitnessServiceConnection.image=UIImage(named: "iconRower512Gray.png")
            iconBleBatteryServiceConnection.image=UIImage(named: "iconBattery512Gray.png")
        }
        
        if ( ble.heartRatePeripheral != nil && ble.heartRatePeripheral.state == .connected){
            iconBleHeartRateServiceConnection.image=UIImage(named: "iconHeartRate512Blue.png")
        }else{
            iconBleHeartRateServiceConnection.image=UIImage(named: "iconHeartRate512Gray.png")
        }
        
        circularSlider.delegate=self;
        circularSlider.markerColor=UIColor(red: 0, green: 185/255, blue: 255, alpha: 0.0)
        
        workourTargetlabel.text="Define a timer and row until the timer stops."
        fullrevolutionValue=30
        circularSlider.maximumRevolutions=4
        circularSlider._commaSeparatedLabels="0,5,10,15,20,25"
        nearestValue=5
        workourTargetUnitlabel.text="min"
        
        workoutTargetValueLabel.text="0"
        circularSlider.maximumValue=Double(fullrevolutionValue)
        workoutStartButton.isEnabled=false
        
        workoutStartButton.layer.cornerRadius = 10
        workoutStartButton.clipsToBounds = true
        
        computeWorkoutStartButtonState()
        
    }
    
}
