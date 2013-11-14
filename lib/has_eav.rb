module ActiveRecord
  module ActsAs
    module HasEav
      def self.included(base)
        base.extend ActiveRecord::ActsAs::HasEav::ClassMethods
      end

      module ClassMethods
        # Specify that the ActiveModel is an EAV model
        #
        # == Usage
        #   # specifiy eav_attributes at instance level
        #   has_eav :through => :some_class_with_name_and_value_attributes
        #   def available_eav_attributes
        #     case self.origin
        #     when "remote"
        #       %(remote_ip user_agent)
        #     when "local"
        #       %(user)
        #     end + [ :uniq_id ]
        #   end
        #
        #   # specify some eav_attributes at class level
        #   has_eav :through => "BoundAttribute" do
        #     eav_attribute :remote_ip
        #     eav_attribute :uniq_id
        #   end
        #
        #   # specify more attributes in an STI class
        #   class ItalianJob < Job
        #     has_eav do
        #       eav_attribute :mini_driver
        #     end
        #   end
        #
        # == Mixing class and instance defined EAV attributes
        # You can define EAV attributes both in class and instance context and
        # they will be both adhered
        #
        def has_eav opts={}, &block
          if self.superclass != ActiveRecord::Base && (opts.nil? || opts.empty?)
            @eav_attributes = {}
            yield
            return
          end

          klass = opts.delete :through
          klass = klass.to_s if klass.is_a? Symbol
          klass = klass.camelize

          raise(
            "Eav Class cannot be nil. Specify a class using " +
            "has_eav :through => :class"
          ) if klass.blank?

          opts[:class_name] = klass
          opts[:dependent] ||= :destroy

          class_eval do
            has_many   :eav_attributes, opts
            after_save :save_eav_attributes
          end

          @eav_class      = klass.constantize
          @eav_attributes = {}

          yield if block_given?

          send :include, ActiveRecord::ActsAs::HasEav::InstanceMethods
        end

        # Add an other attribute to the class list
        def eav_attribute name, type = String
          name = name.to_s if !name.is_a? String

          @eav_attributes[name] = type
        end

        # class accessor - when the superclass != AR::Base asume we are in STI
        # mode
        def class_eav_attributes # :nodoc:
          superclass != ActiveRecord::Base ?
            superclass.class_eav_attributes.merge(@eav_attributes || {}) :
            @eav_attributes
        end

        # class accessor - when the superclass != AR::Base asume we are in STI
        # mode
        def eav_class # :nodoc:
          superclass != ActiveRecord::Base ? superclass.eav_class : @eav_class
        end
      end # /ClassMethods

      module InstanceMethods
        # get to the eav class
        def eav_class
          self.class.eav_class
        end

        # get the class eav attributes
        def class_eav_attributes
          self.class.class_eav_attributes
        end

        # Override this to get some usable attributes
        #
        # Cowardly refusing to adhere to all
        def instance_eav_attributes
          []
        end

        # override method missing, but only kick in when super fails with a
        # NoMethodError
        #
        def method_missing method_symbol, *args, &block
          super unless respond_to? method_symbol

          method_name    = method_symbol.to_s
          attribute_name = method_name.gsub(/[\?=]$/, '')

          if method_name =~ /\=$/
            self.class.class_eval do
              define_method method_name do |value|
                if attribute = self.eav_attributes.find_by(name: attribute_name)
                  if !value.nil?
                    attribute.value = value
                  else
                    self.eav_attibutes.destroy attribute
                  end
                elsif !value.nil?
                  self.eav_attributes.build name: attribute_name, value: value
                end
                value
              end
            end
          elsif method_name =~ /\?$/
            self.class.class_eval do
              define_method method_name do
                self.eav_attributes.where(name: attribute_name).any?
              end
            end
          else
            self.class.class_eval do
              define_method method_name do
                self.eav_attributes.find_by(name: attribute_name).value if send(:"#{method_name}?")
              end
            end
          end
          self.send method_name, *args, &block
        end

        # override respond_to?
        def respond_to? method_symbol, is_private=false
          super || begin
            method_name = method_symbol.to_s.gsub(/[\?=]$/, '')
            eav_attributes_list.include? method_name
          end
        end

        # save the list of eav_attribute back to the database
        def save_eav_attributes # :nodoc:
          eav_attributes.select { |a| a.changed? }.each do |a|
            a.save!
          end
        end

        # override changed - if any of the eav_attributes has changed, the
        # object has changed.
        #
        def changed?
          super || eav_attributes.any? { |attribute| attribute.changed? || attribute.new_record? }
        end

        # get a complete list of eav_attributes (class + instance)
        def eav_attributes_list # :nodoc:
          (
            self.instance_eav_attributes + self.class_eav_attributes.keys
          ).collect { |attribute| attribute.to_s }.uniq
        end

        # make sure EAV is included in as_json, to_json and to_xml
        #
        def serializable_hash options=nil
          hash = super
          eav_attributes_list.each do |attribute|
            hash[attribute] = self.send(attribute)
          end

          hash
        end

        protected :save_eav_attributes
      end # /InstanceMethods
    end # /HasEav
  end # /ActsAs
end # /ActiveRecord

# insert the has_eav method into ActiveRecord
ActiveRecord::Base.send( :include, ActiveRecord::ActsAs::HasEav )
