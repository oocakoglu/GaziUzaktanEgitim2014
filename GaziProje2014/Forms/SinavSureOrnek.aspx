<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SinavSureOrnek.aspx.cs" Inherits="GaziProje2014.Forms.SinavSureOrnek" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>

    <style>
        .clockSession
        {
             width: 409px;
             height: 174px;
             background: url(Resim/clockSession.jpg) no-repeat;
        }
           
        .contSession
        {
             width: 270px;
             float: right;
             text-align: center;
             margin: 20px 20px 0 0 ;
        }
           
        .sessionExpire
        {
             color: #3366ff;
             padding-top: 30px;
        }
           
        .showNotification
        {
             padding-top: 15px;
             color: #666;
        }
           
        .timeRemain
        {
             padding-top: 5px;
             color: #000;
        }
           
        .timeSeconds
        {
             font-size: 30px;
             padding-right: 5px;
        }
           
        .infoIcon, .notificationContent
        {
             display: inline-block;
            zoom: 1;
             *display: inline;
        }
           
        .infoIcon
        {
             width: 32px;
             height: 32px;
             margin: 0 10px ;
             vertical-align: top;
        }
           
        .notificationContent
        {
             width: 160px;
             vertical-align: bottom;
        }

    </style>

</head>
<body>
    <form id="form1" runat="server">

     <telerik:RadScriptManager runat="server" ID="RadScriptManager1" />
        <telerik:RadFormDecorator ID="QsfFromDecorator" runat="server" DecoratedControls="All" EnableRoundedCorners="false" />
         <script type="text/javascript">

             //----------------------- code related only to the demo UI --------------------------------------//


             //all the timers declared below are used for the demo UI only - to update UI texts.
             //The functionality related to the scenario itself is handled by RadNotification automatically out of the box
             var mainLblCounter = null;
             var timeLeftCounter = null;
             var seconds = 60;
             var secondsBeforeShow = 60;
             var mainLabel;

             //start the main label counter when the page loads
             function pageLoad() {
                 var xmlPanel = $find("<%= RadNotification1.ClientID %>")._xmlPanel;
                  xmlPanel.set_enableClientScriptEvaluation(true);
                  mainLabel = $get("mainLbl"); resetTimer("mainLblCounter", updateMainLabel, 1000);
              };

              //stop timers for UI
              function stopTimer(timer) {
                  clearInterval(this[timer]);
                  this[timer] = null;
              };

              //reset timers for UI
              function resetTimer(timer, func, interval) {
                  this.stopTimer(timer);
                  this[timer] = setInterval(Function.createDelegate(this, func), interval);
              };

              function OnClientShowing(sender, args) {
                  //deal with UI labels
                  mainLabel.innerHTML = 0;
                  resetTimer("timeLeftCounter", UpdateTimeLabel, 1000);
                  stopTimer("mainLblCounter");
              }

              function updateMainLabel(toReset) {
                  secondsBeforeShow = (toReset == true) ? 60 : secondsBeforeShow - 1;
                  mainLabel.innerHTML = secondsBeforeShow;
              }

              function OnClientHidden() {
                  updateMainLabel(true);
                  mainLabel.style.display = "";
                  resetTimer("mainLblCounter", updateMainLabel, 1000);
              }


              //-----------------------end of code related only to the demo UI --------------------------------------//


              //update the text in the label in RadNotification
              //this could also be done automatically by using UpdateInterval. However, this will cause callbacks [which is the second best solution than javascript] on every second that is being count
              function UpdateTimeLabel(toReset) {
                  var sessionExpired = (seconds == 0);
                  if (sessionExpired) {
                      stopTimer("timeLeftCounter");
                      //redirect to session expired page - simply take the url which RadNotification sent from the server to the client as value
                      window.location.href = $find("<%= RadNotification1.ClientID %>").get_value();
                    }
                    else {
                        var timeLbl = $get("timeLbl");
                        timeLbl.innerHTML = seconds--;
                    }
                }

                function ContinueSession() {
                    var notification = $find("<%= RadNotification1.ClientID %>");
                  //we need to contact the server to restart the Session - the fastest way is via callback
                  //calling update() automatically performs the callback, no need for any additional code or control
                  notification.update();
                  notification.hide();

                  //resets the showInterval for the scenario where the Notification is not disposed (e.g. an AJAX request is made)
                  //You need to inject a call to the ContinueSession() function from the code behind in such a request
                  var showIntervalStorage = notification.get_showInterval(); //store the original value
                  notification.set_showInterval(0); //change the timer to avoid untimely showing, 0 disables automatic showing
                  notification.set_showInterval(showIntervalStorage); //sets back the original interval which will start counting from its full value again

                  stopTimer("timeLeftCounter");
                  seconds = 60;
                  updateMainLabel(true);
              }

         </script>
         <div class="clockSession">
              <div class="contSession">
                   <div class="sesseionExpire">
                        Your Session will expire in
                        <%= Session.Timeout %>
                        minutes</div>
                   <div class="showNotification">
                        Notification will be shown in:</div>
                   <div class="timeRemain">
                        <span class="timeSeconds"><span id="mainLbl">60 </span></span>seconds</div>
              </div>
         </div>
         <telerik:RadNotification ID="RadNotification1" runat="server" Position="Center" Width="240"
              Height="100" OnCallbackUpdate="OnCallbackUpdate" OnClientShowing="OnClientShowing"
              OnClientHidden="OnClientHidden" LoadContentOn="PageLoad" AutoCloseDelay="60000"
              Title="Continue Your Session" TitleIcon="" Skin="Office2007" EnableRoundedCorners="true"
              ShowCloseButton="false" KeepOnMouseOver="false">
              <ContentTemplate>
                   <div class="infoIcon">
                        <img src="Resim/infoIcon.jpg" alt="info icon" /></div>
                   <div class="notificationContent">
                        Time remaining:&nbsp; <span id="timeLbl">60</span>
                        <telerik:RadButton Skin="Office2007" ID="continueSession" runat="server" Text="Continue Your Session"
                             Style="margin-top: 10px;" AutoPostBack="false" OnClientClicked="ContinueSession">
                        </telerik:RadButton>
                   </div>
              </ContentTemplate>
         </telerik:RadNotification>

    </form>
</body>
</html>
