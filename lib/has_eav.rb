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
        # # specifiy eav_attributes at instance level
        # has_eav :through => :some_class_with_name_and_value_attributes
        # def available_eav_attributes
        #   case self.origin
        #   when "remote"
        #     %(remote_ip user_agent)
        #   when "local"
        #     %(user)
        #   end + [ :uniq_id ]
        # end
        #
        # # specify some eav_attributes at class level
        # has_eav :through => "BoundAttribute" do
        #   eav_attribute :remote_ip
        #   eav_attribute :uniq_id
        # end
        #
        # == Mixing class and instance defined EAV attributes
        # You can define EAV attributes both in class and instance context and
        # they will be both adhered
        #
        def has_eav opts={}, &block
          klass = opts.delete :through
          klass = klass.to_s if klass.is_a? Symbol
          klass = klass.camelize

          raise(
            "Eav Class cannot be nil. Specify a class using " +
            "has_eav :through => :class"
          ) if klass.blank?

          class_eval do
            has_many   :eav_attributes, :class_name => klass
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

          self.class_eav_attributes[name] = type
        end

        # class accessor - when the superclass != AR::Base asume we are in STI
        # mode
        def class_eav_attributes # :nodoc:
          superclass != ActiveRecord::Base ?
            superclass.class_eav_attributes :
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
          super
        rescue NoMethodError => e
          method_name    = method_symbol.to_s
          attribute_name = method_name.gsub(/[\?=]$/, '')

          raise e unless eav_attributes_list.include? attribute_name

          attribute = self.eav_attributes.select { |a|
            a.name == attribute_name
          }.first

          if method_name =~ /\=$/
            value = args[0]

            if attribute
              if !value.nil?
                return attribute.send(:write_attribute, "value", value)

              else
                self.eav_attributes -= [ attribute ]
                return attribute.destroy

              end

            elsif !value.nil?
              self.eav_attributes << eav_class.new(
                :name  => attribute_name,
                :value => "#{value}"
              )

              return cast_eav_value(value, attribute_name)

            else
              return nil

            end
          elsif method_name =~ /\?$/
            return ( attribute and attribute.value == true ) ? true : false

          else
            return nil if attribute and attribute.destroyed?
            return attribute ?
              cast_eav_value(attribute.value, attribute_name) :
              nil
          end

          raise e
        end

        # override respond_to?
        def respond_to? method_symbol, is_private=false
          if super == false
            method_name = method_symbol.to_s.gsub(/[\?=]$/, '')
            return true if eav_attributes_list.include? method_name

            false
          else
            true
          end
        end

        # save the list of eav_attribute back to the database
        def save_eav_attributes # :nodoc:
          eav_attributes.select { |a| a.changed? }.each do |a|
            if a.new_record?
              a.send( :write_attribute, self_key, self.id )
            end

            a.save!
          end
        end

        # override changed - if any of the eav_attributes has changed, the
        # object has changed.
        #
        def changed?
          eav_attributes.each do |attribute|
            return true if ( attribute.changed? || attribute.new_record? )
          end

          super
        end

        # get a complete list of eav_attributes (class + instance)
        def eav_attributes_list # :nodoc:
          (
            self.instance_eav_attributes + self.class_eav_attributes.keys
          ).collect { |attribute| attribute.to_s }.uniq
        end

        # get the key to my <3
        def self_key # :nodoc:
          klass = self.class
          if klass.superclass != ActiveRecord::Base
            klass = klass.superclass
          end

          "#{klass.name.underscore}_id".to_sym
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

        # cast an eav value to it's desired class
        def cast_eav_value value, attribute # :nodoc:
          attributes = self.class_eav_attributes.stringify_keys
          return value unless attributes.keys.include?(attribute)
          return value if attributes[attribute] == String # no need for casting


          begin
            # for core types [eg: Integer '12']
            eval("#{attributes[attribute]} '#{value}'")

          rescue
            begin
              # for BigDecimal [eg: BigDecimal.new("123.45")]
              eval("#{attributes[attribute]}.new('#{value}')")

            rescue
              begin
                # for date/time classes [eg: Date.parse("2011-03-20")]
                eval("#{attributes[attribute]}.parse('#{value}')")
              rescue
                # nothing worked, falling back to whatever the ORM supplied
                value
              end

            end
          end
        end

        protected :save_eav_attributes, :self_key, :cast_eav_value

      end # /InstanceMethods
    end # /HasEav
  end # /ActsAs
end # /ActiveRecord

# insert the has_eav method into ActiveRecord
ActiveRecord::Base.send( :include, ActiveRecord::ActsAs::HasEav )
