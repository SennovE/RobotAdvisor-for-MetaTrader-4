//+------------------------------------------------------------------+
//|                                                   roboExpert.mq4 |
//|                                      Copyright 2023, Egor Sennov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Egor Sennov"
#property version   "1.16"
#property strict


                    //[0    , 1    , 2        , 3     , 4     , 5       , 6      , 7        , 8  ]
double arr[960][9]; //[mid=0, level, priceMove, moveTP, moveSL, breakeven, deposit, commission, num]
int ticketsNumbers[960];
const string closeObjects[] = {"CloseAlertWindow", "CloseYes", "CloseNo", "CloseAlertLable1", "CloseAlertLable2"};
int days = 0;
int k = 0;
const int LEN = 960;
const int SIZEX = 600;
const int SIZEY = SIZEX*2/3;
//const int BGCOLOR = Black, TEXTCOLOR = C'245,255,255', EDITBGCOLOR = Black;
const int BGCOLOR = C'245,255,255', TEXTCOLOR = Black, EDITBGCOLOR = White;
const double TS = 0.6;
const int TEXTSIZEHEAD = SIZEX/45*TS;
const int TEXTSIZEBIG = SIZEX/30*TS;
const int TEXTSIZESMALL = SIZEX/60*TS;
datetime prevCandleTime;
int tableColor[96];
double level_ = 175.00/100000, priceMove_ = 0.0/100000, moveTP_ = 0.0/100000, moveSL_ = 2.00/100000, breakeven_ = 10.0/100000, deposit_ = 4.00/100/1000, commission_ = 2.00;
bool startPr = false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    if (true)
      {
         string name;
         for (int i=0; i<96; i++)
         {
            name = "_" + i + "_";
            tableColor[i] = GlobalVariableGet(name);
         }
         level_ = GlobalVariableGet("globallevel_");
         priceMove_ = GlobalVariableGet("globalpriceMove_");
         moveTP_ = GlobalVariableGet("globalmoveTP_");
         moveSL_ = GlobalVariableGet("globalmoveSL_");
         breakeven_ = GlobalVariableGet("globalbreakeven_");
         deposit_ = GlobalVariableGet("globaldeposit_");
      }
    else for (int i=0; i<96; i++) tableColor[i] = 0;
    ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
    ObjectsDeleteAll(0);
    ButtonCreate(0, "ButtonInterface", 100, 25, 95, 20, "RoboExpert", "Arial Black", 10*TS, DarkRed);
    ObjectSetInteger(0,"ButtonInterface",OBJPROP_BGCOLOR,White);
    ObjectSetInteger(0,"ButtonInterface",OBJPROP_COLOR,Black);
    for (int i=0; i<LEN; i++) arr[i][8] = 0;
    const int minutes = TimeMinute(TimeLocal())/15;
    k = TimeHour(TimeLocal())*4+minutes+1;
    
    return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    GlobalVariableSet("globallevel_", level_);
    GlobalVariableSet("globalpriceMove_", priceMove_);
    GlobalVariableSet("globalmoveTP_", moveTP_);
    GlobalVariableSet("globalmoveSL_", moveSL_);
    GlobalVariableSet("globalbreakeven_", breakeven_);
    GlobalVariableSet("globaldeposit_", deposit_);
    string name;
    for (int i=0; i<96; i++)
       {
          name = "_" + i + "_";
          GlobalVariableSet(name, tableColor[i]);
       }
    ObjectsDeleteAll(0);
    ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    if (!startPr && TimeMinute(TimeLocal())%15 == 0)
      {
         startPr = true;
         OnTimer();
      }
    else if (TimeMinute(TimeLocal())%15 != 0) startPr = false;
      
    
    double volume;
    int orderTicker;
    double deposit;
    int num;
    for (int i = 0; i < 960; i++)
      {
        num = arr[i][8];
        orderTicker = ticketsNumbers[i];
        if (orderTicker == -1 || num == 0) continue;
        deposit = arr[i][6];
        
        volume = AccountBalance() * deposit;
        
        
        switch (num)
          {
            case -1:
              Rollback(i, volume, orderTicker);
              break;
            case 1:
              Breakdown(i, volume, orderTicker);
              break;
          }
      }
  }
//+------------------------------------------------------------------+
//| Opening a new candle                                             |
//+------------------------------------------------------------------+
void OnTimer()
  { 
    string name;
    if (IsTesting())
      {
         for (int i=0; i<96; i++)
         {
            name = "_" + i + "_";
            tableColor[i] = GlobalVariableGet(name);
         }
         level_ = GlobalVariableGet("globallevel_");
         priceMove_ = GlobalVariableGet("globalpriceMove_");
         moveTP_ = GlobalVariableGet("globalmoveTP_");
         moveSL_ = GlobalVariableGet("globalmoveSL_");
         breakeven_ = GlobalVariableGet("globalbreakeven_");
         deposit_ = GlobalVariableGet("globaldeposit_");
      }
    name = k/4 + "_" + k%4;
    ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,BGCOLOR);
    const double maxBid    = iHigh(Symbol(), PERIOD_M15, 1);
    const double minBid    = iLow(Symbol(), PERIOD_M15, 1);
    const double midBid    = NormalizeDouble((maxBid + minBid)/2, Digits);
    const double level     = level_;
    const double levelHigh = midBid + level;
    const double levelLow  = midBid - level;
    const double deposit   = deposit_;
    const int now = 96*days+k;
    int num;
    
    if (Ask <= levelHigh + level && Bid >= levelLow - level)
      {
        arr[now][0] = midBid;
        arr[now][1] = level_;
        arr[now][2] = priceMove_;
        arr[now][3] = moveTP_;
        arr[now][4] = moveSL_;
        arr[now][5] = breakeven_;
        arr[now][6] = deposit_;
        arr[now][7] = commission_;
        if (k == 0) num = tableColor[95];
        else num = tableColor[k-1];
        arr[now][8] = num;
        
        if (num != 0) Print("Свеча закрыта " , num, ". Среднее значение: ", midBid, " Уровень: ", level, " ", maxBid, " ", minBid);
        
        double priceMove = arr[now][2];
        double volume    = AccountBalance() * deposit;
        
        if (volume <= 0);
        else if (num == -1)
          {
            if (Ask > levelHigh + priceMove && Ask < levelHigh + level)
              {
                double moveTP     = arr[now][3];
                double moveSL     = arr[now][4];
                double price      = Ask;
                double stopLoss   = levelHigh + level - moveSL;
                double takeProfit = midBid - moveTP;
                int    cmd        = OP_SELL;
                Order(cmd, volume, price, stopLoss, takeProfit, now);
              }
            else if (Bid < levelLow - priceMove && Bid > levelLow - level)
              {
                double moveTP     = arr[now][3];
                double moveSL     = arr[now][4];
                double price      = Bid;
                double stopLoss   = levelLow - level + moveSL;
                double takeProfit = midBid + moveTP;
                int    cmd        = OP_BUY;
                Order(cmd, volume, price, stopLoss, takeProfit, now);
              }
          }
        else if (num == 1)
          {
            
            if (Ask > levelHigh - priceMove && Ask < levelHigh + level)
              {
                double moveTP     = arr[now][3];
                double moveSL     = arr[now][4];
                double price      = Ask;
                double stopLoss   = midBid + moveSL;
                double takeProfit = levelHigh + level + moveTP;
                int    cmd        = OP_BUY;
                Order(cmd, volume, price, stopLoss, takeProfit, now);
              }
            else if (Bid < levelLow + priceMove && Bid > levelLow - level)
              {
                double moveTP     = arr[now][3];
                double moveSL     = arr[now][4];
                double price      = Bid;
                double stopLoss   = midBid - moveSL;
                double takeProfit = levelLow - level - moveTP;
                int    cmd        = OP_SELL;
                Order(cmd, volume, price, stopLoss, takeProfit, now);
              }
          }
      }
    else ticketsNumbers[now] = -1;
    const int minutes = TimeMinute(TimeLocal())/15;
    k = TimeHour(TimeLocal())*4+minutes+1;
    if (k == 96)
      {
        k = 0;
        days += 1;
        if (days == 10)
          {
            const int len = 480;
            for (int i=0; i < len; i++)
              {
                for (int j=0; j < 9; j++)
                  {
                     arr[i][j] = arr[i+len][j];
                  }
                ticketsNumbers[i] = ticketsNumbers[i+len];
              }
            for (int i=480; i < 960; i++)
              {
                arr[i][8] = 0;
                ticketsNumbers[i] = 0;
              }
            days = 5;
          }
      }
  }

// Change StopLoss
void ChangeSL(int idx, bool plus)
  {
    double stloss;
    double breakeven = arr[idx][5];
    OrderSelect(ticketsNumbers[idx],SELECT_BY_TICKET);
    if (plus) stloss = OrderOpenPrice() + breakeven;
    else stloss = OrderOpenPrice() - breakeven;
    Print(OrderType(), " ", OrderTakeProfit(), " ", OrderOpenPrice(), " ", NormalizeDouble(stloss, Digits), " ", OrderStopLoss());
    bool res = OrderModify(
      OrderTicket(),
      OrderOpenPrice(),
      NormalizeDouble(stloss, Digits),
      OrderTakeProfit(),
      0,
      Red);
    int err = GetLastError();
    if (err == 4108) ticketsNumbers[idx] = -1;
    
  }

// Rollback (-1)
void Rollback(const int i, const double volume, const int orderTicker)
  {
    const double mid       = arr[i][0];
    const double level     = arr[i][1];
    const double levelHigh = mid + level;
    const double levelLow  = mid - level;
    const double moveTP    = arr[i][3];

    if (orderTicker == 0) // The order has not been issued
      {
        if (Ask >= levelHigh && volume > 0)
          {
            const double priceMove  = arr[i][2];
            const double moveSL     = arr[i][4];
            const double price      = levelHigh + priceMove;
            const double stopLoss   = levelHigh + level - moveSL;
            const double takeProfit = mid - moveTP;
            const int    cmd        = OP_SELLLIMIT;
            Order(cmd, volume, price, stopLoss, takeProfit, i); //Place an order with the SellLimit operation on rollback
          }
        else if (Bid <= levelLow && volume > 0)
          {
            const double priceMove  = arr[i][2];
            const double moveSL     = arr[i][4];
            const double price      = levelLow - priceMove;
            const double stopLoss   = levelLow - level + moveSL;
            const double takeProfit = mid + moveTP;
            const int    cmd        = OP_BUYLIMIT;
            Order(cmd, volume, price, stopLoss, takeProfit, i); // Place an order with the BuyLimit operation on rollback
          }
      }
    else // The order has been issued
      {
        const bool res = OrderSelect(orderTicker, SELECT_BY_TICKET);
        if (!(res))
          {
            ticketsNumbers[i] = -1;
          }
        else if (OrderType() == 3) // SellLimit Order
          {
            if (Bid <= mid && OrderDelete(orderTicker)) ticketsNumbers[i] = -1;
            else if (Bid <= OrderTakeProfit()) ChangeSL(i, false); // Bid is lowered to TP, SL is carried over
          }
        else if (OrderType() == 2) // BuyLimit Order
          {
            if (Ask >= mid && OrderDelete(orderTicker))
               {
                  ticketsNumbers[i] = -1;
               }
            else if (Ask >= OrderTakeProfit()) ChangeSL(i, true); // Ask reaches TP, SL is carried over
          }
      }
  }
// Breakdown (1)
void Breakdown(const int i, const double volume, const int orderTicker)
  {
    const double mid       = arr[i][0];
    const double level     = arr[i][1];
    const double levelHigh = mid + level;
    const double levelLow  = mid - level;
    const double moveTP    = arr[i][3];

    if (orderTicker == 0) // The order has not been issued
      {
        if (Ask >= levelHigh && volume > 0)
          {
            const double priceMove  = arr[i][2];
            const double moveSL     = arr[i][4];
            const double price      = levelHigh - priceMove;
            const double stopLoss   = mid + moveSL;
            const double takeProfit = levelHigh + level + moveTP;
            const int    cmd        = OP_BUYLIMIT;
            Order(cmd, volume, price, stopLoss, takeProfit, i); // Place an order with the BuyLimit operation at the breakdown
          }
        else if (Bid <= levelLow && volume > 0)
          {
            const double priceMove  = arr[i][2];
            const double moveSL     = arr[i][4];
            const double price      = levelLow + priceMove;
            const double stopLoss   = mid - moveSL;
            const double takeProfit = levelLow - level - moveTP;
            const int    cmd        = OP_SELLLIMIT;
            Order(cmd, volume, price, stopLoss, takeProfit, i); // Place an order with the SellLimit operation at the breakdown
          }
      }
    else // The order has been issued
      {
        bool res = OrderSelect(orderTicker, SELECT_BY_TICKET);
        if (!(res))
          {
            ticketsNumbers[i] = -1;
          }
        else if (OrderType() == 2) // BuyLimit Order
          {
            if (Ask >= levelHigh + level && OrderDelete(orderTicker)) ticketsNumbers[i] = -1;
            else if (Ask >= OrderTakeProfit()) ChangeSL(i, true); // Changing the SL
          }
        else if (OrderType() == 3) // SellLimit Order
          {
            if (Bid >= levelHigh - level && OrderDelete(orderTicker))
               {
                  ticketsNumbers[i] = -1;
               }
            else if (Bid <= OrderTakeProfit()) ChangeSL(i, false); // Changing the SL
          }
      }
  }

// Place an order with the specified parameters
void Order(int cmd, double volume, double price, double stopLoss, double takeProfit, int i)
  {
    int ticket = OrderSend(
      Symbol(),     // symbol 
      cmd,          // trading operation
      NormalizeDouble(volume/price, 2),       // number of lots
      NormalizeDouble(price, Digits),  // price 
      0,            // slippage 
      stopLoss,     // stop loss 
      takeProfit,   // take profit 
      NULL,         // comment 
      0,            // ID 
      0,            // the expiration date of the order
      Blue);        // color
    ticketsNumbers[i] = ticket;
  }

//+------------------------------------------------------------------+
//| Graphical interface                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
    static bool focus = false, click = false;
    static int mouseX = 0, mouseY = 0;
    
    if (id == CHARTEVENT_OBJECT_CLICK && !click)
      {
        if (sparam == "HideButton")
         {
            ObjectsDeleteAll(0);
            ButtonCreate(0, "ButtonInterface", 100, 25, 95, 20, "RoboExpert", "Arial Black", 10*TS, DarkRed);
            ObjectSetInteger(0,"ButtonInterface",OBJPROP_BGCOLOR,White);
            ObjectSetInteger(0,"ButtonInterface",OBJPROP_COLOR,Black);
         }
        else if (sparam == "CloseButton") CloseAlert();
        else if (sparam == "CloseYes") ExpertRemove();
        else if (sparam == "CloseNo") for (int i=0;i<5;i++) ObjectDelete(closeObjects[i]);
        else if (sparam == "ButtonInterface") OpenInterface();
        else if (StringFind(sparam, "_") != -1) TableClick(sparam);
        else if (sparam == "ApplyButton") GetEditText();
        else if (sparam == "ClearButton") TableClear();
          
        else if (sparam == "UselessGray" || sparam == "UselessGreen" || sparam == "UselessRed" || sparam == "UselessPurple") ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      }
    else if (id == CHARTEVENT_OBJECT_ENDEDIT)
      {
         ObjectSetInteger(0, "ApplyButton", OBJPROP_COLOR, TEXTCOLOR);
         ObjectSetInteger(0, "ApplyButton", OBJPROP_BORDER_COLOR, C'0,153,102');
      }
    else if (id == 4 || id == CHARTEVENT_OBJECT_CLICK && click)
      {
         focus = false;
         click = false;
         ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
         ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
      }
    else if (id == 9 && !click)
      {
         ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
         click = true;
      }
    else if (id == 10 && click)
      {
         if (!focus)
            {
               int x, y, xend, yend;
               const int chartWidth = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
               const int chartHeight = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
               x = ObjectGetInteger(0,"Window",OBJPROP_XDISTANCE);
               y = ObjectGetInteger(0,"Window",OBJPROP_YDISTANCE);
               x = chartWidth - x;
               y = y;
               xend = x + SIZEX;
               yend = y + SIZEY*0.083;
               if (GetLastError() != 0)
                  {
                     x = ObjectGetInteger(0,"ButtonInterface",OBJPROP_XDISTANCE);
                     y = ObjectGetInteger(0,"ButtonInterface",OBJPROP_YDISTANCE);
                     x = chartWidth - x;
                     y = y;
                     xend = x + 95;
                     yend = y + 20;
                  }
               if (x < lparam && lparam < xend && y < dparam && dparam < yend)
                  {
                     mouseX = lparam;
                     mouseY = dparam;
                     focus = true;
                     ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
                  }
               else
                  {
                     ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
                     click = false;
                  }
            }
         else
            {
               MoveInterface(mouseX - lparam, -(mouseY - dparam));
               mouseX = lparam;
               mouseY = dparam;
            }
      }
  }
//+------------------------------------------------------------------+
void TableClear()
  {
    int i;
    string name;
    for (i=0; i<96; i++) tableColor[i] = 0;
    for (i=0; i<24; i++)
      {
        for (int j=0; j<4; j++)
         {
            name = i+"_"+j;
            ObjectSetInteger(0, name, OBJPROP_BGCOLOR, LightGray);
         }
      }
    ObjectSetInteger(0,"ClearButton",OBJPROP_STATE,false);
    ObjectSetInteger(0, "ApplyButton", OBJPROP_COLOR, TEXTCOLOR);
    ObjectSetInteger(0, "ApplyButton", OBJPROP_BORDER_COLOR, C'0,153,102');
  }

void CloseAlert()
  {
    int x = ObjectGetInteger(0,"Window",OBJPROP_XDISTANCE) - SIZEX;
    int y = ObjectGetInteger(0,"Window",OBJPROP_YDISTANCE) - 20;
    int chart_ID = 0;
    RectLabelCreate(chart_ID,"CloseAlertWindow",SIZEX + x,20 + y,SIZEX,SIZEY);
    ButtonCreate(chart_ID, "CloseNo", SIZEX/7*6 + x, SIZEY/3*2 + y, SIZEX*9/28, SIZEY/3*2/5, "Нет", "Arial Black", TEXTSIZEBIG, clrNONE);
    ButtonCreate(chart_ID, "CloseYes", SIZEX/28*13 + x, SIZEY/3*2 + y, SIZEX*9/28, SIZEY/3*2/5, "Удалить", "Arial Black", TEXTSIZEBIG, clrNONE);
    LabelCreate(chart_ID,"CloseAlertLable1",SIZEX/1.25 + x,SIZEY/3 + y,"Вы точно хотите удалить","Arial Black",TEXTSIZEBIG);
    LabelCreate(chart_ID,"CloseAlertLable2",SIZEX/1.3 + x,SIZEY/3 + SIZEX/30*2 + y,"советника с графика?","Arial Black",TEXTSIZEBIG);
   
  }

void MoveInterface(const int x, const int y)
   {
      string name;
      int obj_x, obj_y;
      for (int i=0;i<ObjectsTotal();i++)
        {
         name = ObjectName(i);
         obj_x = ObjectGetInteger(0,name,OBJPROP_XDISTANCE);
         obj_y = ObjectGetInteger(0,name,OBJPROP_YDISTANCE);
         ObjectSetInteger(0,name,OBJPROP_XDISTANCE,obj_x+x); 
         ObjectSetInteger(0,name,OBJPROP_YDISTANCE,obj_y+y);
        }
   }
   
void OpenInterface()
  {  
    const int chart_ID = 0;
    string name;
    ObjectsDeleteAll(0);
    RectLabelCreate(chart_ID,"Window",SIZEX,20,SIZEX,SIZEY);
    LabelCreate(chart_ID,"RoboExpert",SIZEX/69.9*69,SIZEY/12,"RoboExpert","Arial Black",TEXTSIZEHEAD);
    ButtonCreate(chart_ID, "CloseButton", SIZEY/12+SIZEY/100, SIZEY/14, SIZEY/12, SIZEY/12, "r", "Webdings", TEXTSIZEBIG, BGCOLOR);
    ButtonCreate(chart_ID, "HideButton", SIZEY/12*2+SIZEY/100, SIZEY/14, SIZEY/12, SIZEY/12, "0", "Webdings", TEXTSIZEBIG, BGCOLOR);
    RectLabelCreate(chart_ID,"SubWindow",SIZEX,SIZEY*0.15,SIZEX,SIZEY*0.917);
    RectLabelCreate(chart_ID,"TableWindow",SIZEX*0.964,SIZEY/5,SIZEX*0.9286,SIZEY*0.5);
    name = "Hours";
    LabelCreate(chart_ID,name,SIZEX/2,SIZEY*0.22,"Часы","Arial",TEXTSIZEHEAD);
    name = "Minutes";
    LabelCreate(chart_ID,name,SIZEX*0.957,SIZEY/1.9,"Минуты","Arial",TEXTSIZEHEAD);
    ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,90);
    int i;
    int j;
    const int startX = SIZEX*0.86;
    const int startY = SIZEY/3.3;
    const int size = SIZEY/20;
    for (i=0; i<24; i++)
       {  
          if (i<10) name = "0" + i;
          else name = i;
          LabelCreate(chart_ID,name,startX-SIZEY/100-size*i,startY,name,"Arial",TEXTSIZESMALL);
       }
    for (i=0; i<4; i++)
       {  
          if (i==0) name = "00 ";
          else name = i*15 + " ";
          LabelCreate(chart_ID,name,startX+size,startY+size+SIZEY/150+size*i,name,"Arial",TEXTSIZESMALL);
       }
    int num;
      
    for (i=0; i<24; i++)
      {
        for (j=0; j<4; j++)
          {
            name = i+"_"+j;
            ButtonCreate(chart_ID, name, startX-size*i, startY+size+size*j, size, size, "", "Arial", 0, BGCOLOR);
            if (ticketsNumbers[95 - (ArraySize(ticketsNumbers) - ((10 - days)*96-96+i*4+j) - 1)] != 0)
              {
                ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,C'153,0,204');
              }
            num = tableColor[4*i+j];
            switch(num)
               {
                  case 0:
                     ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, LightGray);
                     break;
                  case 1:
                     ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, C'0,153,102');
                     break;
                  case -1:
                     ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, C'255,51,51');
                     break;
               }
           }
        }
    
    ButtonCreate(chart_ID, "UselessGray", SIZEX*0.93, SIZEY*0.607, size*0.75, size*0.75, "", "Arial", 0, BGCOLOR);
    LabelCreate(chart_ID,"GrayText",SIZEX*0.90,SIZEY*0.595," - не проверять","Arial",TEXTSIZEHEAD);
    ButtonCreate(chart_ID, "UselessGreen", SIZEX*0.67, SIZEY*0.607, size*0.75, size*0.75, "", "Arial", 0, BGCOLOR);
    LabelCreate(chart_ID,"GreenText",SIZEX*0.64,SIZEY*0.595," - пробой","Arial",TEXTSIZEHEAD);
    ButtonCreate(chart_ID, "UselessRed", SIZEX*0.485, SIZEY*0.607, size*0.75, size*0.75, "", "Arial", 0, BGCOLOR);
    LabelCreate(chart_ID,"RedText",SIZEX*0.465,SIZEY*0.595," - отскок","Arial",TEXTSIZEHEAD);
    ButtonCreate(chart_ID, "UselessPurple", SIZEX*0.33, SIZEY*0.607, size*0.75, size*0.75, "", "Arial", 0, BGCOLOR);
    LabelCreate(chart_ID,"PurpleText",SIZEX*0.30,SIZEY*0.595," - сделка закрыта","Arial",TEXTSIZEHEAD);
    ObjectSetInteger(chart_ID, "UselessPurple", OBJPROP_BGCOLOR, BGCOLOR);
    ObjectSetInteger(chart_ID, "UselessPurple", OBJPROP_BORDER_COLOR, C'153,0,204');
    ObjectSetInteger(chart_ID, "UselessRed", OBJPROP_BGCOLOR, C'255,51,51');
    ObjectSetInteger(chart_ID, "UselessGreen", OBJPROP_BGCOLOR, C'0,153,102');
    ObjectSetInteger(chart_ID, "UselessGray", OBJPROP_BGCOLOR, LightGray);
      
    LabelCreate(chart_ID,"Level",SIZEX*0.95,SIZEY*0.72,"Уровень:","Arial",TEXTSIZEHEAD);
    LabelCreate(chart_ID,"PriceMove",SIZEX*0.95,SIZEY*0.80,"Смещение цены:","Arial",TEXTSIZEHEAD);
    LabelCreate(chart_ID,"MoveTP",SIZEX*0.95,SIZEY*0.88,"Смещение TP:","Arial",TEXTSIZEHEAD);
    LabelCreate(chart_ID,"MoveSL",SIZEX*0.95,SIZEY*0.96,"Смещение SL:","Arial",TEXTSIZEHEAD);
    EditCreate(chart_ID, "LevelEdit", SIZEX*0.7, SIZEY*0.72, SIZEX/7, SIZEX/25, level_*100000, "Arial", TEXTSIZEHEAD);
    EditCreate(chart_ID, "PriceMoveEdit", SIZEX*0.7, SIZEY*0.8, SIZEX/7, SIZEX/25, priceMove_*100000, "Arial", TEXTSIZEHEAD);
    EditCreate(chart_ID, "MoveTPEdit", SIZEX*0.7, SIZEY*0.88, SIZEX/7, SIZEX/25, moveTP_*100000, "Arial", TEXTSIZEHEAD);
    EditCreate(chart_ID, "MoveSLEdit", SIZEX*0.7, SIZEY*0.96, SIZEX/7, SIZEX/25, moveSL_*100000, "Arial", TEXTSIZEHEAD);
      
    LabelCreate(chart_ID,"Breakeven",SIZEX*0.5,SIZEY*0.72,"Безубыток:","Arial",TEXTSIZEHEAD);
    LabelCreate(chart_ID,"Deposit",SIZEX*0.5,SIZEY*0.80,"Загрузка депозита (%):","Arial",TEXTSIZEHEAD);
    LabelCreate(chart_ID,"Commission",SIZEX*0.5,SIZEY*0.88,"Комиссия ($/лот):","Arial",TEXTSIZEHEAD);
    EditCreate(chart_ID, "BreakevenEdit", SIZEX*0.179, SIZEY*0.72, SIZEX/7, SIZEX/25, breakeven_*100000, "Arial", TEXTSIZEHEAD);
    EditCreate(chart_ID, "DepositEdit", SIZEX*0.179, SIZEY*0.8, SIZEX/7, SIZEX/25, deposit_*100*1000, "Arial", TEXTSIZEHEAD);
    EditCreate(chart_ID, "CommissionEdit", SIZEX*0.179, SIZEY*0.88, SIZEX/7, SIZEX/25, commission_, "Arial", TEXTSIZEHEAD);
      
    ButtonCreate(chart_ID, "ApplyButton", SIZEX*0.214, SIZEY*0.96, SIZEX/5.6, SIZEX/25, "Применить", "Arial", TEXTSIZEHEAD, Gray);
    ObjectSetInteger(chart_ID, "ApplyButton", OBJPROP_BGCOLOR, EDITBGCOLOR);
    ObjectSetInteger(chart_ID, "ApplyButton", OBJPROP_COLOR, Gray);
    
    ButtonCreate(chart_ID, "ClearButton", SIZEX*0.5, SIZEY*0.96, SIZEX/3.8, SIZEX/25, "Очистить таблицу", "Arial", TEXTSIZEHEAD, Gray);
    ObjectSetInteger(chart_ID, "ClearButton", OBJPROP_BGCOLOR, EDITBGCOLOR);
  }
   
void RectLabelCreate(const long             chart_ID=0,               // ID графика 
                     const string           name="RectLabel",         // имя метки
                     const int              x=0,                      // координата по оси X 
                     const int              y=0,                      // координата по оси Y 
                     const int              width=0,                  // ширина 
                     const int              height=0)                 // высота
   {
      ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,BGCOLOR);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,Gray);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,true);
   }
   
void ButtonCreate(const long              chart_ID=0,               // ID графика 
                  const string            name="Button",            // имя кнопки
                  const int               x=0,                      // координата по оси X 
                  const int               y=0,                      // координата по оси Y 
                  const int               width=0,                  // ширина кнопки 
                  const int               height=0,                 // высота кнопки
                  const string            text="",                  // текст 
                  const string            font="Arial",             // шрифт 
                  const int               font_size=10,             // размер шрифта
                  const color             border_clr=clrNONE)       // цвет границы
   {
      ObjectCreate(chart_ID,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,TEXTCOLOR);
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,BGCOLOR);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,false); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false); 
   }

void LabelCreate(const long              chart_ID=0,               // ID графика 
                 const string            name="Label",             // имя метки
                 const int               x=0,                      // координата по оси X 
                 const int               y=0,                      // координата по оси Y
                 const string            text="Label",             // текст 
                 const string            font="Arial",             // шрифт 
                 const int               font_size=10)             // размер шрифта
   { 
      ObjectCreate(chart_ID,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,TEXTCOLOR);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,false); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false); 
   }

void EditCreate(const long             chart_ID=0,               // ID графика 
                const string           name="Edit",              // имя объекта
                const int              x=0,                      // координата по оси X 
                const int              y=0,                      // координата по оси Y 
                const int              width=0,                  // ширина 
                const int              height=0,                 // высота 
                const string           text="Text",              // текст 
                const string           font="Arial",             // шрифт 
                const int              font_size=10)             // размер шрифта
   {
      ObjectCreate(chart_ID,name,OBJ_EDIT,0,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,ALIGN_LEFT);
      ObjectSetInteger(chart_ID,name,OBJPROP_READONLY,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,EDITBGCOLOR);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,TEXTCOLOR);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,Gray);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,false); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false); 
   }
  
void TableClick(const string name)
   {
      ObjectSetInteger(0,name,OBJPROP_STATE,false);
      ObjectSetInteger(0, "ApplyButton", OBJPROP_COLOR, TEXTCOLOR);
      ObjectSetInteger(0, "ApplyButton", OBJPROP_BORDER_COLOR, C'0,153,102');
      
      ushort u_sep = StringGetCharacter("_",0); 
      string result[2];
      StringSplit(name, u_sep, result);
      const int i = StringToInteger(result[0]), j = StringToInteger(result[1]);
      const int num = ObjectGetInteger(0,name,OBJPROP_BGCOLOR);
      int pos = i*4+j;

      switch(num)
         {
            case 13882323:
               tableColor[pos] = 1;
               ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'0,153,102');               
               break;
            case 6723840:
               tableColor[pos] = -1;
               ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'255,51,51');
               break;
            case 3355647:
               tableColor[pos] = 0;
               ObjectSetInteger(0, name, OBJPROP_BGCOLOR, LightGray);
               break;
         }
   }
   
void GetEditText()
   {  
      int text;
      text = StringToInteger(ObjectGetString(0, "LevelEdit", OBJPROP_TEXT));
      if (text >= 0) level_ = NormalizeDouble(StringToDouble(text)/100000, Digits);
      text = StringToInteger(ObjectGetString(0, "PriceMoveEdit", OBJPROP_TEXT));
      if (text >= 0) priceMove_ = NormalizeDouble(StringToDouble(text)/100000, Digits);
      text = StringToInteger(ObjectGetString(0, "MoveTPEdit", OBJPROP_TEXT));
      if (text >= 0) moveTP_ = NormalizeDouble(StringToDouble(text)/100000, Digits);
      text = StringToInteger(ObjectGetString(0, "MoveSLEdit", OBJPROP_TEXT));
      if (text >= 0) moveSL_ = NormalizeDouble(StringToDouble(text)/100000, Digits);
      text = StringToInteger(ObjectGetString(0, "BreakevenEdit", OBJPROP_TEXT));
      if (text >= 0) breakeven_ = NormalizeDouble(StringToDouble(text)/100000, Digits);
      text = StringToInteger(ObjectGetString(0, "DepositEdit", OBJPROP_TEXT));
      if (text >= 0) deposit_ = StringToDouble(text)/100/1000;
      text = StringToInteger(ObjectGetString(0, "CommissionEdit", OBJPROP_TEXT));
      if (text >= 0) commission_ = NormalizeDouble(StringToDouble(text), Digits);
      ObjectSetInteger(0,"ApplyButton",OBJPROP_STATE,false);
      ObjectSetInteger(0, "ApplyButton", OBJPROP_BGCOLOR, EDITBGCOLOR);
      ObjectSetInteger(0, "ApplyButton", OBJPROP_COLOR, LightGray);
      ObjectSetInteger(0, "ApplyButton", OBJPROP_BORDER_COLOR, LightGray);
      GlobalVariableSet("globallevel_", level_);
      GlobalVariableSet("globalpriceMove_", priceMove_);
      GlobalVariableSet("globalmoveTP_", moveTP_);
      GlobalVariableSet("globalmoveSL_", moveSL_);
      GlobalVariableSet("globalbreakeven_", breakeven_);
      GlobalVariableSet("globaldeposit_", deposit_);
      string name;
      for (int i=0; i<96; i++)
         {
            name = "_" + i + "_";
            GlobalVariableSet(name, tableColor[i]);
         }
   }
