module ApplicationHelper
  def bootstrap_flash_class(level)
    case level.to_sym
    when :notice, :success
      "alert alert-success"
    when :alert, :error
      "alert alert-danger"
    when :warning
      "alert alert-warning"
    when :info
      "alert alert-info"
    else
      "alert alert-secondary"
    end
  end
end
