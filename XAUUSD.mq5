//+------------------------------------------------------------------+
//|                                                    AutoMoney.mq5 |
//|                                                            Denis |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Denis"
#property link      ""
#property version   "1.00"
// Файлы проверки ошибок с MQL5
///#include <CheckMoneyForTrade.mqh> // Нехватка средств для проведения торговой операции
//#include <CheckVolumeValue.mqh>   // Неправильные объемы в торговых операциях
//#include <IsNewOrderAllowed.mqh>  // Ограничение на количество отложенных ордеров
// Ограничение на количество лотов по одному символу - внедрить
// Установка уровней TakeProfit и StopLoss в пределах минимального уровня SYMBOL_TRADE_STOPS_LEVEL - внедрить
// Попытка модификации ордера или позиции в пределах уровня заморозки SYMBOL_TRADE_FREEZE_LEVEL - внедрить
// Ошибки, возникающие при работе с символами с недостаточной историей котировок
// Выход за пределы мссива (array out of range)
// Отправка запроса на модификацию уровней без фактического их изменения
// Попытка импорта скомпилированных файлов (даже EX4/EX5) и DLL
// Обращение к пользовательским индикаторам через iCustom()
// Передача недопустимого параметра в функцию (ошибки времени выполнения)
// Access violation
// Потребление ресурсов процессора памяти

// Мои файлы
//#include <Errors.mqh>
//#include <ErrorsServer.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
enum PERIOD {PERIOD_M30};       // общий таймфрейм программы
input double OP_XAUUSD = 40; // 15-30
input double SL_XAUUSD = 520; // 25-450
input double TS_XAUUSD = 1000; // 600-1600
double lot = 0.01;
double bid;
double ask;
double spread;
double minAO;
double maxAO;
double raznica1;
double raznica2;
double _NewBar1;
double _NewBar2;
bool prices = false;
bool AO_NewBar;
int signalAO = 0;              // количество сигналов AO
bool  AO_SIGNAL[2];            // используется в AO.mqh
ENUM_ORDER_TYPE type_Buy = ORDER_TYPE_BUY_STOP;
ENUM_ORDER_TYPE type_Sell = ORDER_TYPE_SELL_STOP;
double mAO[];
double balance;
double RealFreeBalance;
double balances;                // общий баланс счета
double balanceFreeMargin;       // свободная маржа
int CreditPlecho;               // кредитное плече счета
double Price_Trade_Buy;
double Price_Trade_Sell;
bool modifyBuy;
bool modifySell;
ulong ti;
double res_Buy;
double res_Sell;
//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//+------------------------------------------------------------------+
//| Balance.mqh                                                      | // рассчитать баланс при открытии сделок с учетом плеча
//+------------------------------------------------------------------+ // информация по счету от брокера
   RealFreeBalance = AccountInfoDouble(ACCOUNT_EQUITY); // текущие свободные средства
//Print("Свободные средства: ",RealFreeBalance);
//Print("Средств на счёте: ",AccountInfoDouble(ACCOUNT_EQUITY)," RUB."); // средства на счете в валюте депозита
//Print("Текущая приыль: ",AccountInfoDouble(ACCOUNT_PROFIT), " RUB."); // текущая прибыль
   double RealPrice = iHigh(Symbol(),PERIOD_M1,0); // текущая цена рубль//доллар
   double RealZalog = NormalizeDouble(RealPrice*1000/AccountInfoInteger(ACCOUNT_LEVERAGE),2); // AccountInfoInteger(ACCOUNT_LEVERAGE)
// текущий залог в рублях, нормализованный
//Print("Маржа = ",RealZalogRub);
//Print("Брокер: ",AccountInfoString(ACCOUNT_COMPANY));
//Print("Пользователь: ",AccountInfoString(ACCOUNT_NAME));
//Print("Номер счета: ",AccountInfoInteger(ACCOUNT_LOGIN));
   CreditPlecho = ACCOUNT_LEVERAGE;
//Print("Кредитное плечо: ",CreditPlecho);
//Print("Максимальное количество отложенных ордеров ",ACCOUNT_LIMIT_ORDERS);
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
//Print("Текущая прибыль: ",AccountInfoDouble(ACCOUNT_PROFIT), " руб.");
//Print("Собственные средства: ",AccountInfoDouble(ACCOUNT_EQUITY)," руб.");
//Print("Размер залога по сделкам: ",AccountInfoDouble(ACCOUNT_MARGIN)," руб.");
   balanceFreeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//Print("Средства доступные для открытия сделок: ",balanceFreeMargin," руб.");
//SendNotification("Эксперт инициализирован"); // PUSH уведомление на телефон
//+------------------------------------------------------------------+
//| Balance.mqh                                                      |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| NewBar.mqh                                                       |
//+------------------------------------------------------------------+
   _NewBar1 = iOpen("XAUUSDrfd",PERIOD(),0);          // получаем цену открытия 0 бара
   _NewBar2 = iOpen("XAUUSDrfd",PERIOD(),1);          // получаем цену открытия 1 бара
   raznica1  = _NewBar1 - _NewBar2;                   // разница сохраняется в 0 разнице
//+------------------------------------------------------------------+
//| NewBar.mqh                                                       |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Price.mqh                                                        |
//+------------------------------------------------------------------+
   MqlTick price;
   if(SymbolInfoTick("XAUUSDrfd",price)==true)
     {
      bid = price.bid;
      ask = price.ask;
      maxAO = NormalizeDouble(iHigh("XAUUSDrfd",PERIOD(),1),Digits());
      minAO = NormalizeDouble(iLow("XAUUSDrfd",PERIOD(),1),Digits());
      prices = true;
      spread = NormalizeDouble(ask-bid,Digits());
     }
   else
     {
      prices = false;
     }
//+------------------------------------------------------------------+
//| Price.mqh                                                        |
//+------------------------------------------------------------------+
   Sleep(3000);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//+------------------------------------------------------------------+
//| Price.mqh присваиваем текущие bid и ask цены переменным          |
//+------------------------------------------------------------------+
   MqlTick price;
   if(SymbolInfoTick("XAUUSDrfd",price)==true)
     {
      bid = price.bid;
      ask = price.ask;
      maxAO = NormalizeDouble(iHigh("XAUUSDrfd",PERIOD(),1),Digits());
      minAO = NormalizeDouble(iLow("XAUUSDrfd",PERIOD(),1),Digits());
      prices = true;
      spread = NormalizeDouble(ask-bid,Digits());
     }
   else
     {
      prices = false;
     }
//+------------------------------------------------------------------+
//| Price.mqh                                                        |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| OrderModifyActive.mqh модифицируем действующие ордера            |
//+------------------------------------------------------------------+
   MqlTradeRequest request1;
   MqlTradeResult result1;
   int total1=PositionsTotal();                                                     // получаем количество активных ордеров
   for(int i=0; i<total1; i++)
     {
      ulong position_ticket = PositionGetTicket(i);                                 // тикет позиции
      double sl=PositionGetDouble(POSITION_SL);                                     // Stop Loss позиции текущий
      string coment = PositionGetString(POSITION_COMMENT);
      double price1 = PositionGetDouble(POSITION_PRICE_OPEN);                       // цена открытия ордера
      double stl_Buy  = NormalizeDouble(bid-TS_XAUUSD*Point(),Digits());            // цена нового стоп лосса
      double stl_Sell = NormalizeDouble(ask+TS_XAUUSD*Point(),Digits());
      //***********************************************************************
      if((coment == "XAUUSDrfd_AO_BUY")  &&                                         // тип ордера SELL или BAY
         (bid > price1+spread)           &&
         (stl_Buy != sl)                 &&                                         // новый стоп лосс не равен старому стоп лоссу
         (stl_Buy > sl)                  &&                                         // новый стоп лосс больше старого стоп лосса
         (prices == true))
         {
            ZeroMemory(request1);                                                   // обнуление структуры по всей видимости
            ZeroMemory(result1);
            request1.action = TRADE_ACTION_SLTP;                                    // выбор типа торговой операции
            request1.position = position_ticket;                                    // тикет текущей позиции в цикле
            request1.sl = stl_Buy;                                                  // новый стоп лосс
            if(!OrderSend(request1,result1))                                        // если одер не открылся
               PrintFormat("Ошибка модификации XAUUSD_BUY %d", GetLastError());     // обрабатываем ошибку
         }
      if((coment == "XAUUSDrfd_AO_SELL")  &&
         (ask < price1-spread)            &&
         (stl_Sell != sl)                 &&
         (stl_Sell < sl)                  &&
         (prices == true))
         {
            ZeroMemory(request1); 
            ZeroMemory(result1);
            request1.action = TRADE_ACTION_SLTP; 
            request1.position = position_ticket; 
            request1.sl = stl_Sell;       
            if(!OrderSend(request1,result1))                                 
               PrintFormat("Ошибка модификации XAUUSD_SELL %d", GetLastError());   
         }
     }
//+------------------------------------------------------------------+
//| OrderModifyActive.mqh                                            |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| AO_Trade.mqh  индикатор АО                                       |
//+------------------------------------------------------------------+
   _NewBar1 = iOpen("XAUUSDrfd",PERIOD(),0);         // цена открытия текущего    бара
   _NewBar2 = iOpen("XAUUSDrfd",PERIOD(),1);         // цена открытия предыдущего бара
   raznica2 = _NewBar1 - _NewBar2;                   // разница в пунктах между текущим и предыдущими барами
   if(raznica1 != raznica2)                          // если цены открытия баров не равны
     {
      raznica2  = raznica1;                          // записываем новое значение в старую переменную
      AO_NewBar = true;                              // флаг новый бар активен
     }
   else                                              // иначе
     {AO_NewBar = false;}                            // флаг новый бар не
//*******************************************************************************************************************
   if(AO_NewBar == true)                             // если флаг новый бар активен
     {
      int hAO;
      int ALLorders2 = OrdersTotal();                // получаем общее количество ОТЛОЖЕННЫХ ордеров
      if(ALLorders2 == 0)                            // если количество отложенных ордеров = 0
        {
         ALLorders2 = 1;                             // то, присваиваем случайное значение в переменную
        }
      string ALOrders[];                                          // создаем динамический массив для комментарие
      ulong AO_Ticket[];                                          // создаем динамический массив для тикетов ордеров
      ArrayResize(ALOrders,ALLorders2);                           // устанавливаем размер массива равным количеству ордеров
      ArrayResize(AO_Ticket,ALLorders2);                          // устанавливаем размер массива равным количеству ордеров
      for(int q=0; q<ALLorders2 ; q++)                            // пробегаем по количеству ордеров
        {
         ulong ticket=OrderGetTicket(q);                          // копируем тикет ордера 1
         if(ticket != 0)                                          // ордер успешно скопирован
           {
            string commente = OrderGetString(ORDER_COMMENT);      // достаем из ордера комментарий
            ALOrders[q] = commente;                               // записываем комментарий в динамический массив
            AO_Ticket[q] = ticket;                                // записываем тикет этого ордера в динамический массив
           }
         else
           {
            ALOrders[q] = "RANDOM";
           }
        }
      //*******************************************************************************************************************
      MqlTradeRequest request;
      MqlTradeResult result;
      hAO = iAO("XAUUSDrfd",PERIOD());
      CopyBuffer(hAO,0,0,6,mAO);
      ArraySetAsSeries(mAO,true);
      if(mAO[1] > mAO[2] &&
         mAO[2] > mAO[3] &&
         mAO[3] > mAO[4] &&
         mAO[4] < mAO[5] &&
         (iHigh("XAUUSDrfd",PERIOD(),0) < iHigh("XAUUSDrfd",PERIOD(),1)))
        {
         // перебираем отложенные ордера на соответствие комментарию
         bool newOrderAOBuy = true;
         bool activeOrderAOBuy = true;
         //*******************************************************************************************************************
         for(int i=0; i<ALLorders2; i++)                  // если есть сигнал индикатора
           {
            if(ALOrders[i] == "XAUUSDrfd_AO_BUY")         // проверяем все отложенные ордера на соответствие комментарию
              {                                           // если комментарий совпал, то запрещаем открывать новый отложенный ордер
               newOrderAOBuy = false;                     // и мы должны модифицировать старый ордер на новый сигнал
               modifyBuy=true;
               ti = AO_Ticket[i];   
              }
           }
         //*******************************************************************************************************************
            double new_Price = NormalizeDouble(maxAO+OP_XAUUSD*Point(),Digits());
            if((new_Price != Price_Trade_Buy)    && 
               (new_Price < Price_Trade_Buy)     && 
               (new_Price > ask)                 &&
               (newOrderAOBuy == false)          &&
               (modifyBuy==true))
               {
               string buy = "BUY";
               OrderModify(buy,ti,maxAO,minAO,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_SELL",Digits());
               Price_Trade_Buy = res_Buy;
               }
         //*******************************************************************************************************************
         int active=PositionsTotal();
         for(int i=0; i<active; i++)
           {
            ulong tick[];
            ArrayResize(tick,active);
            for(int q=0; q<active; q++)
              {
               ulong tic = PositionGetTicket(q);
               if(tic != 0)
                 {
                  string comentAOactiveBuy = PositionGetString(POSITION_COMMENT);
                  if(comentAOactiveBuy == "XAUUSDrfd_AO_BUY")
                    {
                     activeOrderAOBuy = false;
                    }
                 }
              }
           }
         //*******************************************************************************************************************
         if((newOrderAOBuy == true) && (activeOrderAOBuy == true))
           {
            if((maxAO > ask) && (minAO < bid))
               OpenOrder(type_Buy,maxAO,minAO,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_BUY",Digits());
            if((maxAO > ask) && (minAO > bid))
               OpenOrder(type_Buy,maxAO,bid,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_BUY",Digits());
            if((maxAO < ask) && (minAO < bid))
               OpenOrder(type_Buy,ask,minAO,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_BUY",Digits());
            if((maxAO < ask) && (minAO > bid))
               OpenOrder(type_Buy,ask,bid,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_BUY",Digits());
           }
        }
      //*********************************************** --- ПРОДАЖА --- ************************************************
      hAO = iAO("XAUUSDrfd",PERIOD());
      CopyBuffer(hAO,0,0,6,mAO);
      ArraySetAsSeries(mAO,true);
      if(mAO[1] < mAO[2] &&
         mAO[2] < mAO[3] &&
         mAO[3] < mAO[4] &&
         mAO[4] > mAO[5] &&
         (iLow("XAUUSDrfd",PERIOD(),0) > iLow("XAUUSDrfd",PERIOD(),1)))
        {
         bool newOrderAOSell = true;
         bool activeOrderAOSell = true;
         //*******************************************************************************************************************
         for(int i=0; i<ALLorders2; i++)  // если есть сигнал по конкретной валюте
           {
            if(ALOrders[i] == "XAUUSDrfd_AO_SELL")
              {
               newOrderAOSell = false;
               ti = AO_Ticket[i];
               modifySell=true;
              }
           }
         //*******************************************************************************************************************
         double new_Price = NormalizeDouble(minAO-OP_XAUUSD*Point(),Digits());
            if((new_Price != Price_Trade_Sell)    && 
               (new_Price > Price_Trade_Sell)     && 
               (new_Price < bid)                  &&
               (newOrderAOSell == false)          &&
               (modifySell==true))
               {
                  string sell = "SELL";
                  OrderModify(sell,ti,maxAO,minAO,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_SELL",Digits());
                  Price_Trade_Sell = res_Sell;
               }
         //*******************************************************************************************************************
         int active=PositionsTotal();
         for(int i=0; i<active; i++)
           {
            ulong tick[];
            ArrayResize(tick,active);
            for(int q=0; q<active; q++)
              {
               ulong tic = PositionGetTicket(q);
               if(tic != 0)
                 {
                  string comentAOactiveSell = PositionGetString(POSITION_COMMENT);
                  if(comentAOactiveSell == "XAUUSDrfd_AO_SELL")
                    {
                     activeOrderAOSell = false;
                    }
                 }
              }
           }
         //*******************************************************************************************************************
         if((newOrderAOSell == true) && (activeOrderAOSell == true))
           {
            if((maxAO > ask) && (minAO < bid))
               OpenOrder(type_Sell,maxAO,minAO,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_SELL",Digits());
            if((maxAO > ask) && (minAO > bid))
               OpenOrder(type_Sell,maxAO,bid,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_SELL",Digits());
            if((maxAO < ask) && (minAO < bid))
               OpenOrder(type_Sell,ask,minAO,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_SELL",Digits());
            if((maxAO < ask) && (minAO > bid))
               OpenOrder(type_Sell,ask,bid,OP_XAUUSD,SL_XAUUSD,"XAUUSDrfd","_AO_SELL",Digits());
           }
        }
     }
//+------------------------------------------------------------------+
//| AO_Trade.mqh                                                     |
//+------------------------------------------------------------------+
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool OpenOrder(ENUM_ORDER_TYPE type1, double PricesMAX,double PricesMIN, double OP_Symbol, double SL_Symbol, string Comm, string DopComm, int pips)
  {
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   request.action = TRADE_ACTION_PENDING;
   request.symbol = Comm;
   request.volume = lot;

   if(type1 == ORDER_TYPE_BUY_STOP)
     {
      request.type = type1;
      Price_Trade_Buy = NormalizeDouble(PricesMAX+OP_Symbol*Point(),pips);
      request.price = Price_Trade_Buy;
      request.sl = NormalizeDouble(PricesMIN-SL_Symbol*Point(),pips);
      request.comment = Comm + DopComm;
      if(!OrderSend(request,result))
        {PrintFormat(Comm+DopComm, " - Error open order - %d", GetLastError());}
      else
        {
         Print("Ticket order ",Comm+DopComm," ", result.order);
        }
     }
   if(type1 == ORDER_TYPE_SELL_STOP)
     {
      request.type = type1;
      Price_Trade_Sell = NormalizeDouble(PricesMIN-OP_Symbol*Point(),pips);
      request.price = Price_Trade_Sell;
      request.sl = NormalizeDouble(PricesMAX+SL_Symbol*Point(),pips);
      request.comment = Comm + DopComm;
      if(!OrderSend(request,result))
        {PrintFormat(Comm+DopComm, " - Error open order - %d", GetLastError());}
      else
        {
         Print("Ticket order ",Comm+DopComm," ", result.order);
        }
     }
   return(true);
  }
//********************************************************************* модификация отложенного ордера на покупку
bool OrderModify(string poz, ulong ticket, double PriceASK, double PriceBID,double OP_Symbol, double SL_Symbol, string Comm, string DopComm,int pips)
  {
   MqlTradeRequest request = {};
   MqlTradeResult result = {0};
   request.action = TRADE_ACTION_MODIFY;
   request.order = ticket;
   request.symbol = Comm;
   if(poz == "BUY")
     {
      request.price = NormalizeDouble(PriceASK+OP_Symbol*Point(),pips);
      request.sl = NormalizeDouble(PriceBID-SL_Symbol*Point(),pips);
      if(!OrderSend(request,result))
        {
         PrintFormat(" - ERROR МОДИФИКАЦИИ ОТЛОЖЕННОГО BUY - %d", GetLastError());
        }
      else
        {
         Print("ОТЛОЖЕННЫЙ МОДИФИЦИРОВАН BUY ",Comm+DopComm," ", result.order);
         modifyBuy = false;
         res_Buy = request.price;
        }
     }
   if(poz == "SELL")
     {
      request.price = NormalizeDouble(PriceBID-OP_Symbol*Point(),pips);
      request.sl = NormalizeDouble(PriceASK+SL_Symbol*Point(),pips);
      if(!OrderSend(request,result))
        {
         PrintFormat(" - ERROR МОДИФИКАЦИИ ОТЛОЖЕННОГО SELL - %d", GetLastError());
        }
      else
        {
         Print("ОТЛОЖЕННЫЙ МОДИФИЦИРОВАЛИ SELL ",Comm+DopComm," ", result.order);
         modifySell = false;
         res_Sell = request.price;
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+