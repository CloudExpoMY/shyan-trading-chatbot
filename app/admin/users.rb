ActiveAdmin.register User do
  menu priority: 2

  includes :conversation

  permit_params :email, :full_name, :phone_number

  index do
    selectable_column
    id_column
    column :phone_number
    column :email
    column :full_name
    column 'Current Chat Flow' do |user|
      user.current_step || '-'
    end
    actions
  end
end
