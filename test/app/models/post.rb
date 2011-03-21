class Post < ActiveRecord::Base
  has_eav :through => :post_attribute do
    eav_attribute :author_name
    eav_attribute :author_email
    eav_attribute :published_on, Date
    eav_attribute :last_update, Time
  end
end
