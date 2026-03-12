# Rails gọi Python script để lấy dữ liệu chứng khoán VN (vnstock)

## 1. Bối cảnh dự án

Dự án đang xây dựng website có chart chứng khoán (TradingView hoặc chart
library khác) và cần dữ liệu thị trường Việt Nam.

Nguồn dữ liệu dự kiến sử dụng trong giai đoạn MVP là thư viện Python
**vnstock**.

Thư viện này:

-   chỉ có Python
-   không có REST API sẵn
-   thường dùng để scrape dữ liệu từ các nguồn như TCBS / VCI

Hiện tại hệ thống backend chính đang dùng **Ruby on Rails**.

Để tránh phải deploy thêm một microservice Python riêng (tăng độ phức
tạp hạ tầng), giải pháp được chọn là:

> Rails gọi trực tiếp Python script để lấy dữ liệu rồi trả JSON cho
> frontend.

Kiến trúc tổng thể:

    Frontend
       │
       ▼
    Rails API
       │
       ├─ gọi Python script
       │
       ▼
    Python + vnstock
       │
       ▼
    JSON response

------------------------------------------------------------------------

# 2. Yêu cầu môi trường

Server cần cài:

-   Python \>= 3.9
-   pip

Cài thư viện vnstock:

    pip install vnstock

Khuyến nghị tạo virtual environment:

    python3 -m venv venv
    source venv/bin/activate
    pip install vnstock

------------------------------------------------------------------------

# 3. Tạo Python script lấy dữ liệu

Tạo folder:

    scripts/

Tạo file:

    scripts/get_stock.py

Code ví dụ:

``` python
import sys
import json
from vnstock import Vnstock

symbol = sys.argv[1]

stock = Vnstock().stock(symbol=symbol, source="VCI")

# Lấy dữ liệu lịch sử
history = stock.quote.history(period='1d', start='2024-01-01')

print(history.to_json())
```

Script này:

-   nhận symbol từ command line
-   gọi vnstock
-   in JSON ra stdout

------------------------------------------------------------------------

# 4. Rails gọi Python script

Ví dụ controller:

    app/controllers/api/stocks_controller.rb

Code:

``` ruby
class Api::StocksController < ApplicationController

  def show

    symbol = params[:symbol]

    result = `python3 scripts/get_stock.py #{symbol}`

    render json: JSON.parse(result)

  end

end
```

Route:

``` ruby
get "/api/stocks/:symbol", to: "api/stocks#show"
```

API sẽ hoạt động như sau:

    GET /api/stocks/FPT

Flow:

1.  Rails nhận request
2.  Rails chạy Python script
3.  Python gọi vnstock
4.  Python trả JSON
5.  Rails trả JSON cho frontend

------------------------------------------------------------------------

# 5. Thêm cache (rất khuyến nghị)

vnstock thường scrape dữ liệu nên không nên gọi quá nhiều.

Nên cache 30-60s.

Ví dụ:

``` ruby
class Api::StocksController < ApplicationController

  def show

    symbol = params[:symbol]

    data = Rails.cache.fetch("stock_#{symbol}", expires_in: 60.seconds) do

      result = `python3 scripts/get_stock.py #{symbol}`
      JSON.parse(result)

    end

    render json: data

  end

end
```

------------------------------------------------------------------------

# 6. Format dữ liệu cho chart

Frontend chart thường cần dạng:

    [
      {
        time: 1710000000,
        open: 100,
        high: 105,
        low: 98,
        close: 103,
        volume: 100000
      }
    ]

Nếu cần có thể transform dữ liệu trong Python trước khi trả.

------------------------------------------------------------------------

# 7. Lưu ý performance

Cách này **spawn Python process mỗi request**.

Phù hợp:

-   MVP
-   traffic thấp

Không phù hợp:

-   high traffic
-   realtime data

Khi scale nên chuyển sang:

    Python microservice

------------------------------------------------------------------------

# 8. Lưu ý bảo mật

Không truyền trực tiếp input user vào shell command.

Nên sanitize symbol.

Ví dụ:

``` ruby
symbol = params[:symbol].to_s.upcase.gsub(/[^A-Z]/, "")
```

------------------------------------------------------------------------

# 9. Tóm tắt

Giải pháp này giúp:

-   không cần deploy Python service
-   tận dụng server Rails hiện tại
-   triển khai nhanh cho MVP

Trade-off:

-   performance thấp hơn microservice
-   phụ thuộc vào vnstock

Phù hợp cho giai đoạn thử nghiệm và phát triển ban đầu.
