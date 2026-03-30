class DailyStat < ApplicationRecord
  validates :stat_date, presence: true, uniqueness: true

  # page_type: "home" | "top_stocks" — UPSERT MySQL, tránh race khi nhiều request đồng thời
  def self.bump_page_view!(page_type)
    column = case page_type.to_s
             when "home" then :homepage_views
             when "top_stocks" then :top_stocks_views
             else
               raise ArgumentError, "page_type must be home or top_stocks"
             end

    bump_counter_column(column)
  end

  def self.bump_new_user!(date = Date.current)
    sql = sanitize_sql_array([
      <<~SQL.squish,
        INSERT INTO daily_stats (stat_date, homepage_views, top_stocks_views, new_users_count, created_at, updated_at)
        VALUES (?, 0, 0, 1, NOW(), NOW())
        ON DUPLICATE KEY UPDATE new_users_count = new_users_count + 1, updated_at = NOW()
      SQL
      date
    ])
    connection.execute(sql)
  end

  def self.bump_counter_column(column)
    raise ArgumentError unless %i[homepage_views top_stocks_views].include?(column)

    home_inc = column == :homepage_views ? 1 : 0
    top_inc = column == :top_stocks_views ? 1 : 0
    col_name = column.to_s

    sql = sanitize_sql_array([
      <<~SQL.squish,
        INSERT INTO daily_stats (stat_date, homepage_views, top_stocks_views, new_users_count, created_at, updated_at)
        VALUES (?, ?, ?, 0, NOW(), NOW())
        ON DUPLICATE KEY UPDATE #{col_name} = #{col_name} + 1, updated_at = NOW()
      SQL
      Date.current,
      home_inc,
      top_inc
    ])
    connection.execute(sql)
  end
  private_class_method :bump_counter_column
end
