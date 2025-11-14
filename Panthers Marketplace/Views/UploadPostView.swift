
//
//  UploadPostView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//
import SwiftUI
import PhotosUI

struct UploadPostView: View {
    @State var listingVM: ListingsViewModel = ListingsViewModel()
    @State private var listingsVM = ListingsViewModel()
    
    var onNavigateToMyListings: (() -> Void)? = nil

    @State private var title: String = ""
    @State private var priceText: String = ""
    @State private var category: String = ""
    @State private var condition: String = ""
    @State private var descriptionText: String = ""
    @State private var location: String = ""

    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    @State private var isPosting: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var formErrors: [FieldError] = []

    private let minPhotos = 1
    private let maxPhotos = 6
    private let categories = ["Electronics", "Furniture", "Clothing", "Books", "Sports", "Other"]
    private let conditions = ["New", "Like New", "Good", "Fair", "For Parts"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photosSection

                    inputSection(title: "Title") {
                        TextField("Add a descriptive title", text: $title)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                    }
                    .errorText(error(for: .title))

                    inputSection(title: "Price") {
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                    }
                    .errorText(error(for: .price))

                    inputSection(title: "Category") {
                        Menu {
                            ForEach(categories, id: \.self) { cat in
                                Button(cat) { category = cat }
                            }
                        } label: {
                            HStack {
                                Text(category.isEmpty ? "Select a category" : category)
                                    .foregroundStyle(category.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .errorText(error(for: .category))

                    inputSection(title: "Condition") {
                        Menu {
                            ForEach(conditions, id: \.self) { cond in
                                Button(cond) { condition = cond }
                            }
                        } label: {
                            HStack {
                                Text(condition.isEmpty ? "Select condition" : condition)
                                    .foregroundStyle(condition.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .errorText(error(for: .condition))

                    inputSection(title: "Description", minHeight: 120) {
                        ZStack(alignment: .topLeading) {
                            if descriptionText.isEmpty {
                                Text("Describe your item, include details and any flaws")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            TextEditor(text: $descriptionText)
                                .frame(minHeight: 120)
                        }
                    }
                    .errorText(error(for: .description))

                    inputSection(title: "Location") {
                        TextField("City, State", text: $location)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                    }
                    .errorText(error(for: .location))

                    guidelinesFooter
                        .padding(.top, 8)
                }
                .padding(16)
            }
            .navigationTitle("Post an Item")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: post) {
                        if isPosting {
                            ProgressView()
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isPosting)
                }
            }
            .alert("Listing posted!", isPresented: $showSuccessAlert) {
                Button("Go to My Listings") {
                    onNavigateToMyListings?()
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your item has been posted successfully.")
            }
            .onChange(of: selectedPickerItems) { _, newItems in
                Task { await loadPickedImages(from: newItems) }
            }
        }
    }
}

private extension UploadPostView {
    var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photos")
                .font(.headline)
            
            let cellHeight: CGFloat = 110
            let gridSpacing: CGFloat = 10
            let corner: CGFloat = 12

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 3),
                spacing: gridSpacing
            ) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: corner)
                            .fill(Color(.systemGray6))
                            .frame(height: cellHeight)

//                        Image(uiImage: image)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(height: cellHeight)

                        Button {
                            withAnimation {
                                if !selectedImages.isEmpty {
                                    selectedImages.remove(atOffsets: IndexSet(integer: index))
                                }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, .black.opacity(0.6))
                                .padding(6)
                        }
                    }
                    .mask(RoundedRectangle(cornerRadius: corner))
                }

                if selectedImages.count < maxPhotos {
                    PhotosPicker(selection: $selectedPickerItems,
                                 maxSelectionCount: maxPhotos - selectedImages.count,
                                 matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: cellHeight)
                            VStack(spacing: 6) {
                                Image(systemName: "camera")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Text("Add Photos")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            if let error = error(for: .photos) {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    func inputSection<Content: View>(title: String, minHeight: CGFloat = 48, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            VStack {
                content()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    var guidelinesFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            // add guidelines
        }
    }
}

private extension UploadPostView {
    enum FieldErrorKey: Hashable { case photos, title, price, category, condition, description, location }
    struct FieldError: Identifiable, Hashable { let id = UUID(); let key: FieldErrorKey; let message: String }

    var isFormValid: Bool {
        validate().isEmpty && !isPosting
    }

    func validate() -> [FieldError] {
        var errors: [FieldError] = []

        if selectedImages.count < minPhotos {
            errors.append(FieldError(key: .photos, message: "Add at least \(minPhotos) photo."))
        }
        if selectedImages.count > maxPhotos {
            errors.append(FieldError(key: .photos, message: "You can add up to \(maxPhotos) photos."))
        }

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(FieldError(key: .title, message: "Title is required."))
        }

        if decimalPrice == nil || (decimalPrice ?? 0) <= 0 {
            errors.append(FieldError(key: .price, message: "Enter a valid price greater than 0."))
        }

        if category.isEmpty { errors.append(FieldError(key: .category, message: "Select a category.")) }
        if condition.isEmpty { errors.append(FieldError(key: .condition, message: "Select a condition.")) }

        if descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(FieldError(key: .description, message: "Description is required."))
        }

        if location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(FieldError(key: .location, message: "Location is required."))
        }

        return errors
    }

    func error(for key: FieldErrorKey) -> String? {
        formErrors.first(where: { $0.key == key })?.message
    }

    var decimalPrice: Decimal? {
        let sanitized = priceText.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: sanitized)
    }
}

private extension UploadPostView {
    func post() {
        formErrors = validate()
        guard formErrors.isEmpty else { return }

        let draft = ListingsViewModel.ListingDraft(
            photos: selectedImages,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            price: decimalPrice ?? 0,
            category: category,
            condition: condition,
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        isPosting = true
        Task { @MainActor in
            do {
                try await listingsVM.createListing(draft)
                resetForm()
                showSuccessAlert = true
            } catch {
                formErrors = [FieldError(key: .title, message: "Failed to post. Please try again.")]
            }
            isPosting = false
        }
    }

    func resetForm() {
        title = ""
        priceText = ""
        category = ""
        condition = ""
        descriptionText = ""
        location = ""
        selectedPickerItems = []
        selectedImages = []
        formErrors = []
    }

    func loadPickedImages(from items: [PhotosPickerItem]) async {
        var newImages: [UIImage] = selectedImages
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                newImages.append(image)
                if newImages.count >= maxPhotos { break }
            }
        }
        await MainActor.run {
            selectedImages = Array(newImages.prefix(maxPhotos))
            selectedPickerItems = []
            formErrors = validate()
        }
    }
}

private extension View {
    func errorText(_ message: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            self
            if let message = message, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    UploadPostView()
}


