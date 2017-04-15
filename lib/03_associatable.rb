require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @model_class ||= class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = {
      class_name: name.to_s.singularize.camelcase,
      primary_key: :id,
      foreign_key: "#{name.to_s.singularize.downcase}_id".to_sym
    }
    options = default.merge(options)

    options.each do |key, value|
      send("#{key}=", value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default = {
      class_name: name.to_s.singularize.camelcase,
      primary_key: :id,
      foreign_key: "#{self_class_name.to_s.singularize.downcase}_id".to_sym
    }
    options = default.merge(options)

    options.each do |key, value|
      send("#{key}=", value)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # store BelongsToOptions object to class variable
    # e.g. Cat.assoc_options[:owner] is a BTO object
    self.assoc_options[name] = BelongsToOptions(name, options)

    # define association method for instance
    # e.g. cat1.owner
    define_method(name) do
      # access BelongsToOptions object from class
      # e.g. cat1 can access Cat.assoc_options[:owner]
      options = self.class.assoc_options[name]

      # get value of foreign_key of instance
      # e.g. options.foreign_key is owner_id => cat1.owner_id
      f_key_value = self.send(options.foreign_key)

      # get result from the association
      # e.g.
      # options.model_class => Human
      # options.primary_key => id
      # f_key_value => cat1.owner_id == 10
      # .where() => Human.where(id => 10)
      options
        .model_class
        .where(options.primary_key => f_key_value)
        .first
    end
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
end
