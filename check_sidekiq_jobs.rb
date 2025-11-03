# Script để kiểm tra các background jobs trong Sidekiq
# Chạy trong Rails console: rails c
# Sau đó load file này: load 'check_sidekiq_jobs.rb'

puts "🔍 Kiểm tra trạng thái Sidekiq Jobs..."

require 'sidekiq/api'

# 1. Thống kê tổng quan
stats = Sidekiq::Stats.new
puts "\n📊 THỐNG KÊ TỔNG QUAN:"
puts "- Jobs đã xử lý: #{stats.processed}"
puts "- Jobs thất bại: #{stats.failed}" 
puts "- Jobs đang chờ: #{stats.enqueued}"
puts "- Jobs đang xử lý: #{stats.workers_size}"
puts "- Số retry: #{stats.retry_size}"
puts "- Jobs đã chết: #{stats.dead_size}"

# 2. Lịch sử jobs (processed + failed trong 24h qua)
history = Sidekiq::Stats::History.new
puts "\n📈 LỊCH SỬ 24H QUA:"
puts "- Processed: #{history.processed}"
puts "- Failed: #{history.failed}"

# 3. Kiểm tra các queue
puts "\n📋 DANH SÁCH QUEUES:"
Sidekiq::Queue.all.each do |queue|
  puts "- Queue '#{queue.name}': #{queue.size} jobs"
end

# 4. Jobs đang chờ xử lý
puts "\n⏳ JOBS ĐANG CHỜ XỬ LÝ:"
Sidekiq::Queue.all.each do |queue|
  if queue.size > 0
    puts "\nQueue: #{queue.name}"
    queue.each_with_index do |job, index|
      break if index >= 5 # Chỉ hiện 5 jobs đầu tiên
      puts "  #{index + 1}. #{job.klass} - #{job.args.inspect}"
      puts "     Created: #{Time.at(job.created_at)}"
    end
  end
end

# 5. Jobs đang được xử lý
puts "\n🔄 JOBS ĐANG XỬ LÝ:"
workers = Sidekiq::Workers.new
if workers.size > 0
  workers.each do |process_id, thread_id, work|
    puts "- #{work['payload']['class']} (#{work['queue']})"
    puts "  Started: #{Time.at(work['run_at'])}"
  end
else
  puts "Không có jobs nào đang được xử lý"
end

# 6. Jobs đã thất bại (retry)
puts "\n❌ JOBS THẤT BẠI (RETRY):"
retry_set = Sidekiq::RetrySet.new
if retry_set.size > 0
  retry_set.each_with_index do |job, index|
    break if index >= 10 # Chỉ hiện 10 jobs đầu tiên
    puts "#{index + 1}. #{job.klass} - Retry #{job.retry_count}/#{job['retry']}"
    puts "   Error: #{job.error_message}"
    puts "   Next retry: #{job.at}"
    puts "   Args: #{job.args.inspect}"
    puts "   ---"
  end
else
  puts "Không có jobs nào đang retry"
end

# 7. Jobs đã chết (không retry nữa)
puts "\n💀 JOBS ĐÃ CHẾT:"
dead_set = Sidekiq::DeadSet.new
if dead_set.size > 0
  dead_set.each_with_index do |job, index|
    break if index >= 5 # Chỉ hiện 5 jobs đầu tiên
    puts "#{index + 1}. #{job.klass}"
    puts "   Error: #{job.error_message}"
    puts "   Failed at: #{job.failed_at}"
    puts "   Args: #{job.args.inspect}"
    puts "   ---"
  end
else
  puts "Không có jobs chết"
end

# 8. Jobs được lên lịch
puts "\n⏰ JOBS ĐƯỢC LÊN LỊCH:"
scheduled_set = Sidekiq::ScheduledSet.new
if scheduled_set.size > 0
  scheduled_set.each_with_index do |job, index|
    break if index >= 5 # Chỉ hiện 5 jobs đầu tiên
    puts "#{index + 1}. #{job.klass} - #{job.at}"
    puts "   Args: #{job.args.inspect}"
  end
else
  puts "Không có jobs được lên lịch"
end

# 9. Kiểm tra cụ thể SendNotificationJob
puts "\n📱 KIỂM TRA SENDNOTIFICATIONJOB:"
all_queues = Sidekiq::Queue.all
notification_jobs_pending = 0
all_queues.each do |queue|
  queue.each do |job|
    notification_jobs_pending += 1 if job.klass == 'SendNotificationJob'
  end
end

notification_jobs_retry = 0
Sidekiq::RetrySet.new.each do |job|
  notification_jobs_retry += 1 if job.klass == 'SendNotificationJob'
end

notification_jobs_dead = 0
Sidekiq::DeadSet.new.each do |job|
  notification_jobs_dead += 1 if job.klass == 'SendNotificationJob'
end

puts "- Pending: #{notification_jobs_pending}"
puts "- Retrying: #{notification_jobs_retry}" 
puts "- Dead: #{notification_jobs_dead}"

puts "\n✅ Hoàn thành kiểm tra!"
puts "\n💡 TIP: Để xem chi tiết hơn, truy cập Sidekiq Web UI tại: http://localhost:3000/sidekiq"
