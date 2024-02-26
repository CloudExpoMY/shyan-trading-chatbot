# app/decorators/active_storage_attachment_decorator.rb
module ActiveStorageAttachmentDecorator
  extend ActiveSupport::Concern

  included do
    def self.ransackable_attributes(_auth_object = nil)
      %w[blob_id created_at id id_value name record_id record_type]
    end
  end
end

ActiveStorage::Attachment.include ActiveStorageAttachmentDecorator
