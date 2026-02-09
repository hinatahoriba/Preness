# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

[
  "TOEFL ITP 模試 Vol.1",
  "TOEFL ITP 模試 Vol.2"
].each do |title|
  exam = Exam.find_or_initialize_by(title: title)
  exam.price = 1200
  exam.stripe_price_id = nil
  exam.save!
end
