class Api::Admin::DashboardStatsController < Api::Admin::BaseController
  def show
    today = Date.current
    range_start = today - 6.days

    total_users = User.count
    # Tính theo "7 ngày lịch" giống hệt chart: từ 00:00 của (today - 6 days) đến hết hôm nay
    start_time = Time.zone.local(range_start.year, range_start.month, range_start.day)
    end_time = Time.zone.local((today + 1).year, (today + 1).month, (today + 1).day)
    new_users_this_week = User.where("created_at >= ? AND created_at < ?", start_time, end_time).count

    stats_by_date = DailyStat.where(stat_date: range_start..today).index_by(&:stat_date)
    chart_data = (range_start..today).map do |d|
      {
        date: d.iso8601,
        views: stats_by_date[d]&.homepage_views.to_i
      }
    end

    today_stat = stats_by_date[today]
    home_today = today_stat&.homepage_views.to_i
    top_today = today_stat&.top_stocks_views.to_i
    conversion = home_today.zero? ? 0.0 : (top_today.to_f / home_today * 100).round(2)

    render json: {
      total_users: total_users,
      new_users_this_week: new_users_this_week,
      chart_data: chart_data,
      top_stocks_performance: {
        views: top_today,
        conversion_rate: conversion
      }
    }
  end
end
