# class for testing attribute casting
#
class Product < ActiveRecord::Base
  has_eav :through => :product_attribute do
    eav_attribute :price
    eav_attribute :cost_price
  end
end
