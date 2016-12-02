require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = (params.map { |k, _| "#{k} = ?" }).join(" AND ")

    self.parse_all(DBConnection.execute(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL
    )
  end
end

class SQLObject
  extend Searchable
end
