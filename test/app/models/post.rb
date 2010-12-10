class Post < ActiveRecord::Base
  has_eav :through => :post_attribute do
    eav_attribute :author_name
    eav_attribute :author_email    
  end
end
