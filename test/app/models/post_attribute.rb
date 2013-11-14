class PostAttribute < ActiveRecord::Base
  belongs_to :post

  serialize :value
end
