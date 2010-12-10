require 'helper'

class TestHasEav < Test::Unit::TestCase
  should "be able to create new records" do
    before = Post.count
    Post.create( :title => "Hello world", :contents => "Lipsum" )
    assert_equal before + 1, Post.count, "count has incremented by 1"
  end
  
  should "be able to write to an eav attribute" do
    p = Post.last
    assert_equal p.author_name = "hartog", "hartog", "eav attribute set"
  end
  
  should "propperly respond_to? eav_attributes" do
    p = Post.new
    assert p.respond_to?(:author_name), "responds to author name"
    assert !p.respond_to?(:author_gender), "does not respond to gender"
  end
  
  should "propperly implement changed?" do
    p = Post.last
    assert !p.changed?, "is not changed"
    
    p = Post.last
    p.author_name = rand 100
    
    assert p.changed?, "is changed only by eav attribute"
    
    p = Post.last
    p.title = "Bye World"
    assert p.changed?, "is changed on real attribute"
  end
  
  should "save PostAttribute's" do
    before = PostAttribute.count
    p = Post.create( :title => "Hello World", :contents => "Lipsum" )
    p.author_name = "hartog"
    p.save!
    
    assert_equal before + 1, PostAttribute.count, "count has incremented by 1"
  end
    
  should "save ProductAttribute's on Product.create" do
    before = ProductAttribute.count
    p = Product.create(
      :name        => "test",
      :description => "spiffy. new.",
      :price       => 12.95
    )    
    
    assert_equal before + 1, ProductAttribute.count, "count has incremented by 1"
  end

  should "cast values" do
    p = Product.create( :name => "test", :description => "test" )
    p.price = 12.95
    p.save!
    
    p = Product.last    
    assert p.price.is_a?(Float), "casted"
    assert p.price == 12.95, "same"
  end
  
  should "cast values with new" do
    test_val ="13.24458724857"
    p = Product.create(
      :name => "test", :description => "test", :cost_price => test_val
    )
    
    p = Product.last    
    assert p.cost_price.is_a?(BigDecimal), "casted"
    assert p.cost_price == BigDecimal.new(test_val), "same"
  end
  
  should "not find by eav attribute" do
    p = Post.create(
      :title => "title", :contents => "lorem ipsum", :author_name => "hartog"
    )
    
    post = nil
    begin
      post = Post.find_by_author_name "hartog"
    rescue
      post = "failed"
    end
    
    assert_equal "failed", post, "has failed"
  end
  
  should "work with STI" do
    p = SpecialPost.create(
      :title => "title", :contents => "lorem ipsum", :author_name => "hartog"
    )
  end
end
