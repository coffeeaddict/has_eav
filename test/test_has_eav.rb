require 'helper'

class TestHasEav < Test::Unit::TestCase
  #
  # A model under EAV ...
  #
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

  should "save PostAttribute's on Post.create" do
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

  should "be able to handle Date casting" do
    p = Post.last
    p.published_on = Date.yesterday

    assert_equal Date.yesterday, p.published_on, "Date comparisson"
  end

  should "be able to handle Time casting" do
    t = Time.now

    p = Post.last
    p.last_update = t

    assert_equal t.to_i, p.last_update.to_i, "Time comparisson"
  end

  should "not create attributes with nil value" do
    p = Post.create
    p.author_name = nil

    assert_equal [], p.eav_attributes, "No attributes where defined"

    p.author_name = "name"

    assert_equal 1, p.eav_attributes.count, "There is 1 eav attribute"

    p.author_name = nil
    assert_equal nil, p.author_name, "The value is nilified"
    assert_equal [], p.eav_attributes, "There are no more attributes"
  end

  should "include EAV attributes in to_json, as_json and to_xml" do
    p = Post.last
    p.author_name = "The Author"
    p.author_email = nil

    hash = p.as_json

    assert hash["post"].has_key?("author_name"), "The key is present"
    assert_equal "The Author", hash["post"]["author_name"], "Value is correct"

    assert hash["post"].has_key?("author_email"), "The nil key is present"
    assert_equal nil, hash["post"]["author_email"], "Value is nil"
  end
end
