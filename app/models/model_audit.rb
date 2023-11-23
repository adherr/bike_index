class ModelAudit < ApplicationRecord
  UNKNOWN_STRINGS = %w[na idk no unknown unkown none tbd no\ model].freeze

  enum certification_status: ModelAttestation::CERTIFICATION_KIND_ENUM
  enum propulsion_type: PropulsionType::SLUGS
  enum cycle_type: CycleType::SLUGS

  belongs_to :manufacturer

  has_many :bikes
  has_many :model_attestations
  has_many :organization_model_audits, dependent: :destroy

  validates_uniqueness_of :frame_model, scope: %i[manufacturer_id manufacturer_other], allow_nil: false, case_sensitive: false

  before_validation :set_calculated_attributes

  def self.valid_kinds
    (certification_statuses.keys - ["certification_proof_url"])
  end

  def self.manufacturer_id_corrected(manufacturer_id, mnfg_name)
    return manufacturer_id if manufacturer_id != Manufacturer.other.id
    Manufacturer.friendly_find_id(mnfg_name) || manufacturer_id
  end

  def self.matching_manufacturer(manufacturer_id, mnfg_name)
    model_audits = where("mnfg_name ILIKE ?", mnfg_name)
    manufacturer_id = manufacturer_id_corrected(manufacturer_id, mnfg_name)
    return model_audits if manufacturer_id == Manufacturer.other.id
    model_audits.or(where(manufacturer_id: manufacturer_id))
  end

  def self.matching_frame_model(frame_model)
    if unknown_model?(frame_model)
      where(frame_model: nil)
    else
      where("frame_model ILIKE ?", frame_model)
    end
  end

  def self.find_for(bike = nil, manufacturer_id: nil, mnfg_name: nil, frame_model: nil)
    manufacturer_id ||= bike&.manufacturer_id
    mnfg_name ||= bike&.mnfg_name
    frame_model ||= bike&.frame_model
    matching_audits = matching_manufacturer(manufacturer_id, mnfg_name)
      .matching_frame_model(frame_model).reorder(:id)
    return matching_audits.first if matching_audits.count < 2
    not_other = matching_audits.where.not(manufacturer_id: Manufacturer.other.id)
    not_other.present? ? not_other.first : matching_audits.first
  end

  def self.unknown_model?(frame_model)
    return true if frame_model.blank?
    UNKNOWN_STRINGS.include?(frame_model.downcase)
  end

  def self.audit?(bike)
    return true if bike.motorized? || bike.manufacturer&.motorized_only?
    if bike.manufacturer&.other?
      manufacturer_id = manufacturer_id_corrected(bike.manufacturer_id, bike.mnfg_name)
      if manufacturer_id != Manufacturer.other.id
        return true if Manufacturer.find_by_id(manufacturer_id)&.motorized_only?
      end
    end
    return false if unknown_model?(bike.frame_model)
    # Also enqueue if any matching bikes have a model_audit
    ModelAudit.matching_bikes_for(bike).where.not(model_audit_id: nil).limit(1).any?
  end

  def self.matching_bikes_for_frame_model(bikes, frame_model: nil)
    if unknown_model?(frame_model)
      bikes.where(frame_model: nil).or(bikes.where("frame_model ILIKE ANY (array[?])", UNKNOWN_STRINGS))
    else
      bikes.where("frame_model ILIKE ?", frame_model)
    end
  end

  def self.matching_bikes_for(bike = nil, manufacturer_id: nil, mnfg_name: nil, frame_model: nil)
    manufacturer_id ||= bike&.manufacturer_id
    mnfg_name ||= bike&.mnfg_name || Manufacturer.find_by_id(manufacturer_id)&.simple_name
    # Always match by mnfg_name, to fix things if it previously was manufacturer_other
    bikes = Bike.unscoped.where("mnfg_name ILIKE ?", mnfg_name)
    if manufacturer_id != Manufacturer.other.id
      bikes = bikes.or(Bike.unscoped.where(manufacturer_id: manufacturer_id))
    end

    matching_bikes_for_frame_model(bikes, frame_model: frame_model || bike&.frame_model)
      .reorder(id: :desc)
  end

  def self.counted_matching_bikes_count(bikes)
    # As of now, user_hidden isn't normally visible in orgs. Not sure what to do about that?
    bikes.where(example: false, deleted_at: nil, likely_spam: false).count
  end

  # WARNING! This is a calculated query. You should probably use the association
  def matching_bikes
    self.class.matching_bikes_for(nil, manufacturer_id: manufacturer_id, mnfg_name: mnfg_name, frame_model: frame_model)
  end

  # WARNING! This is a calculated query.
  def counted_matching_bikes_count
    self.class.counted_matching_bikes_count(matching_bikes)
  end

  def matching_bike?(bike)
    same_frame_model = if self.class.unknown_model?(bike.frame_model)
      unknown_model?
    else
      frame_model&.downcase == bike.frame_model&.downcase
    end
    return false unless same_frame_model
    mnfg_name.downcase == bike.mnfg_name.downcase
  end

  def delete_if_no_bikes?
    model_attestations.limit(1).blank?
  end

  def unknown_model?
    frame_model.blank?
  end

  def certification_status_humanized
    ModelAttestation.kind_humanized(certification_status)
  end

  def cycle_type_name
    CycleType.new(cycle_type)&.name
  end

  def propulsion_type_name
    PropulsionType.new(propulsion_type).name
  end

  def set_calculated_attributes
    self.manufacturer_other = nil if manufacturer_id != Manufacturer.other.id
    self.mnfg_name = Manufacturer.calculated_mnfg_name(manufacturer, manufacturer_other)
    self.certification_status = calculated_certification_status
  end

  private

  def calculated_certification_status
    (self.class.valid_kinds & model_attestations.current.distinct.pluck(:kind)).first
  end
end
