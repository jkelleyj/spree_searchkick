Spree::Property.class_eval do
  scope :filterable, -> { where(filterable: true) }

  def filter_name
    "#{name.downcase.gsub(/\s+/, '')}"
  end
end
