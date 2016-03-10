module PuppetX
module CatalogTranslation
  class Type
    attr_reader :name

    @instances = {}

    def initialize(name,&block)
      @name = name
      @translations = {}
      instance_eval(&block)
      self.class.register self
    end

    def translate!(resource)
      result = {}
      # temporarily set @resource to the parameter
      # for use by the blocks
      @resource = resource

      @translations.each do |attr,translation|
        title = translation[:alias] || attr

        result[title] = if translation[:spawned]
          translation[:block].call
        elsif translation.has_key? :block
          translation[:block].call(resource[attr])
        else
          resource[attr]
        end
      end
      @resource = nil
      result
    end

    def output
      @output || @name
    end

    def self.translation_for(type)
      @instances[type] || @instances[:default]
    end

    private

    def self.register(instance)
      @instances[instance.name] = instance
    end

    # below are DSL methods

    def carry(*attributes,&block)
      attributes.each do |attribute|
        @translations[attribute] = { :title => attribute, }
        if block_given?
          @translations[attribute][:block] = block
        end
      end
    end

    def rename(attribute,newname,&block)
      if block_given?
        carry(attribute) { |x| block.call(x) }
      else
        carry attribute
      end
      @translations[attribute][:alias] = newname
    end

    def spawn(*attributes,&block)
      attributes.each do |attribute|
        carry(attribute) { yield }
        @translations[attribute][:spawned] = true
      end
    end

    def emit(output)
      raise "emit has been called twice for #{name}" if @output
      @output = output
    end

  end
end
end
