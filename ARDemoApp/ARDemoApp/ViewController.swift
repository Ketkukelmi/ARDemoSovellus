//
//  ViewController.swift
//  ARDemoApp
//
//  Created by CubiCasa Office on 10/01/2019.
//  Copyright © 2019 CubiCasa Office. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var modeButton: UIButton!
    @IBOutlet weak var chooseButton: UIButton!
    @IBOutlet weak var okButtonO: UIButton!
    @IBAction func okButton(_ sender: Any) {
        if !placeOk{
            placeOk = true
        }else{
            placeOk = false
        }
    }
    @IBOutlet weak var rotateB: UIButton!
    @IBAction func rotateButton(_ sender: Any) {
        rotationInY += 0.05
    }
    @IBAction func mode(_ sender: Any) {
        if !mode{
            mode = true
            modeButton.setTitle("Measure", for: .normal)
            chooseButton.isHidden = false
            okButtonO.isHidden = false
            rotateB.isHidden = false
            currentObject?.removeFromParentNode()
        }else{
            mode = false
            modeButton.setTitle("Place", for: .normal)
            chooseButton.isHidden = true
            okButtonO.isHidden = true
            rotateB.isHidden = true
        }
    }
    @IBAction func choose(_ sender: Any) {
        currentObject?.removeFromParentNode()
        let controller = ArrayChoiceTableViewController(Dmodels) { (dmodel) in
            print("\(dmodel) selected")
            self.anotherPopUp(model: dmodel)
        }
        rotationInY = 0.0
        controller.modalPresentationStyle = .popover
        controller.preferredContentSize = CGSize(width: 300, height: 200)
        let presentationController = controller.presentationController as! UIPopoverPresentationController
        presentationController.sourceView = self.view
        controller.popoverPresentationController?.delegate = self
        presentationController.sourceRect = CGRect(x: 50, y: 700, width: (sender as AnyObject).frame.size.width, height: (sender as AnyObject).frame.size.height)
        presentationController.permittedArrowDirections = [.down]
        self.present(controller, animated: true)
        
       

    }
    fileprivate lazy var rotationInY = 0.0
    fileprivate lazy var Dmodels = ["Sofa", "Table", "Bed"]
    fileprivate lazy var session = ARSession()
    fileprivate lazy var configuration = ARWorldTrackingConfiguration()
    fileprivate lazy var isMeasuring = false
    fileprivate lazy var vectorZero = SCNVector3()
    fileprivate lazy var startValue = SCNVector3()
    fileprivate lazy var endValue = SCNVector3()
    fileprivate lazy var lines: [MeasureNode] = []
    fileprivate lazy var objecIsChosen = false
    fileprivate var currentLine: MeasureNode?
    fileprivate var measurements = [Float]()
    fileprivate var allMeasurements = [Any]()
    fileprivate var canMark : Bool = false
    fileprivate var keys = [String]()
    fileprivate var mode : Bool = false // false for measuring and true for placing
    fileprivate var modelName : String = ""
    fileprivate lazy var modelMeasurements = [Float]()
    fileprivate var objectsOnScene: [ObjectNode] = []
    fileprivate var currentObject: ObjectNode?
    fileprivate var createonce : Bool = true
    fileprivate var placeOk : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let configuration = ARWorldTrackingConfiguration()
        //sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        //sceneView.session.run(configuration)
        chooseButton.isHidden = true
        setupScene()
        getKeys()
        for key in keys{
            getMeasurements(key : key)
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mode{
            objecIsChosen = true
        }else{
            resetValues()
            isMeasuring = true
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mode{
            objecIsChosen = false
        }else{
            
            if let line = currentLine {
                lines.append(line)
                print(lines.count)
                currentLine = nil
                canMark = true
            }
        }
        isMeasuring = false
        

        
    }
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    func anotherPopUp(model : String){
        let controller = ArrayChoiceTableViewController(keys) { (key) in
            print("\(key) selected")
            let objectMeasurement = self.getMeasurements(key: key)
            let values = objectMeasurement as! [Float]
            print(values)
            self.modelMeasurements = values
            self.modelName = model
            self.createonce = true
            
        }
        
        controller.modalPresentationStyle = .popover
        controller.preferredContentSize = CGSize(width: 300, height: 200)
        let presentationController = controller.presentationController as! UIPopoverPresentationController
        presentationController.sourceView = self.view
        controller.popoverPresentationController?.delegate = self
        presentationController.sourceRect = CGRect(x: 50, y: 700, width: 300, height: 200)
        presentationController.permittedArrowDirections = [.down]
        self.present(controller, animated: true)
    }
    
    func addObject(){
        let ball = SCNSphere.init(radius: 0.75)
        ball.firstMaterial?.diffuse.contents = UIColor.white
        ball.firstMaterial?.lightingModel = .constant
        ball.firstMaterial?.isDoubleSided = true
        
        let node = SCNNode.init(geometry: ball)
        node.position = SCNVector3.init(1, 0, 0)
        sceneView.scene.rootNode.addChildNode(node)
    }
    func saveState(){
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else {
                    print("Can't get current world map error: \(error!.localizedDescription)")
                    return
            }
            let mapUrl = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/worldMap"
            let mapURL = URL(string: mapUrl)
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: mapURL!, options: [.atomic])
            } catch {
                print("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    func retrieveData(url : URL) -> Data?{
        do{
            return try Data(contentsOf: url)
        }catch{
            print("No data found")
        }
        return nil
    }
    func loadState(data : Data) -> ARWorldMap{
        do {
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                else { fatalError("No ARWorldMap in archive.") }
            return worldMap
        } catch {
            fatalError("Can't unarchive ARWorldMap from file data: \(error)")
        }
    }
}
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            if !self!.mode{
                self?.detectObjects()
            }else{
                
                self?.placeObjects()
            }
        }
    }
}
extension ViewController {
    fileprivate func setupScene() {
        targetImageView.isHidden = true
        sceneView.delegate = self
        sceneView.session = session
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        resetValues()
    }
    
    fileprivate func resetValues() {
        isMeasuring = false
        
        startValue = SCNVector3()
        endValue =  SCNVector3()
    }
    fileprivate func resetValuesNode() {
        objecIsChosen = false
        
        startValue = SCNVector3()
        endValue =  SCNVector3()
    }
    fileprivate func removeValues(){
        for line in lines {
            line.removeFromParentNode()
        }
        //measurements.removeAll()
    }
    fileprivate func placeObjects(){
        guard let worldPosition = sceneView.realWorldVector(screenPosition: view.center) else { return }
        targetImageView.isHidden = false
        if createonce{
            print("käy tääl")
            startValue = worldPosition
            currentObject = ObjectNode(scene: sceneView, vector: startValue, objName: modelName)
            createonce = false
        }
        if objecIsChosen{
            startValue = worldPosition
            currentObject?.update(to: startValue)
            currentObject?.rotateNode(withTrans: SCNVector3(x: 0, y: Float(rotationInY), z: 0))
            resetValuesNode()
        }else{
            endValue = worldPosition
            currentObject?.update(to: endValue)
            currentObject?.rotateNode(withTrans: SCNVector3(x: 0, y: Float(rotationInY), z: 0))
        }
        if placeOk{
            currentObject?.place(vector: worldPosition)
            let object = PlaceNode(scene: sceneView, vector: endValue, objName: modelName, measurement: modelMeasurements)
            object.rotateNode(withTrans: SCNVector3(x: 0, y: Float(rotationInY), z: 0))
            placeOk = false
            
        }
        
    }
    fileprivate func detectObjects() {
        guard let worldPosition = sceneView.realWorldVector(screenPosition: view.center) else { return }
        targetImageView.isHidden = false
        if isMeasuring {
            if startValue == vectorZero {
                startValue = worldPosition
                currentLine = MeasureNode(scene: sceneView, vector: startValue)
            }
            endValue = worldPosition
            currentLine?.update(to: endValue)

            
        }else{
            endValue = worldPosition
            if lines.count == 1 && canMark{
                
                let lengthLine = vectorDistance(v1: startValue, v2: endValue)
                
                measurements.append(lengthLine)
                canMark = false
            }
            if lines.count == 2 && canMark{
               
                let heightLine = vectorDistance(v1: startValue, v2: endValue)
                
                measurements.append(heightLine)
                canMark = false
            }
            if lines.count == 3 && canMark{
                
                let widthLine = vectorDistance(v1: startValue, v2: endValue)
                print("käytäällä")
                measurements.append(widthLine)
                canMark = false
                showFinishAlert()
                lines.removeAll()
                removeValues()
                
            }
        }
    }
    func vectorDistance(v1: SCNVector3, v2: SCNVector3) -> Float{
        let x = v1.x - v2.x
        let y = v1.y - v2.y
        let z = v1.z - v2.z
        
        return sqrt((x*x)+(y*y)+(z*z))
    }
    
    func showFinishAlert(){
        let alert = UIAlertController(title : "Save measurements", message: nil, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            let textField = alert.textFields![0]
            self.writeMeasurementToMemory(arrayToMemory:  self.measurements, withKey: textField.text!)
            self.keys.append(textField.text!)
            self.writeKeysToMemory(arrayToMemory: self.keys)
            self.measurements.removeAll()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            
        }))
        
        self.present(alert, animated: true)
    }
    func writeKeysToMemory(arrayToMemory : [String]){
        let preferences = UserDefaults.standard
        preferences.set(arrayToMemory, forKey: "KEYS")
        print("writing \(arrayToMemory)")
    }
    func writeMeasurementToMemory(arrayToMemory : [Float], withKey : String){
        let preferences = UserDefaults.standard
        preferences.set(arrayToMemory, forKey: withKey)
    }
    func getKeys(){
        let preferences = UserDefaults.standard
        if preferences.array(forKey: "KEYS") == nil {
            print("nothing here")
        }
        else{
            keys = preferences.array(forKey: "KEYS") as! [String]
            print(keys)
        }
    }
    
    func getMeasurements(key : String) -> [Any]{
        let preferences = UserDefaults.standard
        if preferences.array(forKey: key) == nil {
            print("Fuck")
        }else{
            print("pitäs käyä täällä")
            print("\(key) : \(preferences.array(forKey: key))")
            return preferences.array(forKey: key)!
        }
        return ["Empty"]
    }
}


