ActiveAdmin.register RedemptionVoucher do
  menu priority: 5

  includes :user

  index do
    selectable_column
    id_column
    column :description
    column :code
    column 'Redeeemed By' do |v|
      v.user
    end
    actions
  end
end
