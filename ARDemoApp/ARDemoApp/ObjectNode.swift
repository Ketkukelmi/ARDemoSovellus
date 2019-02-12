//
//  MeasureNode.swift
//  ARDemoApp
//
//  Created by CubiCasa Office on 19/01/2019.
//  Copyright © 2019 CubiCasa Office. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class ObjectNode {
    var node = SCNNode()
    var placementNode = SCNNode()
    var sceneView = ARSCNView()
    var startVector = SCNVector3()
    var scale = [Float]()
    
    init(scene: ARSCNView, vector: SCNVector3, objName: String){
        self.sceneView = scene
        self.startVector = vector
        
        let objectName = objName + ".dae"
        guard let objectScene = SCNScene(named: objectName) else {return}
        node = objectScene.rootNode
        placementNode = objectScene.rootNode
        

        
        node.position  = SCNVector3.init(vector.x, vector.y - 1, vector.z)
        sceneView.scene.rootNode.addChildNode(node)
        
    }
    
    func update(to vector: SCNVector3) {

        //sceneView.scene.rootNode.addChildNode(node)
        node.position = vector
        //node.position = SCNVector3.init(vector.x + 2, vector.y - 1, vector.z + 1)

        node.position  = SCNVector3.init(vector.x, vector.y - 1, vector.z)
        /*if node.parent == nil {
            sceneView.scene.rootNode.addChildNode(node)
        }*/
    }
    func place(vector: SCNVector3){
        placementNode.position = vector
        if placementNode.parent == nil {
            sceneView.scene.rootNode.addChildNode(placementNode)
            
        }
    }
    func rotateNode(withTrans : SCNVector3){
        node.eulerAngles = withTrans
    }
    
    func distance(to vector: SCNVector3) -> String {
        return String(format: "%.2f%@", startVector.distance(from: vector), "meters")
    }
    
    func removeFromParentNode() {
        node.removeFromParentNode()
    }
}
