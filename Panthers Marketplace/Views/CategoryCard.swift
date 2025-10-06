//
//  CategoryCard.swift
//  Panthers Marketplace
//
//  Created by John Borrego on 10/22/25.
//

import SwiftUI

struct CategoryCard : View{
    var label : String;
    
    var icon : String;
    
    var red : Double;
    var green : Double;
    var blue : Double;
    
    
    
    var body : some View{
        
        Button {
            
        } label: {
            ZStack{
                Color(red: red/255, green: green/255, blue: blue/255)
                VStack{
                    Text(icon)
                        .padding()
                        .font(Font.system(size: 30))
                    
                   
                        
                        Text("\(label)")
                            .foregroundStyle(.black)
                            
                      
                    
                    
                   
                        
                }
               
                
                
                
            }
            .frame(height : 100)
            .cornerRadius(12)
            
            
            
        }
        

        
        
    }
    
    
}

#Preview {
    
}
