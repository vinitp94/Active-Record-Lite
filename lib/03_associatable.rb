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
    @class_name.constantize
  end

  def table_name
    # (@class_name.split /(?=[A-Z])/).map(&:downcase).join('_') + 's'
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = (name + '_id').to_sym
    @class_name = name.capitalize
    @primary_key = :id

    @foreign_key = options[:foreign_key] if options.include?(:foreign_key)
    @class_name = options[:class_name] if options.include?(:class_name)
    @primary_key = options[:primary_key] if options.include?(:primary_key)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = (self_class_name.downcase + '_id').to_sym
    @class_name = name.singularize.camelcase
    @primary_key = :id

    @foreign_key = options[:foreign_key] if options.include?(:foreign_key)
    @class_name = options[:class_name] if options.include?(:class_name)
    @primary_key = options[:primary_key] if options.include?(:primary_key)
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name.to_s, options)
    define_method "#{name}" do
      foreign_key_value = self.send(options.foreign_key)
      options.model_class.where(id: foreign_key_value).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name.to_s, self.to_s, options)
    define_method "#{name}" do
      foreign_key_value = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => foreign_key_value)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
