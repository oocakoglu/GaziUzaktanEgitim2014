<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="WebForm5.aspx.cs" Inherits="GaziProje2014.EskiFormlar.WebForm5" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
         <script type="text/javascript">
             function toggleTextBox() {
                 var radiobuttonList = document.getElementById('<%= rbList.ClientID %>');
                 var options = radiobuttonList.getElementsByTagName('input');                 
                 var pageView = $find("<%= RadMultiPage1.ClientID %>");

                 for (var i = 0; i < options.length; i++) {
                     if (options[i].checked)
                         pageView.set_selectedIndex(i);
                 }
            </script>

            <asp:RadioButtonList runat="server" onclick="toggleTextBox();" ID="rbList">
                        <asp:ListItem Value="0">İçerik Yaz</asp:ListItem>
                        <asp:ListItem Selected="True" Value="1">Dosyadan Seç</asp:ListItem>
                        <asp:ListItem Value="2">Bir Kaynaktan Embed Et</asp:ListItem>
            </asp:RadioButtonList>



        <telerik:RadMultiPage ID="RadMultiPage1" runat="server" SelectedIndex="0">
            <telerik:RadPageView ID="RadPageView1" runat="server">
                first page
                <br />
                <br />
                <br />
                <asp:Button ID="Button2" Text="Next Page" OnClientClick="goToNextPage(); return false;" runat="server" />
            </telerik:RadPageView>
            <telerik:RadPageView ID="RadPageView2" runat="server">
                second page
                <br />
                <br />
                <br />
                <asp:Button ID="Button3" Text="Prev Page" OnClientClick="goToPrevPage(); return false;" runat="server" />
                <asp:Button ID="Button4" Text="Next Page" OnClientClick="goToNextPage(); return false;" runat="server" />
            </telerik:RadPageView>
            <telerik:RadPageView ID="RadPageView3" runat="server">
                third page
                <br />
                <br />
                <br />
               
            </telerik:RadPageView>
        </telerik:RadMultiPage>


        <telerik:RadScriptManager ID="RadScriptManager1" runat="server"></telerik:RadScriptManager>
    </form>
</body>
</html>
