<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="WebForm4.aspx.cs" Inherits="GaziProje2014.EskiFormlar.WebForm4" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">

        <script>
            function onNavigate(isMoveNext) {
                var tabs = $find('<%= rtbstMain.ClientID %>');
                var totalNumOfTabs = tabs.get_tabs().get_count();
                if (totalNumOfTabs > 0) {
                    var newTabIndex;
                    var currentTabIndex = tabs.get_selectedIndex();

                    if (isMoveNext) {
                        if (currentTabIndex + 1 == totalNumOfTabs) {
                            newTabIndex = 0;
                        }
                        else {
                            newTabIndex = currentTabIndex + 1;
                        }
                    }
                    else {
                        if (currentTabIndex - 1 < 0) {
                            newTabIndex = totalNumOfTabs - 1;
                        }
                        else {
                            newTabIndex = currentTabIndex - 1
                        }
                    }
                    tabs.set_selectedIndex(newTabIndex);
                }
            }

        </script>

        
         <telerik:RadTabStrip ID="rtbstMain" runat="server" MultiPageID="RadMultiPage1" SelectedIndex="0">
               <Tabs>
                   <telerik:RadTab runat="server" Text="Root RadTab1" Selected="True">
                   </telerik:RadTab>
                   <telerik:RadTab runat="server" Text="Root RadTab2">
                   </telerik:RadTab>
                   <telerik:RadTab runat="server" Text="Root RadTab3">
                   </telerik:RadTab>
               </Tabs>
           </telerik:RadTabStrip>
           <telerik:RadMultiPage ID="RadMultiPage1" runat="server" SelectedIndex="0">
               <telerik:RadPageView ID="RadPageView1" runat="server">
                   RadPageView1</telerik:RadPageView>
               <telerik:RadPageView ID="RadPageView2" runat="server">
                   RadPageView2</telerik:RadPageView>
               <telerik:RadPageView ID="RadPageView3" runat="server">
                   RadPageView3</telerik:RadPageView>
           </telerik:RadMultiPage>
           <asp:Button ID="Button1" runat="server" Text="Prev" OnClientClick="onNavigate(false); return false;" />
           <asp:Button ID="Button2" runat="server" Text="Next" OnClientClick="onNavigate(true); return false;" />
         
          <telerik:RadScriptManager ID="RadScriptManager1" runat="server"></telerik:RadScriptManager>


    </form>
</body>
</html>
