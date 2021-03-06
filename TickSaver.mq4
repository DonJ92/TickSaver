//+------------------------------------------------------------------+
//|                                                    TickSaver.mq4 |
//|                                           Copyright 2021,Jupiter |
//|                                          https://www.jupiter.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,Jupiter"
#property link      "https://www.jupiter.com"
#property version   "1.00"
#property strict
#define MAX_BUFFER_COUNT 256

input string InpUrl = "http://localhost"; // InfluxDBURL
input string InpDBName = "fxdata01"; // DBName
input int    InpIntervalMillis = 5000; // IntervalMillis
input int    InpPendingCount = 10; // PendingCount

int      prevSecondTime      = 0;
uint     prevSecondTick      = 0;
long     g_last_sent_time = 0;
int      g_pending_count = 0;

double   g_bids[MAX_BUFFER_COUNT];
double   g_asks[MAX_BUFFER_COUNT];
long     g_times[MAX_BUFFER_COUNT];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   if(InpPendingCount > MAX_BUFFER_COUNT)
      Alert("Too many Pending count. Input below 256.");
   EventSetMillisecondTimer(1);
//   MakeInfulxRequest();
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   long current_millis = GetCurrentMillis();
   g_bids[g_pending_count] = Bid;
   g_asks[g_pending_count] = Ask;
   g_times[g_pending_count] = current_millis;
   g_pending_count++;
   if(g_pending_count > InpPendingCount || current_millis > g_last_sent_time + InpIntervalMillis) {
      SendPendingData();
      g_pending_count = 0;
      g_last_sent_time = current_millis;
   }
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
//---

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendPendingData() {
   if(g_pending_count > 0) {
      //myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000
      string payload = "";
      string broker = AccountCompany();
      StringReplace(broker, " ", "");
      string measurement = Symbol();
      string tagset = "broker=" +  broker;
      string fieldset ="";
      string current_millis = "";

      for(int i = 0; i < g_pending_count; i++) {
         current_millis = IntegerToString(g_times[i]);
         fieldset =  "bid=" + DoubleToString(g_bids[i], _Digits) + ",ask=" + DoubleToString(g_asks[i],_Digits); // fieldset 
         payload += measurement + "," + tagset + " " + fieldset + " " + current_millis+"\n";
      }
      bool result = SendRequest(InpUrl + "/api/v2/write?bucket=" + InpDBName + "&precision=ms", "POST", payload);

      g_pending_count = 0;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendRequest(string url, string method, string payload = "") {
   int http_result;
   string headers = "";
   string result_headers = "";
   char   data[];
   char   result_data[];


//--- Create the body of the POST request for authorization

   ArrayResize(data,StringToCharArray(payload,data,0,WHOLE_ARRAY,CP_UTF8)-1);

//   headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   headers = "Content-Type: application/json\r\n";
   headers += "User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36";


   http_result=WebRequest(method,url,headers,0,data,result_data,result_headers);

   if(http_result!=200) {
      Print("Http error #"+IntegerToString(http_result)+", LastError="+(string)GetLastError());
      return(false);
   }

   string result = CharArrayToString(result_data);

   Print(result);
//--- Return true for successful execution
   return(http_result==200);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long GetCurrentMillis() {
   return (long)((long)TimeCurrent()* 1000 + (GetTickCount() - prevSecondTick));
}

//This is an EVENT function that will be called every
// x millisecond(s) [as stated in teh EventSetMillisecondTimer()
// in the OnInit()
void OnTimer() {
   //If a new "second" occurs, record down the GetTickCount()
   if(TimeLocal() > prevSecondTime) {
      prevSecondTick  = (uint)GetTickCount();
      prevSecondTime  = (int)TimeLocal();
   }
}


//+------------------------------------------------------------------+
