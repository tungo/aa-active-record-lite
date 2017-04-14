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
      LIMIT
        1
    SQL

    @columns = cols.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |col|
      define_method(col) do
        attributes[col]
      end

      define_method("#{col}=") do |value|
        attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    results.empty? ? nil : self.new(results.first)
  end

  def initialize(params = {})
    params.each do |key, value|
      key = key.to_sym
      raise "unknown attribute '#{key}'" unless columns.include?(key)

      send("#{key}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    columns.map { |col| send(col) }
  end

  def insert
    cols_name = columns.join(', ')
    question_marks = (["?"] * columns.size).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{table_name}(#{cols_name})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set = columns.map { |col| "#{col} = ?" }.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{table_name}
      SET
        #{set}
      WHERE
        id = ?
    SQL
  end

  def save
    # ...
  end

  private

  def columns
    self.class.columns
  end

  def table_name
    self.class.table_name
  end
end
