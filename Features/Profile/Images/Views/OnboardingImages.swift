//
//  OnboardingImages.swift
//  Scoop
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI


struct OnboardingImages: View {
    
    //Injected
    @Environment(AppDependencies.self) private var dep
    @Environment(\.dismiss) private var dismiss
    let vm: OnboardingViewModel

    //Local view state
    @State private var imageVM: ProfileImagesViewModel
    @State private var images: [UIImage?] = Array(repeating: nil, count: 6) //Keyed by tile, not by where it sits: a drag never moves these
    @State private var order: [Int] = Array(0..<6) //The tiles in screen order: what a drag rearranges, and the order Complete uploads in
    @State private var selectedImage: ImageSlot? = nil
    @State private var showSavingScreen: Bool = false
    @State private var showPicker: Bool = false
    @State private var pickStart: Int = 0 //The screen position of the empty cell that opened the picker; picks fill onward from it
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var loadingTiles: Set<Int> = [] //Tiles a pick has claimed while it loads — a drag carries the claim along, and no later pick can take them
    private let columns = Array(repeating: GridItem(.fixed(120), spacing: 10), count: 3) //Geometry: photo-grid pitch (cell + gap)

    init(vm: OnboardingViewModel, defaultsManager: DefaultsManaging, storageService: StorageServicing) {
        self.vm = vm
        _imageVM = State(wrappedValue: ProfileImagesViewModel(defaults: defaultsManager, storageService: storageService))
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            
            SignUpTitle(text: "Add 6 Photos")
                .padding(.horizontal, Spacing.sm)
            
            Text("Ensure you're in all")
                .font(.body())
                .foregroundStyle(Color.textTertiary)
            
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(Array(order.enumerated()), id: \.element) { position, tile in
                    OnboardingPhotoCell(selectedImage: $selectedImage, index: tile, image: images[tile],
                                        isLoading: loadingTiles.contains(tile)) {
                        pickStart = position
                        showPicker = true
                    }
                    .reorderableCell(tile, canLift: images[tile] != nil) //Only a photo lifts; empty and loading tiles make room
                }
            }
            //Hold a photo to lift it; the others make room, and the first cell is the main photo
            .reorderableGrid(order) { from, to in
                order.reorder(from: from, to: to)
            } preview: { tile, _ in
                if let image = images[tile] { ImageCell(image: image, size: 120) }
            }
            ActionButton(text: "Complete", isValid: images.allSatisfy({$0 != nil})) {
                showSavingScreen = true
                Task {
                    do {
                         try await imageVM.saveAll(images: order.compactMap { images[$0] }) //Screen order is upload order: the first cell is the main photo
                         try await vm.createProfile()
                         dep.session.appState = .app
                    } catch {
                        showSavingScreen = false // TODO: surface the failure via InAppNotificationCenter
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, Spacing.clearance)
        .padding(.horizontal, Spacing.margin)
        .background(Color.appCanvas)
        //.ordered numbers each pick in the picker, and that number is the order the photos land in
        .photosPicker(isPresented: $showPicker, selection: $pickerItems,
                      maxSelectionCount: max(1, openTiles(from: pickStart).count),
                      selectionBehavior: .ordered, matching: .images)
        .onChange(of: pickerItems) { _, items in receive(items) }
        .fullScreenCover(item: $selectedImage) {localImage in
            ProfileImageEditor(importedImage: localImage) { updatedImage in
                images[updatedImage.index] = updatedImage.image
            }
        }
        .animation(.transition, value: showSavingScreen)
        .overlay {
            if showSavingScreen {
                ZStack {
                    OnboardingLoadingScreen()
                }
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
                .background(Color.appCanvas) //A tap can't dismiss it: Complete would run twice
            }
        }
        .toolbar(showSavingScreen ? .hidden : .visible, for: .navigationBar)
    }
}

//Picking photos
extension OnboardingImages {

    //Open tiles in fill order: the tapped cell, then onward on screen, wrapping round — never a chosen or claimed one
    private func openTiles(from start: Int) -> [Int] {
        order.indices.map { order[(start + $0) % order.count] }
            .filter { images[$0] == nil && !loadingTiles.contains($0) }
    }

    //Each pick claims its cell the moment the picker closes, so a second pick mid-load can't collide with it
    private func receive(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        let tiles = Array(openTiles(from: pickStart).prefix(items.count))
        loadingTiles.formUnion(tiles)
        pickerItems = [] //Consumed, so the picker always reopens empty
        Task { await load(items, into: tiles) }
    }

    //Every pick loads at once, decoded off the main thread, and lands in its cell the moment it's ready
    private func load(_ items: [PhotosPickerItem], into tiles: [Int]) async {
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (tile, item) in zip(tiles, items) {
                group.addTask {
                    //Optional read: a failed pick just leaves its cell empty
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return (tile, nil) }
                    return (tile, await image.byPreparingForDisplay() ?? image)
                }
            }
            for await (tile, image) in group {
                if let image { images[tile] = image }
                loadingTiles.remove(tile)
            }
        }
    }
}
