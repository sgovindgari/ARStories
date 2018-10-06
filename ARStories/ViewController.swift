//
//  ViewController.swift
//  ARStories
//
//  Created by Antony Raphel on 05/10/17.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var usersCollectionView: UICollectionView!
    
    var userDetails: [UserDetails] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        setupCamera()
        
        // Show feature points, and statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.preferredFramesPerSecond = 60
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        let scene = SCNScene(named: "art.scnassets/glowball.scn")!
        let node = scene.rootNode.childNode(withName: "Sphere", recursively: true)!
        node.highlight()
        sceneView.scene = scene
        
        let particlesNode = SCNNode()
        let particleSystem = SCNParticleSystem(named: "Stars", inDirectory: "")
        particlesNode.addParticleSystem(particleSystem!)
        particlesNode.position = SCNVector3(0, 0, 0)
        sceneView.scene.rootNode.addChildNode(particlesNode)
        
        // Create a new scene, and bind it to the view.
        generateRandomBalls()
        
        // Do any additional setup after loading the view, typically from a nib.
        fetchUserData()
        
        usersCollectionView.isHidden = true
    }
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    private func generateRandomBalls() {
        let scene = SCNScene(named: "art.scnassets/glowball.scn")!
        let node = scene.rootNode.childNode(withName: "Sphere", recursively: true)!
        let parentNode = SCNNode()
        
        let sadnessScene = SCNScene(named: "art.scnassets/sadness.scn")!
        let sadnessNode = sadnessScene.rootNode.childNode(withName: "Sphere", recursively: true)!
        
        let angerScene = SCNScene(named: "art.scnassets/anger.scn")!
        let angerNode = angerScene.rootNode.childNode(withName: "Sphere", recursively: true)!
        
        let fearScene = SCNScene(named: "art.scnassets/fear.scn")!
        let fearNode = fearScene.rootNode.childNode(withName: "Sphere", recursively: true)!
        
        let disgustScene = SCNScene(named: "art.scnassets/disgust.scn")!
        let disgustNode = disgustScene.rootNode.childNode(withName: "Sphere", recursively: true)!
        
        let emotions = [node, node, node, sadnessNode, node, fearNode, disgustNode, angerNode, sadnessNode]
        var result: [SCNNode] = []
        
        for j in 1...8 {
            let list = makeList(j)
            for i in list {
                result.append(emotions[i])
            }
        }
        
        for i in result {
            let x = drand48() * 1 - 0.5
            let y = drand48() * 1 - 1
            let z = drand48() * 1 - 0.5
            let deepCopy = deepCopyNode(node: i)
            deepCopy.position = SCNVector3(x, y, z)
            deepCopy.highlight()
            parentNode.addChildNode(deepCopy)
        }
        
        self.sceneView.scene.rootNode.addChildNode(parentNode)
    }
    
    func makeList(_ n: Int) -> [Int] {
        return (0..<n).map{ _ in Int(arc4random_uniform(8) + 1) }
    }
    
    func deepCopyNode(node: SCNNode) -> SCNNode {
        let clone = node.clone()
        clone.geometry = node.geometry?.copy() as? SCNGeometry
        if let g = node.geometry {
            clone.geometry?.materials = g.materials.map{ $0.copy() as! SCNMaterial }
        }
        return clone
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("Hello") // <-- does not run here
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: sceneView)
        
        // Let's test if a 3D Object was touch
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
        if (hitResults.first != nil && hitResults.first?.node.name == "Sphere") {
            // play vertical video in full screen
            DispatchQueue.main.async {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ContentView") as! ContentViewController
                vc.modalPresentationStyle = .overFullScreen
                vc.pages = self.userDetails
                vc.currentIndex = 0
                self.present(vc, animated: true, completion: nil)
            }
            
            return
        }
    }
    
    // MARK: Private func
    private func fetchUserData() {
        let path = Bundle.main.path(forResource: "user-details", ofType: "json")
        let data = NSData(contentsOfFile: path ?? "") as Data?
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
            if let aUserDetails = json["userDetails"] as? [[String : Any]] {
                for element in aUserDetails {
                    userDetails += [UserDetails(userDetails: element)]
                }
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return userDetails.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! usersCollectionViewCell
        cell.imgView.imageFromServerURL(userDetails[indexPath.row].imageUrl)
        cell.lblUserName.text = userDetails[indexPath.row].name
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ContentView") as! ContentViewController
            vc.modalPresentationStyle = .overFullScreen
            vc.pages = self.userDetails
            vc.currentIndex = indexPath.row
            self.present(vc, animated: true, completion: nil)
        }
    }
}
