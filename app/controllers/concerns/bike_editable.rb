module BikeEditable
  extend ActiveSupport::Concern

  included do
    helper_method :edit_bike_template_path_for
  end

  def edit_templates
    return @edit_templates if @edit_templates.present?
    @theft_templates = @bike.status_stolen? ? theft_templates : {}
    @bike_templates = bike_templates
    @edit_templates = @theft_templates.merge(@bike_templates)
  end

  def edit_bike_template_path_for(bike, template = nil)
    if edits_controller_name_for(template) == "edits"
      edit_bike_url(bike.id, edit_template: template)
    elsif template.to_s == "alert"
      new_bike_theft_alert_path(bike_id: bike.id)
    else
      bike_theft_alert_path(bike_id: bike.id)
    end
  end

  protected

  # NB: Hash insertion order here determines how nav links are displayed in the
  # UI. Keys also correspond to template names and query parameters, and values
  # are used as haml header tag text in the corresponding templates.
  def theft_templates
    {}.with_indifferent_access.tap do |h|
      h[:theft_details] = translation(:theft_details, scope: [:controllers, :bikes, :edit])
      h[:publicize] = translation(:publicize, scope: [:controllers, :bikes, :edit])
      h[:alert] = translation(:alert, scope: [:controllers, :bikes, :edit])
      h[:report_recovered] = translation(:report_recovered, scope: [:controllers, :bikes, :edit])
    end
  end

  # NB: Hash insertion order here determines how nav links are displayed in the
  # UI. Keys also correspond to template names and query parameters, and values
  # are used as haml header tag text in the corresponding templates.
  def bike_templates
    {}.with_indifferent_access.tap do |h|
      h[:bike_details] = translation(:bike_details, scope: [:controllers, :bikes, :edit])
      h[:found_details] = translation(:found_details, scope: [:controllers, :bikes, :edit]) if @bike.status_found?
      h[:photos] = translation(:photos, scope: [:controllers, :bikes, :edit])
      h[:drivetrain] = translation(:drivetrain, scope: [:controllers, :bikes, :edit])
      h[:accessories] = translation(:accessories, scope: [:controllers, :bikes, :edit])
      h[:ownership] = translation(:ownership, scope: [:controllers, :bikes, :edit])
      h[:groups] = translation(:groups, scope: [:controllers, :bikes, :edit])
      h[:remove] = translation(:remove, scope: [:controllers, :bikes, :edit])
      unless @bike.status_stolen_or_impounded?
        h[:report_stolen] = translation(:report_stolen, scope: [:controllers, :bikes, :edit])
      end
    end
  end

  def setup_edit_template(requested_page = nil)
    @edit_templates = edit_templates
    @permitted_return_to = permitted_return_to

    # If provided an invalid template name, redirect to the default page for a stolen /
    # unstolen bike
    @edit_template = requested_page || @bike.default_edit_template
    valid_requested_page = (edit_templates.keys.map(&:to_s) + ["alert_purchase_confirmation"]).include?(@edit_template)
    unless valid_requested_page && controller_name == edits_controller_name_for(@edit_template)
      redirect_template = valid_requested_page ? @edit_template : @bike.default_edit_template
      redirect_to(edit_bike_template_path_for(@bike, redirect_template))
      return false
    end

    @skip_general_alert = %w[photos theft_details report_recovered remove alert alert_purchase_confirmation].include?(@edit_template)
    true
  end

  def edits_controller_name_for(requested_page)
    %w[alert alert_purchase_confirmation].include?(requested_page.to_s) ? "theft_alerts" : "edits"
  end
end
