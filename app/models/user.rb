# == Schema Information
#
# Table name: users
#
#  id           :bigint           not null, primary key
#  email        :string
#  full_name    :string
#  phone_number :string
#  points       :integer          default(0)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class User < ApplicationRecord
  has_one :conversation, dependent: :destroy

  validates :phone_number, presence: true, uniqueness: true

  delegate :current_step, to: :conversation, allow_nil: true
end
