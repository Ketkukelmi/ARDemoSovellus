import Foundation
import ARKit
import SceneKit

class PlaceNode {
    var node = SCNNode()
    var placementNode = SCNNode()
    var sceneView = ARSCNView()
    var startVector = SCNVector3()
    var scale = [Float]()
    
    init(scene: ARSCNView, vector: SCNVector3, objName: String, measurement: [Float]){
        self.sceneView = scene
        self.startVector = vector
        
        switch (objName) {
        case "Bed":
            let bedX = 2.192 / measurement[0]
            let bedY = 1.169 / measurement[1]
            let bedZ = 1.649 / measurement[2]
            node.scale = SCNVector3(bedX,bedY,bedZ)
            
        case "Sofa":
            let sofaX = 0.735 / measurement[2]
            let sofaY = 0.737 / measurement[1]
            let sofaZ = 2.069 / measurement[0]
            node.scale = SCNVector3(sofaX,sofaY,sofaZ)
        
        case "Table":
            let tableX = 1.731 / measurement[0]
            let tableY = 0.713 / measurement[1]
            let tableZ = 0.965 / measurement[2]
            node.scale = SCNVector3(tableX,tableY,tableZ)
        default:
            print("not possible")
        }
        
        let objectName = objName + ".dae"
        guard let objectScene = SCNScene(named: objectName) else {return}
        node = objectScene.rootNode
        placementNode = objectScene.rootNode
        
        
        
        node.position  = SCNVector3.init(vector.x, vector.y - 1, vector.z)
        sceneView.scene.rootNode.addChildNode(node)
        
}
    func rotateNode(withTrans : SCNVector3){
        node.eulerAngles = withTrans
    }
}
