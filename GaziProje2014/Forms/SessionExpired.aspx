<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SessionExpired.aspx.cs" Inherits="GaziProje2014.Forms.SessionExpired" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
       <telerik:RadScriptManager ID="RadScriptManager1" runat="server">
        </telerik:RadScriptManager>
        Your Session has expired!
         <br />
         <asp:Button ID="Button1" Text="Go Back" OnClientClick="history.back(); return false;" runat="server" />
    </form>
</body>
</html>
