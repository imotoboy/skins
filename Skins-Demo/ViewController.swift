//
//  ViewController.swift
//  Skins-Demo
//
//  Created by tramp on 2021/4/23.
//

import UIKit
import Skins

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.skin.backgroundColor = .global(.major)
        
        
        let button = UIButton.init(type: .custom)
        button.setTitle("fasdfasdfasdf", for: .normal)
        button.frame = .init(x: 0.0, y: 0.0, width: 100, height: 100)
        button.addTarget(self, action: #selector(actionHandle), for: .touchUpInside)
        button.backgroundColor = .red
        view.addSubview(button)
        button.center = view.center
        
        Skins.shared.log()
    }
    
    /// actionHandle
    /// - Parameter sender: UIButton
    @objc private func actionHandle(_ sender: UIButton) {
        
        switch Skins.shared.interfaceStyle {
        case .dark:
            try? Skins.shared.change(style: .light)
        case .light:
            try? Skins.shared.change(style: .cool)
        case .cool:
            try? Skins.shared.change(style: .dark)
        default:
            try? Skins.shared.change(style: .dark)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
   
        guard presentingViewController == nil else { return }
        let controller = ViewController.init()
        present(controller, animated: true, completion: nil)
    }
    
    deinit {
        print(#function)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            Skins.shared.log()
        }
    }
}

