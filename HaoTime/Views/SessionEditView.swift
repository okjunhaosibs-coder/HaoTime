import SwiftUI
import SwiftData

struct SessionEditView: View {
    let context: ModelContext
    let editingSession: Session?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: Category?
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @Query(sort: \Category.sortOrder) private var allCategories: [Category]

    init(context: ModelContext, editingSession: Session? = nil) {
        self.context = context
        self.editingSession = editingSession
    }

    var categories: [Category] {
        allCategories.filter { !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("类别") {
                    Picker("类别", selection: $selectedCategory) {
                        Text("请选择").tag(nil as Category?)
                        ForEach(categories) { cat in
                            HStack {
                                Circle()
                                    .fill(Color(hex: cat.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(cat.name)
                            }
                            .tag(cat as Category?)
                        }
                    }
                }

                Section("时间") {
                    DatePicker("开始", selection: $startTime)
                    DatePicker("结束", selection: $endTime)
                }
            }
            .navigationTitle(editingSession != nil ? "编辑记录" : "手动添加记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                    .disabled(selectedCategory == nil)
                }
            }
            .onAppear {
                if let session = editingSession {
                    selectedCategory = session.category
                    startTime = session.startTime
                    endTime = session.endTime ?? Date()
                }
            }
        }
    }

    private func save() {
        guard let category = selectedCategory else { return }
        if let existing = editingSession {
            existing.category = category
            existing.startTime = startTime
            existing.endTime = endTime
        } else {
            let session = Session(
                category: category,
                startTime: startTime,
                endTime: endTime
            )
            context.insert(session)
        }
        try? context.save()
    }
}
