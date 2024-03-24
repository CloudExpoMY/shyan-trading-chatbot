# seed 50 fake redemption vouchers

# description_options = [
#   '100 pts - RM10 TnG Reload',
#   '200 pts - RM20 TnG Reload',
#   '500 pts - RM50 TnG Reload',
#   '100 pts - RM10 Grab Voucher'
# ]

# 50.times do
#   RedemptionVoucher.create(
#     description: description_options.sample,
#     code: "#{SecureRandom.hex(1).upcase}-#{SecureRandom.hex(3).upcase}-#{SecureRandom.hex(1).upcase}"
#   )
# end

# seed 10 fake users

10.times do
  User.create(
    email: Faker::Internet.email,
    full_name: Faker::Name.name,
    phone_number: Faker::PhoneNumber.cell_phone
  )
end

AdminUser.create(email: 'admin@cloudexpo.my', password: 'cloudexpoadmin',
                 password_confirmation: 'cloudexpoadmin')
