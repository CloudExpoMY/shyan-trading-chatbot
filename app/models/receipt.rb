# == Schema Information
#
# Table name: receipts
#
#  id         :bigint           not null, primary key
#  location   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_receipts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Receipt < ApplicationRecord
  has_one_attached :image
end
