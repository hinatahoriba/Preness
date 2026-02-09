# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Exam.find_or_create_by!(title: "TOEFL ITP 模試 Vol.1") do |exam|
  exam.price = 3980
  exam.stripe_price_id = ENV["STRIPE_EXAM_VOL1_PRICE_ID"]
end

Exam.find_or_create_by!(title: "TOEFL ITP 模試 Vol.2") do |exam|
  exam.price = 3980
  exam.stripe_price_id = ENV["STRIPE_EXAM_VOL2_PRICE_ID"]
end
