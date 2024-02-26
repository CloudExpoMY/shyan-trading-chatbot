# config/initializers/ransack.rb
Ransack.configure do |config|
  config.add_predicate 'whatsapp_search',
                       arel_predicate: 'in',
                       formatter: proc { |v|
                                    Product
                                      .search(v)
                                      .map(&:id)
                                  },
                       validator: proc { |v| v.present? },
                       type: :string

  def ransackable_associations(auth_object = nil)
    Rails.logger.info('WITHIN RANSACK ASSOCIATION')
    super + %w[impressionable]
  end
end
