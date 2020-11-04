//
//  WorkoutViewController.swift
//  S4BL3 IOS
//
//  Created by vincent.besson on 19/10/2020.
//
import UIKit
import CoreBluetooth
import Charts


class viewTapGesture: UITapGestureRecognizer {
    var viewID = 0
    
}

class WorkoutViewController: UIViewController,bleStackDelegate ,UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fieldPickerValueData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return fieldPickerTitleData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tmpSelectedField = fieldPickerValueData[row] // selected item
        
        let defaults = UserDefaults.standard
        switch activeKpiViewID{
            case 1:
                defaults.set(tmpSelectedField, forKey: "workoutKpiView1")
                kpi1Value.text=String(ble.rdKpi.valueByPropertyName(name:tmpSelectedField))
                kpiFieldName[1]=tmpSelectedField
            case 2:
                defaults.set(tmpSelectedField, forKey: "workoutKpiView2")
                kpi2Value.text=String(ble.rdKpi.valueByPropertyName(name:tmpSelectedField))
                kpiFieldName[2]=tmpSelectedField
            case 3:
                defaults.set(tmpSelectedField, forKey: "workoutKpiView3")
                kpi3Value.text=String(ble.rdKpi.valueByPropertyName(name:tmpSelectedField))
                kpiFieldName[3]=tmpSelectedField
            case 4:
                defaults.set(tmpSelectedField, forKey: "workoutKpiView4")
                kpi2Value.text=String(ble.rdKpi.valueByPropertyName(name:tmpSelectedField))
                kpiFieldName[4]=tmpSelectedField
            default:
                print("")
        }
        
        //defaults.set(tmpSelectedField, forKey: "workoutKpiView1")
        
        kpi1Value.text=String(ble.rdKpi.valueByPropertyName(name:tmpSelectedField))
    
        self.view.endEditing(true)
    }

    var kpiFieldName:[String]!
    
    @IBOutlet weak var iconBleFitnessServiceConnection:UIImageView!
    @IBOutlet weak var iconBleBatteryServiceConnection:UIImageView!
    @IBOutlet weak var iconBleHeartRateServiceConnection:UIImageView!
    
    @IBOutlet weak var barChart: BarChartView!
    @IBOutlet weak var sendReset: UIButton!
    @IBOutlet weak var sendDistance: UIButton!
   
    @IBOutlet weak var kpi1View: UIView!
    @IBOutlet weak var kpi1Label: UILabel!
    @IBOutlet weak var kpi1Value: UILabel!
    
    @IBOutlet weak var kpi2View: UIView!
    @IBOutlet weak var kpi2Label: UILabel!
    @IBOutlet weak var kpi2Value: UILabel!
    
    @IBOutlet weak var kpi3View: UIView!
    @IBOutlet weak var kpi3Label: UILabel!
    @IBOutlet weak var kpi3Value: UILabel!
    
    @IBOutlet weak var kpi4View: UIView!
    @IBOutlet weak var kpi4Label: UILabel!
    @IBOutlet weak var kpi4Value: UILabel!
    
    var rowerDataFieldPicker: UIPickerView!
    var rowerDataFieldToolbar: UIToolbar!
   
    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
   
    var workoutType:Int=0;
    var workoutTargetValue:Double=0;
    
    var ble:bleStack!
    
    var fieldPickerTitleData: [String]!
    var fieldPickerValueData: [String]!
    
    var kpiFieldUnit:[String:String] = [:]
    var kpiFieldLabel:[String:String] = [:]
    
    var activeKpiViewID:Int!=0
    var tmpSelectedField:String!
   
    @IBAction func showPicker(_ sender: viewTapGesture) {
       
        activeKpiViewID=sender.viewID
        rowerDataFieldPicker = UIPickerView.init()
        rowerDataFieldPicker.delegate = self
        rowerDataFieldPicker.dataSource = self
    
        rowerDataFieldPicker.backgroundColor = UIColor.black
        rowerDataFieldPicker.setValue(UIColor.white, forKey: "textColor")
        rowerDataFieldPicker.autoresizingMask = .flexibleWidth
        rowerDataFieldPicker.contentMode = .center
        rowerDataFieldPicker.frame = CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
        
        self.view.addSubview(rowerDataFieldPicker)

        rowerDataFieldToolbar = UIToolbar.init(frame: CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 50))
        
        rowerDataFieldToolbar.barStyle = .black
        rowerDataFieldToolbar.isTranslucent = true
        rowerDataFieldToolbar.items = [UIBarButtonItem]()
        rowerDataFieldToolbar.items?.append(UIBarButtonItem(barButtonSystemItem: .done, target: self, action:#selector( onDoneButtonTapped)))
     
        self.view.addSubview(rowerDataFieldToolbar)
    }
    
    @objc func onDoneButtonTapped(){
        rowerDataFieldToolbar.removeFromSuperview()
        rowerDataFieldPicker.removeFromSuperview()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        barChartUpdate()
        ble = bleStack.sharedInstance;
        ble.delegate = self
        
        // Input the data into the array
        
        let tap1View = viewTapGesture(target: self, action: #selector(self.showPicker(_:)))
        tap1View.viewID=1
        kpi1View.addGestureRecognizer(tap1View)
        
        let tap2View = viewTapGesture(target: self, action: #selector(self.showPicker(_:)))
        tap2View.viewID=2
        kpi2View.addGestureRecognizer(tap2View)
        
        let tap3View = viewTapGesture(target: self, action: #selector(self.showPicker(_:)))
        tap3View.viewID=3
        kpi3View.addGestureRecognizer(tap3View)
        
        let tap4View = viewTapGesture(target: self, action: #selector(self.showPicker(_:)))
        tap4View.viewID=4
        kpi4View.addGestureRecognizer(tap4View)
        
        fieldPickerTitleData = ["Stroke count", "Stroke rate", "Average stroke rate", "Total distance", "Instantaneous pace", "Average pace","Instantaneous power","Average power","Resistance level","Total energy","Energy per hour","Energy per minute", "Heart rate","Metabolic equivalent","Elapsed time","Remaining time"]
        
        
        fieldPickerValueData = ["strokeCount", "", "averageStrokeRate", "totalDistance", "instantaneousPace", "averagePace","instantaneousPower","averagePower","resistanceLevel","totalEnergy","energyPerHour","energyPerMinute", "heartRate","metabolicEquivalent","elapsedTime","remainingTime"]
        
        kpiFieldLabel = ["strokeCount": "Stroke count",
                             "averageStrokeRate": "Average stroke rate",
                             "totalDistance": "Total distance",
                             "instantaneousPace": "Instantaneous pace",
                             "averagePace": "Average pace",
                             "instantaneousPower": "Instantaneous power",
                             "averagePower": "Average power",
                             "resistanceLevel": "Resistance level",
                             "totalEnergy": "Total energy",
                             "energyPerHour": "Energy per hour",
                             "energyPerMinute": "Energy per minute",
                             "heartRate":"Heart rate",
                             "metabolicEquivalent":"Metabolic equivalent",
                             "elapsedTime":"Elapsed time",
                             "remainingTime":"Remaining time"
        ]
        
        kpiFieldUnit = ["strokeCount": "",
                             "averageStrokeRate": "s/min",
                             "totalDistance": "m",
                             "instantaneousPace": "m/s",
                             "averagePace": "m/s",
                             "instantaneousPower": "w",
                             "averagePower": "w",
                             "resistanceLevel": "",
                             "totalEnergy": "cal",
                             "energyPerHour": "cal",
                             "energyPerMinute": "cal",
                             "heartRate":"Bpm",
                             "metabolicEquivalent":"",
                             "elapsedTime":"",
                             "remainingTime":""
        ]
        
        kpi1View.clipsToBounds = true
        kpi1View.layer.cornerRadius = 10
        
        kpi2View.clipsToBounds = true
        kpi2View.layer.cornerRadius = 10
        
        kpi3View.clipsToBounds = true
        kpi3View.layer.cornerRadius = 10
        
        kpi4View.clipsToBounds = true
        kpi4View.layer.cornerRadius = 10
        
        kpiFieldName = [String](repeating: "", count: 5)
        
        let defaults = UserDefaults.standard
        
        kpiFieldName[1] = defaults.string(forKey: "workoutKpiView1") ?? ""
        kpiFieldName[2] = defaults.string(forKey: "workoutKpiView2") ?? ""
        kpiFieldName[3] = defaults.string(forKey: "workoutKpiView3") ?? ""
        kpiFieldName[4] = defaults.string(forKey: "workoutKpiView4") ?? ""
    }
    
    func onBleConnectionDidChange(pType: Int, isConnected: Bool) {
       
        
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
        
        
    }
    
    func onBleDataNotification(bleData:rowerDataKpi) {
        
        //kpi1Label.text=String(bleData.strokeCount);
        
        let defaults = UserDefaults.standard
        if(kpiFieldName[1]  == "" && defaults.string(forKey: "workoutKpiView1") ?? "" != "" ){
            kpiFieldName[1] = defaults.string(forKey: "workoutKpiView1") ?? ""
        }else if (kpiFieldName[1]  == ""){
            kpiFieldName[1] = "totalDistance"
        }
        kpi1Value.text=String(ble.rdKpi.valueByPropertyName(name:kpiFieldName[1]))
        kpi1Label.text=String(kpiFieldLabel[kpiFieldName[1]] ?? "")
        
        if(kpiFieldName[2] == "" && defaults.string(forKey: "workoutKpiView2") ?? "" != ""){
            kpiFieldName[2] = defaults.string(forKey: "workoutKpiView2") ?? ""
        }else if (kpiFieldName[2] == ""){
            kpiFieldName[2] = "strokeRate"
        }
        kpi2Value.text=String(ble.rdKpi.valueByPropertyName(name:kpiFieldName[2]))
        kpi2Label.text=String(kpiFieldLabel[kpiFieldName[2]] ?? "")
        
    }
    
    @IBAction func sendReset(_ sender: UIButton) {
        print("sendReset to S4")
        ble.setBleResetCommand()
    }
    
    @IBAction func sendDistance(_ sender: UIButton) {
        print("set Workout Distance")
        let distance=4500;
        ble.setBleWorkout(workoutType:1,workoutValue: distance)
    }
    
    @IBAction func sendDuration(_ sender: UIButton) {
        print("set Workout Distance")
        let duration=3600;
        ble.setBleWorkout(workoutType:0,workoutValue: duration)
    }
    
    func barChartUpdate () {
        var entry=BarChartDataEntry(x:1.0,y:Double(10));
        
        // Basic set up of plan chart
        barChart.xAxis.drawLabelsEnabled=false
        barChart.rightAxis.drawLabelsEnabled=false
        barChart.leftAxis.drawLabelsEnabled=false
        barChart.leftAxis.drawGridLinesEnabled=false
        barChart.drawGridBackgroundEnabled=false
    
        var dataSet=BarChartDataSet(entries:[entry],label: "split time/500m")
        var i = 1
        
        // Lazy initialization so the timer isn’t initialized until we call it
        var timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {timer in
            guard i <= 20 else {
                    timer.invalidate()
                    return
                }
            i+=1
            
        
                /*
                    let entry1 = BarChartDataEntry(x: 1.0, y: Double(10))
                    let entry2 = BarChartDataEntry(x: 2.0, y: Double(20))
                    let entry3 = BarChartDataEntry(x: 3.0, y: Double(30))
                    let dataSet = BarChartDataSet(entries: [entry1, entry2, entry3,entry1, entry2, entry3], label: "Widgets Type")
                */
           
                entry=BarChartDataEntry(x:Double(i),y:Double(10*i));
                dataSet.append(entry);
                dataSet.setColor(UIColor(red: 0, green: 185/255, blue: 255, alpha: 1.0))
                dataSet.drawValuesEnabled=false;
                let data = BarChartData(dataSets: [dataSet])
                self.barChart.data = data
                self.barChart.notifyDataSetChanged()

            }
        }
    
}

