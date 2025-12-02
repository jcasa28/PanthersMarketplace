//
//  EditProfileView.swift
//  Panthers Marketplace
//
//  Created by John Borrego on 11/24/25.
//
import SwiftUI
import PhotosUI

@MainActor
final class PhotoPickerViewModel: ObservableObject {
    @Published private(set) var selectedImage: UIImage? = nil
    @Published var imageSelection : PhotosPickerItem? = nil{
        didSet{
            setImage(from : imageSelection)
            
            
        }
    }
    
    
    
    private func setImage(from selection : PhotosPickerItem?){
        guard let selection else {return}
        
        Task{
            if let data = try? await selection.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    return
                }
            }
        }
    }
}

struct EditProfileView : View{
    
    @EnvironmentObject var profileVM: ProfileViewModel

    @StateObject private var viewModel = PhotoPickerViewModel()
    
    
    
    
    var body : some View{
        
        
        NavigationStack{
            VStack{
                
            HStack(){
                Text("Profile Picture")
                    .fontWeight(.bold)
                
                    
                Spacer()
                Button {
                    
                } label: {
                    PhotosPicker(selection: $viewModel.imageSelection, matching : .images) {
                        Text("Add")
                    }
                    
                }
                
                
            }
            .padding(.horizontal)
            .font(.system(size: 20))
                
                
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .padding(.bottom)
                    

                } else if let existing = profileVM.profileImage {
                    Image(uiImage: existing)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .padding(.bottom)

                } else {
                   
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                        
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                            .padding(30)
                    }
                    .frame(width: 140, height: 140)
                    .padding(.bottom)
                }

                                
                                Button("Save Changes") {
                                    if let img = viewModel.selectedImage {
                                        profileVM.updateProfileImage(img)  
                                    }
                                }
                
                    
                    
                
        }
            Divider()
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        
    }
    
}



#Preview{
    EditProfileView()
        .environmentObject(ProfileViewModel())
}
