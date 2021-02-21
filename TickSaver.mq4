//+------------------------------------------------------------------+
//|                                                    TickSaver.mq4 |
//|                                           Copyright 2021,Jupiter |
//|                                          https://www.jupiter.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,Jupiter"
#property link      "https://www.jupiter.com"
#property version   "1.00"
#property strict

input string InpUrl = "http://localhost:8086"; // InfluxDBURL
input string InpDBName = "fxdata01"; // DBName

int     prevSecondTime      = 0;
uint    prevSecondTick      = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   EventSetMillisecondTimer(1);
   MakeInfulxRequest();
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
//   MakeInfulxRequest();
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
void MakeInfulxRequest() {
//myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000
   string payload = "";
   string broker = AccountCompany();
   StringReplace(broker, " ", "");
   string measurement = Symbol();
   string tagset = "broker=" +  broker;
   string fieldset = "bid=" + DoubleToString(Bid, _Digits) + ",ask=" + DoubleToString(Ask,_Digits); // fieldset 
   string current_millis = IntegerToString((long)TimeCurrent()* 1000 + getCurrentMs());

   payload = measurement + "," + tagset + " " + fieldset + " " + current_millis;

   bool result = SendRequest(InpUrl + "/api/v2/write?bucket=" + InpDBName + "&precision=ms", "POST", payload);
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
int getCurrentMs() {
   return (int)(GetTickCount() - prevSecondTick);
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
