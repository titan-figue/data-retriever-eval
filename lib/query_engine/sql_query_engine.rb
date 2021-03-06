require "query_engine/default_query_engine"

class SQLQueryEngine < DefaultQueryEngine
  def decorate(query, filters = {}, query_params = {})
    query.gsub!("#_client_#", @client)
    apply_filters(query, filters)
    apply_params(query, query_params)
    query
  end

  def explain(query, info)
    { plan: execute(query.prepend("EXPLAIN "), info) }
  end

  private

  def apply_filters(query, filters = {})
    filters ||= {}
    patterns = query.scan(/#_(?<pat>(where|and|limit|offset)_\w+)_#/i).flatten.uniq
    patterns.each do |pattern|
      pattern_filter = []
      pattern_string = ""

      if filters[pattern] && !filters[pattern].empty?
        filters[pattern].each do |f|
          val = f[:value_type].casecmp("string").zero? ? "'#{f[:value]}'" : f[:value]
          case pattern
          when /limit/
            pattern_filter << "limit #{val}" if f[:value]
          when /offset/
            pattern_filter << "offset #{val}" if f[:value]
          else
            pattern_filter << "(#{f[:field]} #{f[:operator]} #{val})" if f[:value]
          end
        end
        if (pattern =~ /where/) || (pattern =~ /and/)
          pattern_string += pattern =~ /where/ ? "WHERE " : "AND "
          pattern_string += pattern_filter.join(" AND ")
        else
          pattern_string += pattern_filter.join(" ")
        end
      end
      query.gsub!("#_#{pattern}_#", pattern_string)
    end
    query
  end

  def apply_params(query, query_params = {})
    query_params ||= {}
    query_params.each do |pattern, value|
      query.gsub!("#_#{pattern}_#", value)
    end
    query
  end
end
