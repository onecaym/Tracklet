import SwiftUI

struct BrandsView: View {
    @EnvironmentObject var store: AppStore
    @State private var newBrandName = ""
    @State private var alertMessage: String?
    @State private var deleteConfirm: Brand?
    @State private var showDeleteAllConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Управление брендами")
                    .font(Theme.sectionFont)
                    .foregroundStyle(Theme.textPrimary)
                addBrandSection
                brandsListSection
                Text("При удалении бренда также удаляются все связанные с ним отчёты")
                    .font(Theme.smallFont)
                    .foregroundStyle(Theme.textPrimary)
                dangerZoneSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.spacingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Сообщение", isPresented: .init(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            if let m = alertMessage { Text(m) }
        }
        .alert("Подтверждение удаления", isPresented: .init(get: { deleteConfirm != nil }, set: { if !$0 { deleteConfirm = nil } })) {
            Button("Отмена", role: .cancel) { deleteConfirm = nil }
            Button("Удалить", role: .destructive) {
                if let b = deleteConfirm {
                    if store.db.deleteBrand(id: b.id) {
                        store.refresh()
                        alertMessage = "Бренд удалён"
                    } else {
                        alertMessage = "Не удалось удалить бренд"
                    }
                    deleteConfirm = nil
                }
            }
        } message: {
            if let b = deleteConfirm {
                let count = store.db.getBrandReportsCount(brandId: b.id)
                Text("Удалить бренд «\(b.name)»? Будет удалено отчётов: \(count).")
            }
        }
        .alert("Удалить все данные?", isPresented: $showDeleteAllConfirm) {
            Button("Отмена", role: .cancel) { showDeleteAllConfirm = false }
            Button("Удалить всё", role: .destructive) {
                if store.db.deleteAllData() {
                    store.refresh()
                    alertMessage = "Все данные удалены"
                } else {
                    alertMessage = "Не удалось удалить данные"
                }
                showDeleteAllConfirm = false
            }
        } message: {
            Text("Будут удалены все бренды, все отчёты и настройки (включая цель KPI). Это действие нельзя отменить.")
        }
    }
    
    private var addBrandSection: some View {
        GroupBox("Добавить новый бренд") {
            HStack(alignment: .center, spacing: Theme.spacingS) {
                Text("Название:")
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: Theme.formLabelWidth, alignment: .leading)
                TextField("Введите название бренда", text: $newBrandName)
                    .textFieldStyle(.plain)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Theme.spacingS)
                    .padding(.vertical, Theme.spacingXS)
                    .frame(maxWidth: .infinity)
                    .background(Theme.inputBackground)
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
                    .onSubmit { addBrand() }
                Button("Добавить бренд", action: addBrand)
                    .buttonStyle(FramedPrimaryButtonStyle())
                    .font(Theme.labelFont)
            }
            .padding(Theme.spacingS)
        }
        .groupBoxStyle(ThemeGroupBoxStyle())
    }
    
    @ViewBuilder
    private var brandsListSection: some View {
        GroupBox("Список брендов") {
            brandsListContent
        }
        .padding(Theme.spacingXS)
        .groupBoxStyle(ThemeGroupBoxStyle())
    }
    
    @ViewBuilder
    private var brandsListContent: some View {
        if store.brands.isEmpty {
            Text("Нет брендов. Добавьте первый выше.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingXL)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(store.brands.enumerated()), id: \.element.id) { index, b in
                        BrandRowView(brand: b, isAlt: index % 2 != 0) {
                            deleteConfirm = b
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
        }
    }
    
    private var dangerZoneSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Удалить все данные приложения: все бренды, отчёты и настройки (включая цель KPI). Действие необратимо.")
                    .font(Theme.smallFont)
                    .foregroundStyle(Theme.textPrimary)
                Button("Удалить все данные") { showDeleteAllConfirm = true }
                    .buttonStyle(FramedDangerButtonStyle())
                    .font(Theme.labelFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.spacingS)
        }
        .groupBoxStyle(ThemeGroupBoxStyle())
    }
    
    private func addBrand() {
        let name = newBrandName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            alertMessage = "Введите название бренда"
            return
        }
        if store.db.addBrand(name: name) != nil {
            store.refresh()
            newBrandName = ""
            alertMessage = "Бренд «\(name)» добавлен"
        } else {
            alertMessage = "Бренд с таким названием уже существует"
        }
    }
}

private struct BrandRowView: View {
    let brand: Brand
    let isAlt: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: Theme.spacingM) {
            Text(String(brand.id))
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 44, alignment: .leading)
            Text(brand.name)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Удалить", action: onDelete)
                .buttonStyle(FramedDangerButtonStyle())
                .font(Theme.labelFont)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, Theme.spacingS)
        .background(isAlt ? Theme.rowBackgroundAlt : Theme.rowBackground)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .bottom)
    }
}
