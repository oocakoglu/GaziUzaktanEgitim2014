<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="WebForm2.aspx.cs" Inherits="GaziProje2014.Forms.WebForm2" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server"></telerik:RadScriptManager>

        <telerik:RadTicker AutoStart="true" runat="server" ID="Radticker3" Loop="true">
                <Items>
                    <telerik:RadTickerItem>TÜRKEI: Aktien steigen nach einer Welle des Investorenvertrauens</telerik:RadTickerItem>
                    <telerik:RadTickerItem>RUMÄNIEN: Privatisierung bestimmt diese Woche den Aktienmarkt</telerik:RadTickerItem>
                    <telerik:RadTickerItem>BULGARIEN: Regierung plant eine neue Welle der Privatisierung</telerik:RadTickerItem>
                </Items>
        </telerik:RadTicker>

    </form>
</body>
</html>
