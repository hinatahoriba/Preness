class ExamsController < ApplicationController
  before_action :authenticate_user!

  def index
    @exams = Exam.order(created_at: :desc)
    @user_exams_by_exam_id = current_user.user_exams.where(exam_id: @exams.select(:id)).index_by(&:exam_id)
  end
end
