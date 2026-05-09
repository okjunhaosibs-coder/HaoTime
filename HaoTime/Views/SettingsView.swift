import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var dataVM = DataViewModel()
    @State private var navigationPath = NavigationPath()

    let colorOptions = [
        "#B395BD", "#4ECDC4", "#FFD93D", "#FF6B6B",
        "#A78BFA", "#FB923C", "#38BDF8", "#F472B6"
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                ForEach(dataVM.categories.filter { !$0.isArchived }) { category in
                    Button {
                        navigationPath.append(category)
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 10, height: 22)

                            Image(systemName: category.iconName)
                                .font(.title3)
                                .foregroundStyle(Color(hex: category.colorHex))
                                .frame(width: 32)

                            Text(category.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "line.3.horizontal")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onMove { source, destination in
                    let active = dataVM.categories.filter { !$0.isArchived }
                    guard !source.contains(where: { active[$0].builtInName != nil }) else { return }
                    dataVM.moveCategory(from: source, to: destination, context: modelContext)
                }

            }
            .navigationTitle("管理类别")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .navigationDestination(for: Category.self) { category in
                CategoryEditView(
                    category: category,
                    dataVM: dataVM,
                    colorOptions: colorOptions
                )
            }
            .navigationDestination(for: String.self) { value in
                if value == "new" {
                    CategoryAddView(dataVM: dataVM, colorOptions: colorOptions)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            dataVM.fetchCategories(context: modelContext)
        }
    }
}

struct CategoryEditView: View {
    @Bindable var category: Category
    let dataVM: DataViewModel
    let colorOptions: [String]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let iconOptions = [
        "pencil", "brain", "checklist", "figure.run",
        "book", "music.note", "laptopcomputer", "bubble.left",
        "wrench", "leaf", "cup.and.saucer", "bed.double"
    ]

    var body: some View {
        Form {
            Section("名称") {
                TextField("类别名称", text: $category.name)
                    .disabled(category.builtInName != nil)
            }
            if category.builtInName == nil {
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4)) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                category.colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        category.colorHex == hex ?
                                        Circle().stroke(Color.white, lineWidth: 2) : nil
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            if category.builtInName == nil {
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                category.iconName = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(category.iconName == icon ? Color(hex: category.colorHex) : .secondary)
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            if category.builtInName == nil {
                Section {
                    Button(role: .destructive) {
                        dataVM.archiveCategory(category, context: modelContext)
                        dismiss()
                    } label: {
                        Text("删除类别")
                    }
                }
            }
        }
        .navigationTitle("编辑类别")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    dataVM.updateCategory(category, context: modelContext)
                    dismiss()
                }
            }
        }
    }
}

struct CategoryAddView: View {
    let dataVM: DataViewModel
    let colorOptions: [String]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var selectedColor = "#A78BFA"
    @State private var selectedIcon = "circle.fill"

    let iconOptions = [
        "pencil", "brain", "checklist", "figure.run",
        "book", "music.note", "laptopcomputer", "bubble.left",
        "wrench", "leaf", "cup.and.saucer", "bed.double"
    ]

    var body: some View {
        Form {
            Section("名称") {
                TextField("类别名称", text: $name)
            }
            Section("颜色") {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4)) {
                    ForEach(colorOptions, id: \.self) { hex in
                        Button {
                            selectedColor = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    selectedColor == hex ?
                                    Circle().stroke(Color.white, lineWidth: 2) : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Section("图标") {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("新增类别")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("添加") {
                    dataVM.addCategory(
                        name: name.isEmpty ? "新类别" : name,
                        colorHex: selectedColor,
                        iconName: selectedIcon,
                        context: modelContext
                    )
                    dismiss()
                }
            }
        }
    }
}
