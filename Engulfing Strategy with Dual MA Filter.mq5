#include <Trade\Trade.mqh>

// Inputs
input double lotSize = 1.0; // Lot Size
input double profitRiskRatio = 0.5; // Profit to Risk Ratio
input int fastMALength = 14; // Fast Moving Average Length
input int slowMALength = 28; // Slow Moving Average Length
input bool useMAFilter = true; // Use MA Filter
input int magicNumber = 12345; // Magic Number

// Global variables
CTrade trade;
datetime lastTradeTime = 0;

int OnInit()
{
    trade.SetExpertMagicNumber(magicNumber);
    return(INIT_SUCCEEDED);
}

void OnTick()
{
    // Calculate MAs
    double fastMA = iMA(Symbol(), PERIOD_CURRENT, fastMALength,1, MODE_SMA, PRICE_CLOSE);
    double slowMA = iMA(Symbol(), PERIOD_CURRENT, slowMALength, 1, MODE_SMA, PRICE_CLOSE);

    // Get current Bid and Ask prices
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

    // Engulfing pattern detection
    bool bullishEngulfing = iHigh(Symbol(), PERIOD_CURRENT, 1) < iHigh(Symbol(), PERIOD_CURRENT, 2) && iLow(Symbol(), PERIOD_CURRENT, 1) > iLow(Symbol(), PERIOD_CURRENT, 2) && iClose(Symbol(), PERIOD_CURRENT, 1) > iOpen(Symbol(), PERIOD_CURRENT, 1);
    bool bearishEngulfing = iHigh(Symbol(), PERIOD_CURRENT, 1) < iHigh(Symbol(), PERIOD_CURRENT, 2) && iLow(Symbol(), PERIOD_CURRENT, 1) > iLow(Symbol(), PERIOD_CURRENT, 2) && iClose(Symbol(), PERIOD_CURRENT, 1) < iOpen(Symbol(), PERIOD_CURRENT, 1);

    // Check if there are any open trades
    bool hasOpenTrades = false;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            if (PositionGetString(POSITION_SYMBOL) == Symbol() && PositionGetInteger(POSITION_MAGIC) == magicNumber)
            {
                hasOpenTrades = true;
                break;
            }
        }
    }

    // Entry conditions
    if (!hasOpenTrades && TimeCurrent() > lastTradeTime + PeriodSeconds(PERIOD_CURRENT))
    {
        if (bullishEngulfing && (fastMA > slowMA || !useMAFilter))
        {
            double stopLossPrice = iLow(Symbol(), PERIOD_CURRENT, 2);
            double takeProfitPrice = ask + (ask - stopLossPrice) * profitRiskRatio / _Point;
            trade.Buy(lotSize, NULL, ask, stopLossPrice , takeProfitPrice);
            lastTradeTime = TimeCurrent();
        }
        if (bearishEngulfing && (fastMA < slowMA || !useMAFilter))
        {
            double stopLossPrice = iHigh(Symbol(), PERIOD_CURRENT, 2);
            double takeProfitPrice = bid - (stopLossPrice - bid) * profitRiskRatio / _Point;
            trade.Sell(lotSize, NULL, bid, stopLossPrice , takeProfitPrice);
            lastTradeTime = TimeCurrent();
        }
    }
}