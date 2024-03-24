# == Schema Information
#
# Table name: redemption_vouchers
#
#  id          :bigint           not null, primary key
#  code        :string
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint
#
# Indexes
#
#  index_redemption_vouchers_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class RedemptionVoucher < ApplicationRecord
  belongs_to :user
end
