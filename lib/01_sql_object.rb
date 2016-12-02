require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns

    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    @columns = cols.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method "#{col}" do
        self.attributes[col]
      end

      define_method "#{col}=" do |c|
        self.attributes[col] = c
      end
    end
  end

  def self.table_name=(table_name = SQLObject.table_name)
    @table_name = table_name
  end

  def self.table_name
    (self.name.split /(?=[A-Z])/).map(&:downcase).join('_') + 's'
  end

  def self.all
    self.parse_all(DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    )
  end

  def self.parse_all(results)
    results.map { |el| self.new(el) }
  end

  def self.find(id)
    self.parse_all(DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL
    ).first
  end

  def initialize(params = {})
    params.each do |k, v|
      raise "unknown attribute \'#{k}\'" unless
        self.class.columns.include?(k.to_sym)

      self.send("#{k}=".to_sym, v)
    end
  end

  def attributes
    return @attributes if @attributes
    @attributes = {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    cols = self.class.columns[1..-1]
    col_names = cols.join(',')
    question_marks = (["?"] * cols.length).join(', ')

    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    @attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns[1..-1]
    to_set = (cols.map { |el| "#{el} = ?" }).join(', ')

    DBConnection.execute(<<-SQL, attribute_values.rotate)
      UPDATE
        #{self.class.table_name}
      SET
        #{to_set}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
