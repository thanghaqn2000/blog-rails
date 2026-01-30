# Chatbot Feature - Tài liệu hướng dẫn

## 📋 Tổng quan

Feature chatbot sử dụng OpenAI Assistant API với Rails backend. Hệ thống quản lý:
- ✅ Authentication (JWT)
- ✅ Quota management (giới hạn số message/ngày)
- ✅ Conversations & Messages
- ✅ Background job reset quota hàng ngày

## 🏗 Kiến trúc

```
React → Rails (auth + quota + AI + DB) → OpenAI Assistant
```

## 📊 Database Schema

### Tables
- `conversations`: Lưu thông tin cuộc hội thoại
- `messages`: Lưu tin nhắn (user + assistant)
- `user_quotas`: Quản lý hạn mức sử dụng

### Relationships
- User `has_many` Conversations
- Conversation `has_many` Messages
- User `has_one` UserQuota

## 🔧 Cài đặt

### 1. Environment Variables

Thêm vào `.env`:
```env
CHATBOT_API_KEY=sk-your-openai-api-key
OPENAI_ASSISTANT_ID=asst_your_assistant_id
```

### 2. Database Migration

```bash
bin/rails db:migrate
```

### 3. Khởi động Sidekiq

```bash
bundle exec sidekiq
```

## 📡 API Endpoints

### Conversations

#### GET /api/v1/conversations
Lấy danh sách conversations
```bash
curl -H "JWTAuthorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/v1/conversations
```

#### POST /api/v1/conversations
Tạo conversation mới
```bash
curl -X POST \
     -H "JWTAuthorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"conversation":{"title":"My Conversation"}}' \
     http://localhost:3000/api/v1/conversations
```

#### GET /api/v1/conversations/:id
Xem chi tiết conversation (bao gồm messages)
```bash
curl -H "JWTAuthorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/v1/conversations/1
```

#### PATCH /api/v1/conversations/:id
Cập nhật conversation (ví dụ: đổi title)
```bash
curl -X PATCH \
     -H "JWTAuthorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"conversation":{"title":"New Title"}}' \
     http://localhost:3000/api/v1/conversations/1
```

#### PATCH /api/v1/conversations/:id/archive
Archive conversation
```bash
curl -X PATCH \
     -H "JWTAuthorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/v1/conversations/1/archive
```

### Messages

#### GET /api/v1/conversations/:conversation_id/messages
Lấy danh sách messages trong conversation
```bash
curl -H "JWTAuthorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/v1/conversations/1/messages
```

#### POST /api/v1/conversations/:conversation_id/messages
Gửi message mới (gọi OpenAI Assistant)
```bash
curl -X POST \
     -H "JWTAuthorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"message":{"content":"Hello, how are you?"}}' \
     http://localhost:3000/api/v1/conversations/1/messages
```

**Response khi thành công:**
```json
{
  "user_message": {
    "id": "uuid",
    "role": "user",
    "content": "Hello, how are you?",
    "status": "success",
    "created_at": "2026-01-30T05:00:00Z"
  },
  "assistant_message": {
    "id": "uuid",
    "role": "assistant",
    "content": "I'm doing well, thank you!",
    "status": "success",
    "token_usage": 150,
    "created_at": "2026-01-30T05:00:01Z"
  }
}
```

**Response khi quota hết:**
```json
{
  "error": "Quota exceeded",
  "message": "Bạn đã sử dụng hết quota. Vui lòng liên hệ admin để được cấp thêm quota.",
  "quota": {
    "total_limit": 5,
    "used": 5,
    "remaining": 0
  }
}
```

### Quota

#### GET /api/v1/quota
Kiểm tra quota hiện tại
```bash
curl -H "JWTAuthorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/v1/quota
```

**Response:**
```json
{
  "total_limit": 5,
  "used": 3,
  "remaining": 2
}
```

## 🔄 Quota Management

### Quy tắc
- Mỗi user có tổng cộng **5 lần** sử dụng chatbot (mặc định)
- Chỉ tính quota khi OpenAI API trả về thành công
- Nếu OpenAI fail → message được lưu với `status = 'failed'` nhưng KHÔNG tính quota
- **KHÔNG tự động reset** - User hết quota phải đợi admin cấp thêm

### Admin tasks

**Xem thống kê quota:**
```bash
bin/rails chatbot:quota_stats
```

**Cấp quota mới cho user (reset usage + đổi limit):**
```bash
# Cấp 10 lần sử dụng cho user #1
bin/rails chatbot:grant_quota[1,10]
```

**Reset usage cho user (giữ nguyên limit):**
```bash
# Reset về 0 cho user #1
bin/rails chatbot:reset_user_usage[1]
```

## 🧪 Testing

### Test OpenAI connection
```bash
bin/rails chatbot:test_openai
```

### Test trong Rails console
```ruby
# Tạo user quota
user = User.first
quota = user.user_quota || user.create_user_quota(daily_limit: 5)

# Check quota
quota.available? # => true/false
quota.remaining  # => số lượng còn lại

# Admin cấp quota mới
quota.grant_quota!(10)  # Reset usage + set limit = 10

# Admin reset usage
quota.reset_usage!  # Reset về 0, giữ nguyên limit

# Tạo conversation
conversation = user.conversations.create!(
  title: "Test Conversation",
  openai_thread_id: "thread_xxx",
  status: 'active'
)

# Test OpenAI service
service = OpenaiAssistantService.new
thread_id = service.create_thread
response = service.send_message(
  thread_id: thread_id,
  content: "Hello!"
)
```

## 🚨 Error Handling

### Message Status
- `success`: Message thành công
- `failed`: OpenAI API fail hoặc lỗi khác
- `pending`: Đang chờ xử lý (temporary)

### Errors
- `429 Too Many Requests`: Quota exceeded
- `404 Not Found`: Conversation not found
- `503 Service Unavailable`: OpenAI API error
- `500 Internal Server Error`: Lỗi server

## 📝 Models

### Conversation
```ruby
# Scopes
Conversation.active        # conversations với status = 'active'
Conversation.recent        # sắp xếp theo last_message_at

# Methods
conversation.archive!              # archive conversation
conversation.delete_conversation!  # soft delete
conversation.generate_title_from_first_message  # tự động tạo title
```

### Message
```ruby
# Scopes
Message.successful       # messages thành công
Message.failed_messages  # messages failed
Message.oldest_first     # sắp xếp cũ → mới

# Methods
message.user_message?     # check role = 'user'
message.assistant_message? # check role = 'assistant'
message.failed?           # check status = 'failed'
```

### UserQuota
```ruby
# Methods
quota.available?          # còn quota không?
quota.remaining          # số lượng còn lại
quota.increment_usage!   # tăng usage
quota.grant_quota!(limit) # admin cấp quota mới (reset + đổi limit)
quota.reset_usage!       # admin reset usage (giữ nguyên limit)
```

## 🔐 Security Notes

- Tất cả endpoints yêu cầu JWT authentication
- Mỗi user chỉ access được conversations của mình
- OpenAI API key được lưu trong ENV (không commit vào git)

## 📦 Dependencies

- `ruby-openai`: OpenAI API client
- `sidekiq`: Background jobs
- `redis`: Sidekiq backend

## 🎯 Next Steps (Optional)

1. **Streaming response**: Implement streaming để hiển thị response realtime
2. **File upload**: Cho phép user upload file vào conversation
3. **Export conversation**: Export conversation sang PDF/JSON
4. **Analytics**: Thống kê usage, popular questions, etc.
5. **Rate limiting**: Thêm rate limit per minute/hour

## 📞 Support

Nếu có vấn đề, check:
1. OpenAI API key có đúng không?
2. Assistant ID có đúng không?
3. Sidekiq có đang chạy không?
4. Redis có đang chạy không?
5. Check logs: `tail -f log/development.log`
