//
//  bleStack.swift
//  S4BL3 IOS
//
//  Created by vincent.besson on 19/10/2020.
//

import CoreBluetooth

// https://github.com/oesmith/gatt-xml/blob/master/org.bluetooth.characteristic.rower_data.xml
// https://github.com/oesmith/gatt-xml/blob/master/org.bluetooth.characteristic.fitness_machine_control_point.xml
// https://github.com/oesmith/gatt-xml/blob/master/org.bluetooth.characteristic.fitness_machine_feature.xml

let heartRateServiceCBUUID =                CBUUID(string: "180D")
let heartRateMeasurementCxCBUUID =          CBUUID(string: "2A37")
let bodySensorLocationCxCBUUID =            CBUUID(string: "2A38")

let fitnessServiceCBUUID =                  CBUUID(string: "0x1826")
let fitnessMachineControlPointCBUUID =      CBUUID(string: "0x2AD9")        // CX Not implemented yet
let fitnessMachineFeatureCBUUID =           CBUUID(string: "0x2ACC")        // CX Not implemented yet
let fitnessMachineStatusCBUUID =            CBUUID(string: "0x2ADA")       // CX Not implemented yet
let fitnessMachineRowerDataCBUUID =         CBUUID(string: "0x2AD1")      // CX Main cx implemented

let batteryServiceCBUUID =                  CBUUID(string:"0x180F")            // Additionnal battery service
let batteryLevelCBUUID =                    CBUUID(string:"0x2A19")            // Additionnal cx to battery service

struct rowerDataKpi{
  var strokeCount=0;
  var tmpstrokeRate=0;
  var strokeRate=0;
  var averageStrokeRate=0;
  var totalDistance=0;
  var instantaneousPace=0;
  var tmpinstantaneousPace=0;
  var averagePace=0;
  var instantaneousPower=0;
  var averagePower=0;
  var resistanceLevel=0;
  var totalEnergy=0; // Start of Part 2
  var energyPerHour=0;
  var energyPerMinute=0;
  var heartRate=0;
  var metabolicEquivalent=0;
  var elapsedTime=0;
  var elapsedTimeSec=0;
  var elapsedTimeMin=0;
  var elapsedTimeHour=0;
  var remainingTime=0;
    
    func valueByPropertyName(name:String) -> Int {
        switch name {
            case "strokeCount": return strokeCount
            case "strokeRate": return strokeRate
            case "averageStrokeRate": return averageStrokeRate
            case "totalDistance": return totalDistance
            case "instantaneousPace": return instantaneousPace
            case "averagePace": return averagePace
            case "instantaneousPower": return instantaneousPower
            case "averagePower": return averagePower
            case "resistanceLevel": return resistanceLevel
            case "totalEnergy": return totalEnergy
            case "energyPerHour": return energyPerHour
            case "energyPerMinute": return energyPerMinute
            case "heartRate": return heartRate
            case "metabolicEquivalent": return metabolicEquivalent
            case "elapsedTime": return elapsedTime
            case "remainingTime": return remainingTime
           
            default: fatalError("Wrong property name")
        }
    }
    
};


protocol bleStackDelegate {
     func onBleDataNotification(bleData:rowerDataKpi)
     func onBleConnectionDidChange(pType:Int,isConnected:Bool)
}

public class bleStack: NSObject {
    public static let sharedInstance = bleStack() // used to declare the singleton

    var centralManager: CBCentralManager!
    var fitnessPeripheral: CBPeripheral!
    var heartRatePeripheral: CBPeripheral!
    
    var isFitnessPeripheralConnected:Bool=false
    var isFitnessPeripheralHasBatteryService:Bool=false
    var isHeartRatePeripheralConnected:Bool=false
    
    
    var pType=0; // Peripheral Type
  
    var rdKpi:rowerDataKpi!
   
    var delegate: bleStackDelegate?
    
    private override init() {
        super.init()
       /* do{
          // try rowerDataStub()
        }catch{
            
        }*/
        // L'initialisation est privé pour être sur qu'une seule instance sera créé
        centralManager = CBCentralManager(delegate: self, queue: nil)
        rdKpi=rowerDataKpi();
  }
}

extension bleStack: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .unknown:
               print("central.state is .unknown")
             case .resetting:
               print("central.state is .resetting")
             case .unsupported:
               print("central.state is .unsupported")
             case .unauthorized:
               print("central.state is .unauthorized")
             case .poweredOff:
               print("central.state is .poweredOff")
             case .poweredOn:
                pType=0; // Peripheral=0 start with fitness
                centralManager.scanForPeripherals(withServices: [fitnessServiceCBUUID/*,heartRateServiceCBUUID*/])
                
        @unknown default:
           print("fatal error")
        }
    }
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                          advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        if (pType==0){
            //print("here 1")
            fitnessPeripheral = peripheral
            fitnessPeripheral.delegate = self
            centralManager.stopScan()
            centralManager.connect(fitnessPeripheral)
            /* Let's connect the heartRate monitor if any */
            pType=1
            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
            
        }else{
            //print("here 2")
            heartRatePeripheral=peripheral
            heartRatePeripheral.delegate=self
            centralManager.stopScan()
            centralManager.connect(heartRatePeripheral)
        }
        
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        
        if (fitnessPeripheral==peripheral){
            fitnessPeripheral.discoverServices([fitnessServiceCBUUID,batteryServiceCBUUID])
            delegate?.onBleConnectionDidChange(pType:0,isConnected:true)
            isFitnessPeripheralConnected = true
        }else if (heartRatePeripheral==peripheral){
            heartRatePeripheral.discoverServices([heartRateServiceCBUUID,batteryServiceCBUUID])
            delegate?.onBleConnectionDidChange(pType:1,isConnected:true)
            isHeartRatePeripheralConnected = true
        }
    }
    
    public func centralManager(_ central: CBCentralManager,didDisconnectPeripheral peripheral: CBPeripheral,error: Error?){
        print("Disconnected")
        
        if (fitnessPeripheral==peripheral){
            delegate?.onBleConnectionDidChange(pType:0,isConnected:false)
            isHeartRatePeripheralConnected = false
        }else if (heartRatePeripheral==peripheral){
            delegate?.onBleConnectionDidChange(pType:1,isConnected:false)
            isHeartRatePeripheralConnected = false
        }
        
        // This is for automatic reconnection of Peripheral
        centralManager.connect(peripheral)
    }
    
    func findCharacteristicByID(characteristicID: CBUUID) -> CBCharacteristic? {
        if let services = fitnessPeripheral.services {
          for service in services {
            for characteristic in service.characteristics! {
                if characteristic.uuid == characteristicID {
                    return characteristic
                }
            }
          }
        }
        return nil
    }
    
    public func setBleResetCommand(){
        var sData = NSData(bytes: [0x00] as [UInt8], length: 1);
        sendFitnessControlPoint(sData: sData)
        
        sData = NSData(bytes: [0x01] as [UInt8], length: 1);
        sendFitnessControlPoint(sData: sData)
    }
    
    public func setBleWorkout(workoutType:Int, workoutValue:Int) {
       
        // workType=0 => Duration workout
        // workType=1 => Distance workout
        // workType=2 => Stroke   workout
        
        setBleResetCommand() // always start with a Reset for the S4
        
        let c1=(UInt8)(workoutValue &  0x000000FF)
        let c2=(UInt8)((workoutValue & 0x0000FF00 ) >> 8)
        let c3=(UInt8)((workoutValue & 0x00FF0000 ) >> 16) // use for distance
        
        var sData:NSData!
        
        if (workoutType == 0){
            sData=NSData(bytes:[0x0D,c1,c2], length: 3)         //UINT16
            sendFitnessControlPoint(sData: sData)
        }
        
        if (workoutType == 2){
            sData=NSData(bytes:[0x0C,c1,c2,c3], length: 4)      // UINT24
            sendFitnessControlPoint(sData: sData)
        }
        
        if (workoutType == 3){
            sData=NSData(bytes:[0x0B,c1,c2], length: 3)         // UINT16
            sendFitnessControlPoint(sData: sData)
        }
    }
    
    public func sendFitnessControlPoint(sData:NSData){
        if let characteristic = findCharacteristicByID(characteristicID: fitnessMachineControlPointCBUUID) {
            print ("SendControlPoint");
            print (characteristic);
            
            fitnessPeripheral.writeValue(sData as Data, for: characteristic, type: .withResponse)
        }
    }
}

extension bleStack: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
          print(service)
          peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
          return
        }
         print("Message sent")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
          print(characteristic)

            if (characteristic.uuid == batteryLevelCBUUID && peripheral == fitnessPeripheral){
                isFitnessPeripheralHasBatteryService = true
                delegate?.onBleConnectionDidChange(pType:0,isConnected:true)
            }
            
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
            
            case fitnessMachineStatusCBUUID:
                fitnessStatus(from: characteristic)
                
            case fitnessMachineRowerDataCBUUID:
                rowerData(from: characteristic)
                
            case batteryLevelCBUUID:
                //print()
                print(batteryLevel(from:characteristic))
                
            case heartRateMeasurementCxCBUUID:
                rdKpi.heartRate=heartRate(from: characteristic)
                print("Heart rate:\(rdKpi.heartRate)")
    
        default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }

    private func batteryLevel(from characteristic:CBCharacteristic)->Int{
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        return Int(byteArray[0]);
    }
    
    private func rowerData(from characteristic:CBCharacteristic) {
        guard let characteristicData = characteristic.value else { return }
        let byteArray = [UInt8](characteristicData)

        do{
            try decodeRowerDataBitfield(byteArray:byteArray);
        }catch{
            print ("");
        }
    }
    
    private func fitnessStatus(from characteristic:CBCharacteristic){
        guard let characteristicData = characteristic.value else { return }
        print ("fitnessStatus:" )
    }
    
    private func rowerDataStub() throws {
        var byteArray=Array(repeating: UInt8(), count: 10);
        
        let rowerDataFlags=0b0000001111110;
        
        byteArray[1]=(UInt8)(rowerDataFlags & 0x000000FF);
        byteArray[0]=(UInt8)((rowerDataFlags & 0x0000FF00) >> 8);
        do{
            try decodeRowerDataBitfield(byteArray:byteArray);
        }catch{
            print("")
        }
    }
    
    enum rowerDataMessageError: Error {
        case invalidMessageFormat
        case invalidLength(lengthExpected:Int)
    }
    
    private func decodeRowerDataBitfield(byteArray:[UInt8]) throws{
        
        // 0000000000001 - 1   - 0x001 + More Data 0 <!> WARNINNG <!> This Bit is working the opposite way, 0 means field is present, 1 means not present
         // 0000000000010 - 2   - 0x002 + Average Stroke present
         // 0000000000100 - 4   - 0x004 + Total Distance Present
         // 0000000001000 - 8   - 0x008 + Instantaneous Pace present
         // 0000000010000 - 16  - 0x010 + Average Pace Present
         // 0000000100000 - 32  - 0x020 + Instantaneous Power present
         // 0000001000000 - 64  - 0x040 + Average Power present
         // 0000010000000 - 128 - 0x080 - Resistance Level present
         // 0000100000000 - 256 - 0x080 + Expended Energy present
         // 0001000000000 - 512 - 0x080 - Heart Rate present
         // 0010000000000 - 1024- 0x080 - Metabolic Equivalent present
         // 0100000000000 - 2048- 0x080 - Elapsed Time present
         // 1000000000000 - 4096- 0x080 - Remaining Time present

         //  C1  Stroke Rate             uint8     Position    2   (After the Flag 2bytes)
         //  C1  Stroke Count            uint16    Position    3
         //  C2  Average Stroke Rate     uint8     Position    5
         //  C3  Total Distance          uint24    Position    6
         //  C4  Instantaneous Pace      uint16    Position    9
         //  C5  Average Pace            uint16    Position    11
         //  C6  Instantaneous Power     sint16    Position    13
         //  C7  Average Power           sint16    Position    15
         //  C8  Resistance Level        sint16    Position    17
         //  C9  Total Energy            uint16    Position    19
         //  C9  Energy Per Hour         uint16    Position    21
         //  C9  Energy Per Minute       uint8     Position    23
         //  C10 Heart Rate              uint8     Position    24
         //  C11 Metabolic Equivalent    uint8     Position    25
         //  C12 Elapsed Time            uint16    Position    26
         //  C13 Remaining Time          uint16    Position    28

        
        let bitField=(UInt16)((Int(byteArray[1]) << 8) + Int(byteArray[0]))
        
        //print("Bitfield:"+String(bitField));
        
        var flg=0
        var pos=2; // After the 2 initial Bytes
        var len=0; // Length of the block field
        
        for i in 1..<14{

            flg=(Int)((bitField /*& 0x00FF*/) >> (i-1)) & 0b0000000000000001
            switch i{
                case 1:
                    /* <!> Read the GATT Manual 0 Means Active */
                    //  C1  Stroke Rate             uint8     Position    2  <!> (After the Flag 2bytes)
                    //  C1  Stroke Count            uint16    Position    3
                    len=3;
                    if flg == 0 && byteArray.count >= (pos+len) {
                        rdKpi.strokeRate = Int(byteArray[pos])
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.strokeRate=" + String(rdKpi.strokeRate))
                        #endif
                        pos+=1
                        
                        rdKpi.strokeCount =  Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.strokeCount=" + String(rdKpi.strokeCount))
                        #endif
                        pos+=2
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 2:
                    //  C2  Average Stroke Rate     uint8     Position    5
                    len=1;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.averageStrokeRate = Int(byteArray[pos])
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.averageStrokeRate=" + String(rdKpi.averageStrokeRate))
                        #endif
                        pos+=1
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 3:
                    //  C3  Total Distance          uint24    Position    6  +
                    len=3;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.totalDistance = Int(byteArray[pos+2]<<16) + Int(byteArray[pos+1] << 8) + Int(byteArray[pos])
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.totalDistance=" + String(rdKpi.totalDistance))
                        #endif
                        pos+=3
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 4:
                    //  C4  Instantaneous Pace      uint16    Position    9  +
                    len=2;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.instantaneousPace = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.instantaneousPace=" + String(rdKpi.instantaneousPace))
                        #endif
                        pos+=2
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 5:
                    //  C5  Average Pace            uint16    Position    11
                    len=2;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.averagePace = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.averagePace=" + String(rdKpi.averagePace))
                        #endif
                        pos+=2
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 6:
                    //  C6  Instantaneous Power     sint16    Position    13
                    len=2;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.instantaneousPower = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.instantaneousPower=" + String(rdKpi.instantaneousPower))
                        #endif
                        pos+=2
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 7:
                    //  C7  Average Power           sint16    Position    15
                    len=2;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.averagePower = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.averagePower=" + String(rdKpi.averagePower))
                        #endif
                        pos+=2
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 8:
                    //  C8  Average Power           sint16    Position    15
                    len=2;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.resistanceLevel = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.resistanceLevel=" + String(rdKpi.resistanceLevel))
                        #endif
                        pos+=2
                    }else if(byteArray.count<(pos+len)){
                        print("Not Enough Space")
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 9:
                    //  C9  Total Energy            uint16    Position    19
                    //  C9  Energy Per Hour         uint16    Position    21
                    //  C9  Energy Per Minute       uint8     Position    23
                    len=5;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.totalEnergy = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.totalEnergy=" + String(rdKpi.totalEnergy))
                        #endif
                        pos+=2
                        
                        rdKpi.energyPerHour = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.energyPerHour=" + String(rdKpi.energyPerHour))
                        #endif
                        pos+=2
                        
                        rdKpi.energyPerMinute = Int(byteArray[pos])
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.energyPerMinute=" + String(rdKpi.energyPerMinute))
                        #endif
                        pos+=1
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 10:
                    //  C10 Heart Rate              uint8     Position    24
                    len=1;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.heartRate = Int(byteArray[pos])
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.heartRate=" + String(rdKpi.heartRate))
                        #endif
                        pos+=1
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 11:
                    //  C11 Metabolic Equivalent    uint8     Position    25
                    len=1;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.metabolicEquivalent = Int(byteArray[pos])
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.metabolicEquivalent=" + String(rdKpi.metabolicEquivalent))
                        #endif
                        pos+=1
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 12:
                    //  C12 Elapsed Time            uint16    Position    26
                    len=2;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.elapsedTime = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.elapsedTime=" + String(rdKpi.elapsedTime))
                        #endif
                        pos+=2
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                case 13:
                    //  C13 Remaining Time          uint16    Position    28
                    len=2;
                    if (flg==1 && byteArray.count >= (pos+len)){
                        rdKpi.remainingTime = Int(byteArray[pos+1] << 8) + Int(byteArray[pos]);
                        #if DEBUG
                            print("C\(i) pos=\(pos),rdKpi.remainingTime=" + String(rdKpi.remainingTime))
                        #endif
                        pos+=2
                    }else if(byteArray.count<(pos+len)){
                        throw rowerDataMessageError.invalidLength(lengthExpected: len)
                    }
                    
                default:
                    print("")
            }
        }
        
        delegate?.onBleDataNotification(bleData:rdKpi)

    }
    
  private func heartRate(from characteristic: CBCharacteristic) -> Int {
    guard let characteristicData = characteristic.value else { return -1 }
    let byteArray = [UInt8](characteristicData)

    // See: https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.heart_rate_measurement.xml
    // The heart rate mesurement is in the 2nd, or in the 2nd and 3rd bytes, i.e. one one or in two bytes
    // The first byte of the first bit specifies the length of the heart rate data, 0 == 1 byte, 1 == 2 bytes
    let firstBitValue = byteArray[0] & 0x01
    if firstBitValue == 0 {
      // Heart Rate Value Format is in the 2nd byte
      return Int(byteArray[1])
    } else {
      // Heart Rate Value Format is in the 2nd and 3rd bytes
      return (Int(byteArray[1]) << 8) + Int(byteArray[2])
    }
  }
}

