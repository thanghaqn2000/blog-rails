import math
import traceback
from datetime import datetime, timedelta

from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse
from vnstock import Quote
from vnstock.explorer.misc import btmc_goldprice, vcb_exchange_rate

app = FastAPI()


def _safe_float(val):
    if val is None:
        return None
    try:
        f = float(val)
        return None if math.isnan(f) or math.isinf(f) else f
    except (ValueError, TypeError):
        return None


def _parse_gold_prices(df):
    if df is None or df.empty:
        return []

    seen = {}
    for _, row in df.iterrows():
        name = str(row.get("name", ""))
        if "bạc" in name.lower():
            continue
        buy = _safe_float(row.get("buy_price"))
        sell = _safe_float(row.get("sell_price"))
        world = _safe_float(row.get("world_price"))
        time_str = str(row.get("time", ""))
        if name not in seen or time_str > seen[name]["time"]:
            seen[name] = {
                "name": name,
                "buy_price": buy,
                "sell_price": sell,
                "world_price": world,
                "time": time_str,
            }
    return list(seen.values())


def _parse_exchange_rates(df):
    if df is None or df.empty:
        return []

    records = []
    for _, row in df.iterrows():
        record = {}
        for col in df.columns:
            val = row[col]
            if val is None or (hasattr(val, "__class__") and val.__class__.__name__ == "NaTType"):
                record[col] = None
            elif isinstance(val, float):
                record[col] = val
            else:
                record[col] = str(val)
        records.append(record)
    return records


@app.get("/api/stocks/{symbol}/history")
def stock_history(
    symbol: str,
    start: str = Query(None, alias="from"),
    end: str = Query(None, alias="to"),
    resolution: str = "1D",
):
    end_date = end or datetime.now().strftime("%Y-%m-%d")
    start_date = start or (datetime.now() - timedelta(days=365)).strftime("%Y-%m-%d")

    resolution_map = {
        "1": "1m",
        "5": "5m",
        "15": "15m",
        "30": "30m",
        "60": "1H",
        "1D": "1D",
        "1W": "1W",
        "1M": "1M",
    }
    interval = resolution_map.get(resolution, "1D")

    quote = Quote(symbol=symbol.upper(), source="vci")
    df = quote.history(start=start_date, end=end_date, interval=interval)

    if df is None or df.empty:
        return []

    records = []
    for _, row in df.iterrows():
        time_val = row.get("time") or row.get("date") or row.get("tradingDate")
        if hasattr(time_val, "timestamp"):
            unix_ts = int(time_val.timestamp())
        else:
            unix_ts = int(datetime.strptime(str(time_val)[:10], "%Y-%m-%d").timestamp())

        volume = _safe_float(row.get("volume"))
        records.append({
            "time": unix_ts,
            "open": _safe_float(row.get("open")),
            "high": _safe_float(row.get("high")),
            "low": _safe_float(row.get("low")),
            "close": _safe_float(row.get("close")),
            "volume": int(volume) if volume is not None else None,
        })

    records.sort(key=lambda x: x["time"])
    return records


@app.get("/api/gold_prices/btmc")
def gold_price_btmc():
    try:
        df = btmc_goldprice()
    except (SystemExit, Exception) as e:
        return JSONResponse(
            status_code=500,
            content={"error": f"Failed to fetch gold prices from BTMC: {e}"},
        )
    return _parse_gold_prices(df)


@app.get("/api/exchange_rates/vcb")
def exchange_rate_vcb(date: str = Query(None)):
    query_date = date or datetime.now().strftime("%Y-%m-%d")

    try:
        df = vcb_exchange_rate(date=query_date)
    except (SystemExit, Exception) as e:
        return JSONResponse(
            status_code=500,
            content={"error": f"Failed to fetch exchange rates from VCB: {e}"},
        )
    return _parse_exchange_rates(df)


@app.get("/api/market_data")
def market_data():
    """Single endpoint for scheduler: fetch gold prices + exchange rates in one call."""
    result = {"gold_prices": [], "exchange_rates": [], "errors": []}

    try:
        gold_df = btmc_goldprice()
        result["gold_prices"] = _parse_gold_prices(gold_df)
    except SystemExit as e:
        result["errors"].append(f"Gold prices: Rate limit exceeded - {e}")
    except Exception as e:
        result["errors"].append(f"Gold prices: {e}")

    try:
        exchange_df = vcb_exchange_rate(date=datetime.now().strftime("%Y-%m-%d"))
        result["exchange_rates"] = _parse_exchange_rates(exchange_df)
    except SystemExit as e:
        result["errors"].append(f"Exchange rates: Rate limit exceeded - {e}")
    except Exception as e:
        result["errors"].append(f"Exchange rates: {e}")

    result["fetched_at"] = datetime.now().isoformat()
    return result
