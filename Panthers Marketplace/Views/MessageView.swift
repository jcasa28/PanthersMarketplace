//
//  MessageView.swift
//  Panthers Marketplace
//
//  Created by John Borrego on 12/2/25.
//

import SwiftUI

struct MessageView: View {
    var body: some View {
        NavigationView{
            VStack{
                HStack(spacing : 16){
                    Image(systemName: "person")
                        .font(.system(size : 34, weight : .heavy))
                    
                    Text("Username")
                        .font(.system(size : 24,weight : .bold))
                    
                    Spacer()
                    
                }
                .padding(.horizontal)
            
            
            ScrollView{
                ForEach(0..<10, id : \.self){
                    num in
                    VStack{
                        HStack(spacing : 16){
                            Image(systemName : "person")
                                .font(.system(size : 32))
                                .padding()
                                .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color.black,lineWidth: 1))
                            VStack(alignment: .leading){
                                Text("UserName")
                                    .font(.system(size : 16,weight:.bold))
                                Text("Message")
                                    .font(.system(size : 14))
                                    .foregroundColor(Color(.lightGray))
                                
                            }
                            Spacer()
                            
                            Text("2h ago")
                                .font(.system(size : 14, weight: .semibold))
                        }
                        Divider()
                            .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                }
            }
        }
        }
    }
}

#Preview {
    MessageView()
}
